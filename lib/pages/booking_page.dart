import 'package:flutter/material.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Booking',
          style: TextStyle(fontSize: 60, color: Colors.white, backgroundColor: Colors.redAccent),
        ),
      ),
    );
  }
}
