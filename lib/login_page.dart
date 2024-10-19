import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'register_page.dart';
import 'package:rive/rive.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Artboard? _riveArtboard;
  SimpleAnimation? _animationController;

  @override
  void initState() {
    super.initState();

    // Initialize Rive
    RiveFile.initialize().then((_) {
      // Load the Rive file
      rootBundle.load('assets/bee_animation/bee_intro_anim.riv').then(
        (data) async {
          try {
            final file = RiveFile.import(data);
            final artboard = file.mainArtboard;

            // Add a SimpleAnimation controller to play animation automatically
            _animationController = SimpleAnimation('Timeline 1');
            artboard.addController(_animationController!);

            setState(() {
              _riveArtboard = artboard;
              print("Rive artboard is set and animation should be playing.");
            });
          } catch (e) {
            print("Error loading Rive file: $e");
          }
        },
      ).catchError((error) {
        print("Error loading Rive asset: $error");
      });
    }).catchError((error) {
      print("Error initializing Rive: $error");
    });
  }

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
      );
    } catch (e) {
      print("Error logging in: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Stack(
        children: [
          // Rive animation in the background
          _riveArtboard == null
              ? const SizedBox()
              : Positioned.fill(
                  child: Rive(
                    artboard: _riveArtboard!,
                    fit: BoxFit.cover,
                  ),
                ),
          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    child: const Text("Login"),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Don't have an account? Register below!",
                    style: TextStyle(fontSize: 16),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterPage()),
                      );
                    },
                    child: const Text("Register"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
