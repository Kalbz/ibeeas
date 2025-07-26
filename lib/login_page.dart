import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'register_page.dart';
import 'package:rive/rive.dart' as rive;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Google Sign-In Method
  Future<void> _googleLogin() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Authenticate with Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);
      print("Google Sign-In successful");

      // Navigate to the main app
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
      );
    } catch (e) {
      print("Error with Google Sign-In: $e");
    }
  }

  rive.Artboard? _riveArtboard;
  rive.SimpleAnimation? _animationController;

  @override
  void initState() {
    super.initState();

    rive.RiveFile.initialize().then((_) {
      rootBundle.load('assets/bee_animation/bee_intro_anim.riv').then(
        (data) async {
          try {
            final file = rive.RiveFile.import(data);
            final artboard = file.mainArtboard;

            _animationController = rive.SimpleAnimation('Timeline 1');
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/login_background.png',
              fit: BoxFit.cover,
            ),
          ),
          _riveArtboard == null
              ? const SizedBox()
              : Positioned.fill(
                  child: rive.Rive(
                    artboard: _riveArtboard!,
                    fit: BoxFit.cover,
                  ),
                ),
          Positioned(
            top: screenHeight * 0.05,
            right: screenWidth * 0.12,
          child: Image.asset(
            'assets/upscaled_ibeeas_optimized.png',
            width: screenWidth * 0.4,
            height: screenWidth * 0.4,
            fit: BoxFit.contain,
          ),

          ),

          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: screenHeight * 0.40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                ],
              ),
            ),
          ),

          Positioned(
            left: screenWidth * 0.165,
            bottom: screenHeight * 0.29, 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularButton(
                  icon: Icons.person_add,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()),
                    );
                  },
                  tooltip: 'Register',
                ),
                SizedBox(width: screenWidth * 0.05), 
                CircularButton(
                  icon: Icons.login, 
                  onPressed: _googleLogin,
                  tooltip: 'Google Login',
                ),
                SizedBox(width: screenWidth * 0.05), 
                CircularButton(
                  icon: Icons.settings,
                  onPressed: () {
                    // Settings button functionality to be implemented
                  },
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CircularButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const CircularButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: CircleBorder(),
          padding: EdgeInsets.all(16),
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}
