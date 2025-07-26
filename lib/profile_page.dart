import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' show basename;
import 'dart:io';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });

        // Upload to Firebase Storage
        String fileName = basename(pickedFile.path);
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

          setState(() {});

          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Profile picture updated successfully.")));
        }
      }
    } catch (e) {
      print("Error picking and uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload profile picture.")));
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(child: Text("No user is logged in."));
    }

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
          // User data with StreamBuilder
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error loading profile."));
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text("User data not found."));
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final username = userData['username'] ?? 'Guest';
              final honey = userData['honey'] ?? 0;
              final ideasPosted = userData['ideasPosted'] ?? 0;
              final commentsPosted = userData['commentsPosted'] ?? 0;
              final profileImageUrl = userData['profileImageUrl'];

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.1,
                  vertical: MediaQuery.of(context).size.height * 0.05,
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl)
                            : AssetImage('assets/profile_picture.jpg')
                                as ImageProvider,
                        child: profileImageUrl == null
                            ? Icon(Icons.add_a_photo,
                                color: Colors.white, size: 30)
                            : null,
                      ),
                    ),
                    SizedBox(height: 32),
                    // User Info Row (Name and Honey)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Username Column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Name",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              username,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 56),
                        // Honey Column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Honey",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              honey.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 50),
                    // Ideas and Comments Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ideas Column
                        Column(
                          children: [
                            Text(
                              "Ideas",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              ideasPosted.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 150),
                        // Comments Column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Comments",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              commentsPosted.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Spacer(),
                    // Logout Button
                    ElevatedButton(
                      onPressed: _logout,
                      child: Text("Logout"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
