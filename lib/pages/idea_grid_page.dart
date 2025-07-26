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

Stream<List<Idea>> _streamIdeas() {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print("No user is logged in. Returning empty stream.");
    return Stream.value([]);
  }

  final String collectionPath = 'ideas/${user.uid}/user_ideas';
  print("Listening to Firestore collection: $collectionPath");

  return FirebaseFirestore.instance
      .collection(collectionPath)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Idea(
              id: doc.id,
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              filled: data['filled'] ?? false,
              index: data['index'] ?? -1,
              tag: data['tag'] ?? '',
              upvotes: data['upvotes'] ?? 0,
              comments: List<String>.from(data['comments'] ?? []),
              x: data['x'] ?? 0.0,
              y: data['y'] ?? 0.0,
              visible: true,
            );
          }).toList());
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
  final User? user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    print("Error: No user is logged in.");
    return;
  }

  final String collectionName = widget.useOtherDatabase ? 'other_ideas' : 'ideas';
  final String documentPath = widget.useOtherDatabase
      ? "$collectionName/${ideas[index].id}"
      : "$collectionName/${user.uid}/user_ideas/${ideas[index].id}";

  setState(() {
    ideas[index] = ideas[index].copyWith(filled: true, title: title, description: description, tag: tag);
  });

  try {
    print("Adding idea to Firestore at path: $documentPath");
    await FirebaseFirestore.instance.doc(documentPath).set({
      'x': ideas[index].x,
      'y': ideas[index].y,
      'title': title,
      'description': description,
      'filled': true,
      'index': index,
      'tag': tag,
      'upvotes': 0,
      'comments': [],
      if (widget.useOtherDatabase) 'creatorId': user.uid, // Add creatorId for public ideas
    });

    // Increment the "ideasPosted" field in the user's profile
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'ideasPosted': FieldValue.increment(1),
    });

    print("Idea added successfully: ID = ${ideas[index].id}");
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
        backgroundColor: Color(0xFFFFF1C1),
        child: HoneyLineBorderModal(
          width: 300,
          height: 400,
          borderThickness: 8,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Idea',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB5651D),
                  ),
                ),
                SizedBox(height: 16.0),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Title',
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
                  onChanged: (value) => title = value,
                ),
                SizedBox(height: 10.0),
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
                        backgroundColor: Color(0xFFFFA500),
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
        backgroundColor: Color(0xFFFFF1C1),
        child: HoneyLineBorderModal(
          width: 300,
          height: 500,
          borderThickness: 8,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ideas[index].title,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB5651D),
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  "${ideas[index].description}\nTag: ${ideas[index].tag}\nUpvotes: ${ideas[index].upvotes}",
                  style: TextStyle(
                    color: Color(0xFFB5651D),
                  ),
                ),
                SizedBox(height: 16.0),
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
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    labelText: 'Add a comment',
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
                ),
                SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFA500),
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
                        backgroundColor: Color(0xFFFFA500),
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
  if (comment.isEmpty) {
    print("Error: Comment is empty.");
    return;
  }

  final User? user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    print("Error: No user is logged in.");
    return;
  }

  final String ideaId = ideas[index].id;
  final String collectionName = widget.useOtherDatabase ? 'other_ideas' : 'ideas';
  final String documentPath = widget.useOtherDatabase
      ? "$collectionName/$ideaId"
      : "$collectionName/${user.uid}/user_ideas/$ideaId";

  try {
    print("Adding comment to document: $documentPath");

    DocumentReference docRef = FirebaseFirestore.instance.doc(documentPath);
    DocumentSnapshot docSnap = await docRef.get();

    if (!docSnap.exists) {
      print("Error: Document not found at path: $documentPath");
      return;
    }

    await docRef.update({
      'comments': FieldValue.arrayUnion([comment]),
    });

    // Increment the "commentsPosted" field in the user's profile
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'commentsPosted': FieldValue.increment(1),
    });

    print("Comment added successfully to idea ID: $ideaId");
  } catch (e) {
    print("Error adding comment: $e");
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
      ..scale(1.5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFCC00),
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
        currentIndex: _selectedIndex,
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
            _selectedIndex = index;
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

  bool _isCurrentPage(String pageName) {
    return (widget.useOtherDatabase && pageName == "OtherIdeas") ||
        (!widget.useOtherDatabase && pageName == "MyIdeas");
  }
}
