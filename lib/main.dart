import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'contact_page.dart';
import 'pages/idea_grid_page.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;


const firebaseConfig = FirebaseOptions(
  apiKey: "AIzaSyDA07LMjsNM3nlb686yBhv0pJeEVICB0Uc",
  authDomain: "ibeeas.firebaseapp.com",
  projectId: "ibeeas",
  storageBucket: "ibeeas.appspot.com",
  messagingSenderId: "60365986213",
  appId: "1:60365986213:web:70f411c3586babe36df04c",
  measurementId: "G-79V3KB96JV",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(options: firebaseConfig); // Web initialization
  } else if (Platform.isIOS || Platform.isAndroid) {
    await Firebase.initializeApp(); // Native (iOS/Android) initialization
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IBeeas',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xffa500), 
          titleTextStyle: TextStyle(
            color: Colors.white, 
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
      ),
      home: AuthenticationWrapper(),
      routes: {
        '/login': (context) => LoginPage(),
        '/profile': (context) => ProfilePage(),

      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return IdeaGridPage();
        } else {
          return LoginPage();
        }
      },
    );
  }
}
