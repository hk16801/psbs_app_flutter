import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CopyrightWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0F7FA), Color(0xFFF5F5F5)], // Từ cyan nhạt sang xám nhạt
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Text(
          '© ${DateFormat('yyyy').format(DateTime.now())} PET EASE. All rights reserved.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }
}
