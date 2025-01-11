import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set the status bar to blend with the background
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Ensure status bar blends with the background
      statusBarIconBrightness: Brightness.dark, // Change based on your design (e.g., dark or light)
    ));
  }

  Future<void> _register() async {
    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        // Save the username to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': _usernameController.text.trim(),
          'email': user.email,
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
      );
    } catch (e) {
      print("Error registering: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent, // Ensure the Scaffold background is transparent
appBar: AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  leading: Container(), // An empty container to prevent the default back arrow on the left
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 320.0, bottom: 12.0), // Adjust padding as needed
      child: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black),
        iconSize: 36.0,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    ),
  ],
),


      extendBodyBehindAppBar: true, // Allows the body to extend behind the AppBar
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/register_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Main content
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisAlignment: MainAxisAlignment.end, // Align the content towards the bottom
                  children: [
                    SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: screenHeight * 0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _usernameController,
                              decoration: const InputDecoration(labelText: "Username"),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(labelText: "Email"),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordController,
                              decoration: const InputDecoration(labelText: "Password"),
                              obscureText: true,
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _register,
                              child: const Text("Register"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
