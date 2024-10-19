import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? username;
  String? email;
  bool isLoading = true;

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
          // Use a default value if the username field is missing
          username = userSnapshot.data().toString().contains('username') ? userSnapshot['username'] : 'User';
          email = user.email;
          isLoading = false;
        });
      } else {
        // Handle case where document doesn't exist (unlikely for old users)
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


  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, ${username ?? 'Guest'}!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Email: ${email ?? 'Not available'}",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _logout,
                    child: Text("Logout"),
                  ),
                ],
              ),
            ),
    );
  }
}
