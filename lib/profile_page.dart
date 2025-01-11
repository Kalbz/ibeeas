import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' show basename; // This only imports basename, avoiding conflicts
import 'dart:io';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? username;
  String? email;
  int honey = 0;
  int ideasPosted = 0;
  int commentsPosted = 0;
  File? _profileImage;
  bool isLoading = true;
  final ImagePicker _imagePicker = ImagePicker();
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userSnapshot.exists) {
          setState(() {
            username = userSnapshot.data().toString().contains('username') ? userSnapshot['username'] : 'User';
            email = user.email;
            honey = userSnapshot.data().toString().contains('honey') ? userSnapshot['honey'] : 0;
            ideasPosted = userSnapshot.data().toString().contains('ideasPosted') ? userSnapshot['ideasPosted'] : 0;
            commentsPosted = userSnapshot.data().toString().contains('commentsPosted') ? userSnapshot['commentsPosted'] : 0;
            profileImageUrl = userSnapshot.data().toString().contains('profileImageUrl') ? userSnapshot['profileImageUrl'] : null;
            isLoading = false;
          });
        } else {
          setState(() {
            username = 'User';
            email = user.email;
            isLoading = false;
          });
        }
      } catch (e) {
        print("Error loading user data: $e");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });

        // Upload to Firebase Storage
        String fileName = basename(pickedFile.path); // Get the file name
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          Reference firebaseStorageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images/${user.uid}/$fileName');

          UploadTask uploadTask = firebaseStorageRef.putFile(_profileImage!);
          TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

          // Get the download URL
          String downloadUrl = await taskSnapshot.ref.getDownloadURL();

          // Save the URL to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'profileImageUrl': downloadUrl});

          setState(() {
            profileImageUrl = downloadUrl;
          });

          // Display a success message
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile picture updated successfully.")));
        }
      }
    } catch (e) {
      print("Error picking and uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to upload profile picture.")));
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

@override
Widget build(BuildContext context) {
  final double screenHeight = MediaQuery.of(context).size.height;
  final double screenWidth = MediaQuery.of(context).size.width;

  return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    body: Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset(
            'assets/profile_background.png',
            fit: BoxFit.cover,
          ),
        ),
        // Main content
        isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: screenHeight * 0.05),
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile picture upload row
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : (profileImageUrl != null
                                      ? NetworkImage(profileImageUrl!)
                                      : AssetImage('assets/profile_picture.jpg')) as ImageProvider,
                              child: _profileImage == null && profileImageUrl == null
                                  ? Icon(Icons.add_a_photo, color: Colors.white, size: 30)
                                  : null,
                            ),
                          ),
SizedBox(height: 32), // Increased from 16 to 32 for more spacing

// Username and Honey row
Row(
  mainAxisAlignment: MainAxisAlignment.center, // Align items centrally
  children: [
    // Username section
    Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Name",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 8),
        Text(
          username ?? 'Guest',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ],
    ),
    // Reduce the spacing between sections
    SizedBox(width: 56), // Adjust this value as needed
    // Honey section
    Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Honey",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 8),
        Text(
          honey.toString(),
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ],
    ),
  ],
),

                          SizedBox(height: 50),
                          // Ideas posted and Comments posted row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    "Ideas",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    ideasPosted.toString(),
                                    style: TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                                ],
                              ),
                              SizedBox(width: 150),
                              Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,

                                children: [
                                  Text(
                                    "Comments",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    commentsPosted.toString(),
                                    style: TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Spacer(), // Push the Logout button down
                    ElevatedButton(
                      onPressed: _logout,
                      child: Text("Logout"),
                    ),
                  ],
                ),
              ),
      ],
    ),
  );
}
}
