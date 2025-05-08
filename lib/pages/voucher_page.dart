import 'package:flutter/material.dart';

class VoucherPage extends StatelessWidget {
  const VoucherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Voucher',
          style: TextStyle(
              fontSize: 60, color: Colors.white, backgroundColor: Colors.green),
        ),
      ),
    );
  }
}
