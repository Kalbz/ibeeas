import 'package:flutter/material.dart';

class ContactPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // A simple contact page with placeholder content
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Us'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'If you have any questions or feedback, feel free to reach out to us at:\n\n'
            'Email: support@example.com\n'
            'Phone: +1 (555) 123-4567\n\n'
            'We are available Monday through Friday from 9 AM to 5 PM.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
