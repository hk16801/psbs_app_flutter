import 'package:flutter/material.dart';

class ProfilePages extends StatelessWidget {
  const ProfilePages({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Profile',
          style: TextStyle(
              fontSize: 60, color: Colors.white, backgroundColor: Colors.amber),
        ),
      ),
    );
  }
}
