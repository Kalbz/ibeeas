import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as Math;
import '../models/idea.dart';
import '../profile_page.dart';
import '../widgets/hexagon.dart';
import '../widgets/honey_line_border.dart';

class IdeaGridPage extends StatefulWidget {
  final bool useOtherDatabase;

  IdeaGridPage({this.useOtherDatabase = false});

  @override
  _IdeaGridPageState createState() => _IdeaGridPageState();
}

class _IdeaGridPageState extends State<IdeaGridPage> {
  int _selectedIndex = 0; 


  List<Idea> ideas = [];
  List<Idea> filteredIdeas = [];
  bool isLoading = true;
  final List<String> tags = ["Math", "Programming", "Gardening", "Religion", "Creativity"];
  String searchQuery = "";
  final int totalHexagons = 5000;
  TransformationController _transformationController = TransformationController();
  Set<String> loadedChunks = Set();
  final int chunkSize = 6;
  

  @override
  void initState() {
    super.initState();
    _fetchIdeas();
    _transformationController.addListener(_updateVisibility);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_updateVisibility);
    _transformationController.dispose();
    super.dispose();
  }
Future<void> _fetchIdeas() async {
  setState(() {
    isLoading = true;
  });
  try {
    String collectionName = widget.useOtherDatabase ? 'other_ideas' : 'ideas';
    List<Idea> fetchedIdeas = [];

    if (widget.useOtherDatabase) {
      // Fetch shared (public) ideas from "other_ideas"
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(collectionName).get();
      fetchedIdeas = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return Idea(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          filled: data['filled'] ?? false,
          index: data['index'] ?? -1,
          tag: data['tag'] ?? '',
          upvotes: data['upvotes'] ?? 0,
          comments: List<String>.from(data['comments'] ?? []),
        );
      }).toList();
    } else {
      // Fetch private user-specific ideas from "ideas/{userId}/user_ideas"
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('ideas')
            .doc(user.uid)
            .collection('user_ideas')
            .get();
        fetchedIdeas = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return Idea(
            id: doc.id,
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            filled: data['filled'] ?? false,
            index: data['index'] ?? -1,
            tag: data['tag'] ?? '',
            upvotes: data['upvotes'] ?? 0,
            comments: List<String>.from(data['comments'] ?? []),
          );
        }).toList();
      }
    }

    if (mounted) {
      setState(() {
        ideas = List.generate(totalHexagons, (index) {
          int row = index ~/ 20;
          int col = index % 20;

          double hexagonWidth = 100;
          double hexagonHeight = hexagonWidth * Math.sqrt(3) / 2;
          double offsetX = col * (hexagonWidth * 0.75) + hexagonWidth / 2;
          double offsetY = row * (hexagonHeight * Math.sqrt(3) / 1.75) + hexagonHeight / 2;
          if (col % 2 == 1) {
            offsetY += hexagonHeight / 2;
          }

          return Idea(
            id: index.toString(),
            title: '',
            description: '',
            filled: false,
            index: index,
            tag: '',
            x: offsetX,
            y: offsetY,
            visible: false,
          );
        });
        for (var idea in fetchedIdeas) {
          if (idea.index >= 0 && idea.index < totalHexagons) {
            ideas[idea.index] = ideas[idea.index].copyWith(
              filled: idea.filled,
              title: idea.title,
              description: idea.description,
              tag: idea.tag,
              upvotes: idea.upvotes,
              comments: idea.comments,
            );
          }
        }
        filteredIdeas = ideas;
        isLoading = false;
        _updateVisibility();
      });
    }
  } catch (e) {
    print("Error fetching ideas: $e");
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}



  void _updateVisibility() {
    final viewport = _transformationController.value.getTranslation();
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final double viewportWidth = MediaQuery.of(context).size.width / scale;
    final double viewportHeight = MediaQuery.of(context).size.height / scale;
    final double padding = 500.0; // Add padding to load hexagons beyond the viewport edges

    int startChunkX = ((viewport.x - padding) / (chunkSize * 100 * 0.75)).floor();
    int startChunkY = ((viewport.y - padding) / (chunkSize * 100 * Math.sqrt(3) / 2)).floor();
    int endChunkX = ((viewport.x + viewportWidth + padding) / (chunkSize * 100 * 0.75)).ceil();
    int endChunkY = ((viewport.y + viewportHeight + padding) / (chunkSize * 100 * Math.sqrt(3) / 2)).ceil();

    Set<String> visibleChunks = Set();
    for (int chunkY = startChunkY; chunkY <= endChunkY; chunkY++) {
      for (int chunkX = startChunkX; chunkX <= endChunkX; chunkX++) {
        visibleChunks.add("$chunkX,$chunkY");
      }
    }

    setState(() {
      // Load visible chunks
      for (String chunk in visibleChunks) {
        if (!loadedChunks.contains(chunk)) {
          _loadChunk(chunk);
          loadedChunks.add(chunk);
        }
      }

      // Unload chunks that are no longer visible
      loadedChunks = loadedChunks.where((chunk) => visibleChunks.contains(chunk)).toSet();
    });
  }

  void _loadChunk(String chunk) {
    int chunkX = int.parse(chunk.split(",")[0]);
    int chunkY = int.parse(chunk.split(",")[1]);

    for (int i = 0; i < chunkSize; i++) {
      for (int j = 0; j < chunkSize; j++) {
        int index = (chunkY * chunkSize * 20) + (chunkX * chunkSize) + (i * 20) + j;
        if (index >= 0 && index < ideas.length) {
          ideas[index] = ideas[index].copyWith(visible: true);
        }
      }
    }
  }

void _addIdea(int index, String title, String description, String tag) async {
  setState(() {
    ideas[index] = ideas[index].copyWith(filled: true, title: title, description: description, tag: tag);
  });

  try {
    String collectionName = widget.useOtherDatabase ? 'other_ideas' : 'ideas';
    User? user = FirebaseAuth.instance.currentUser;

    if (collectionName == 'ideas' && user != null) {
      // Add the idea to the user's private collection
      await FirebaseFirestore.instance
          .collection('ideas')
          .doc(user.uid)
          .collection('user_ideas')
          .doc(ideas[index].id)
          .set({
        'x': ideas[index].x,
        'y': ideas[index].y,
        'title': title,
        'description': description,
        'filled': true,
        'index': index,
        'tag': tag,
        'upvotes': 0, // Set initial upvotes to 0
        'comments': [], // Set initial comments as an empty list
      });
    } else if (collectionName == 'other_ideas' && user != null) {
      // Add to public "other_ideas" collection with creatorId
      await FirebaseFirestore.instance.collection(collectionName).doc(ideas[index].id).set({
        'creatorId': user.uid, // Include creatorId to manage write permissions
        'x': ideas[index].x,
        'y': ideas[index].y,
        'title': title,
        'description': description,
        'filled': true,
        'index': index,
        'tag': tag,
        'upvotes': 0, // Set initial upvotes to 0
        'comments': [], // Set initial comments as an empty list
      });
    }
  } catch (e) {
    print("Error adding idea: $e");
  }
}


void _showAddIdeaDialog(int index) {
  String title = "";
  String description = "";
  String selectedTag = tags[0];

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Color(0xFFFFF1C1), // Light honey color for the dialog
        child: HoneyLineBorderModal(
          width: 300, // Adjust width as needed
          height: 400, // Adjust height as needed
          borderThickness: 8,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title of the dialog
                Text(
                  'Add Idea',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB5651D), // Honey dark brown color for contrast
                  ),
                ),
                SizedBox(height: 16.0),
                // TextField for Title
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(
                      color: Color(0xFFB5651D), // Dark brown honey color for labels
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFD700), width: 2.0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFA500), width: 2.5),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onChanged: (value) => title = value,
                ),
                SizedBox(height: 10.0),
                // TextField for Description
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(
                      color: Color(0xFFB5651D),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFD700), width: 2.0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFA500), width: 2.5),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onChanged: (value) => description = value,
                ),
                SizedBox(height: 10.0),
                // Dropdown for selecting tag
                DropdownButton<String>(
                  value: selectedTag,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedTag = value;
                      });
                    }
                  },
                  items: tags.map((tag) {
                    return DropdownMenuItem<String>(
                      value: tag,
                      child: Text(tag, style: TextStyle(color: Color(0xFFB5651D))),
                    );
                  }).toList(),
                  style: TextStyle(color: Color(0xFFB5651D)),
                  dropdownColor: Color(0xFFFFF1C1),
                ),
                SizedBox(height: 20.0),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFFB5651D)),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFA500), // Warm honey color for the button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed: () {
                        _addIdea(index, title, description, selectedTag);
                        Navigator.of(context).pop();
                      },
                      child: Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _showIdeaDetailsDialog(int index) {
  TextEditingController commentController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Color(0xFFFFF1C1), // Light honey color for the dialog background
        child: HoneyLineBorderModal(
          width: 300, // Adjust width as needed
          height: 500, // Increased height to provide more space
          borderThickness: 8,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title of the dialog
                Text(
                  ideas[index].title,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB5651D), // Honey dark brown for contrast
                  ),
                ),
                SizedBox(height: 16.0),
                // Idea details
                Text(
                  "${ideas[index].description}\nTag: ${ideas[index].tag}\nUpvotes: ${ideas[index].upvotes}",
                  style: TextStyle(
                    color: Color(0xFFB5651D), // Dark brown text
                  ),
                ),
                SizedBox(height: 16.0),
                // Comments section
                Text(
                  "Comments:",
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB5651D),
                  ),
                ),
                SizedBox(height: 8.0),
                // List of comments
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: ideas[index].comments.length,
                    itemBuilder: (context, commentIndex) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          "- ${ideas[index].comments[commentIndex]}",
                          style: TextStyle(color: Color(0xFFB5651D)),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 10.0),
                // Add comment field
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    labelText: 'Add a comment',
                    labelStyle: TextStyle(
                      color: Color(0xFFB5651D), // Dark brown label
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFD700), width: 2.0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFA500), width: 2.5),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFA500), // Warm honey color for the button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed: () {
                        _addComment(index, commentController.text);
                        Navigator.of(context).pop();
                      },
                      child: Text('Add Comment'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFA500), // Warm honey color for the button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed: () {
                        _upvoteIdea(index);
                        Navigator.of(context).pop();
                      },
                      child: Text('Upvote'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}



void _addComment(int index, String comment) async {
  if (comment.isEmpty) return;

  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    String username = userSnapshot['username'];

    setState(() {
      ideas[index] = ideas[index].copyWith(comments: [...ideas[index].comments, '$username: $comment']);
    });

    try {
      String collectionName = widget.useOtherDatabase ? 'other_ideas' : 'ideas';
      await FirebaseFirestore.instance.collection(collectionName).doc(ideas[index].id).update({
        'comments': FieldValue.arrayUnion(['$username: $comment']),
      });
    } catch (e) {
      print("Error adding comment: $e");
    }
  }
}


void _upvoteIdea(int index) async {
  setState(() {
    ideas[index] = ideas[index].copyWith(upvotes: ideas[index].upvotes + 1);
  });

  try {
    String collectionName = widget.useOtherDatabase ? 'other_ideas' : 'ideas';
    await FirebaseFirestore.instance.collection(collectionName).doc(ideas[index].id).update({
      'upvotes': FieldValue.increment(1),
    });
  } catch (e) {
    print("Error upvoting idea: $e");
  }
}


  void _filterIdeas(String query) {
    setState(() {
      searchQuery = query;
      filteredIdeas = ideas.where((idea) {
        return idea.title.toLowerCase().contains(query.toLowerCase()) ||
               idea.tag.toLowerCase().contains(query.toLowerCase());
      }).toList();

      if (filteredIdeas.isNotEmpty) {
        _zoomToHexagon(filteredIdeas.first);
      }
    });
  }

  void _zoomToHexagon(Idea idea) {
    print('Zooming to: x = ${idea.x}, y = ${idea.y}');
    double offsetX = idea.x;
    double offsetY = idea.y - 50;
    _transformationController.value = Matrix4.identity()
      ..translate(-offsetX, -offsetY)
      ..scale(1.5); // Adjust the scale as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFCC00), // Background color
      appBar: AppBar(
        title: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/upscaled_ibeeas_optimized.png',
                width: 64,
                height: 64,
              ),
              SizedBox(width: 10),
              Text('IBeeas'),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by title or tag...',
                prefixIcon: Icon(Icons.search),
                fillColor: Color(0xFFFA9A00),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onChanged: (query) {
                _filterIdeas(query);
              },
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTapDown: (TapDownDetails details) {
          print('Tapped at: x = ${details.localPosition.dx}, y = ${details.localPosition.dy}');
        },
        child: Stack(
          children: [
            isLoading
                ? Center(child: CircularProgressIndicator())
                : InteractiveViewer(
                    boundaryMargin: EdgeInsets.all(500),
                    clipBehavior: Clip.none,
                    constrained: false,
                    scaleEnabled: true,
                    minScale: 0.5,
                    maxScale: 5.0,
                    transformationController: _transformationController,
                    child: SizedBox(
                      width: 2500,
                      height: 2500,
                      child: RepaintBoundary(
                        child: Stack(
                          children: List.generate(ideas.length, (index) {
                            if (!ideas[index].visible) return Container();
                            return Positioned(
                              left: ideas[index].x,
                              top: ideas[index].y,
                              child: GestureDetector(
                                onTap: () {
                                  if (!ideas[index].filled) {
                                    _showAddIdeaDialog(index);
                                  } else {
                                    _showIdeaDetailsDialog(index);
                                  }
                                },
                                child: Hexagon(
                                  idea: ideas[index],
                                  width: 100,
                                  height: 100 * Math.sqrt(3) / 2,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFFFA9A00),
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex, // Set the selected index
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'My Ideas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Other Ideas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // Update the selected index
          });

          if (index == 0 && !_isCurrentPage("MyIdeas")) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => IdeaGridPage(),
              ),
            );
          } else if (index == 1 && !_isCurrentPage("OtherIdeas")) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => IdeaGridPage(useOtherDatabase: true),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(),
              ),
            );
          }
        },
      ),
    );
  }

  // Utility method to avoid redundant navigation
  bool _isCurrentPage(String pageName) {
    return (widget.useOtherDatabase && pageName == "OtherIdeas") ||
        (!widget.useOtherDatabase && pageName == "MyIdeas");
  }
}
