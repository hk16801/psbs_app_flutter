import 'package:flutter/material.dart';
import '../../models/voucher.dart';

class VoucherCard extends StatelessWidget {
  final Voucher voucher;
  final String basePath;

  VoucherCard({required this.voucher, required this.basePath});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/customer/vouchers/detail',
          arguments: voucher,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Main card content
              IntrinsicHeight(
                child: Row(
                  children: [
                    // Left blue section
                    Container(
                      width: MediaQuery.of(context).size.width * 0.3,
                      color: Colors.blue[600],
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${voucher.voucherDiscount.toStringAsFixed(0)}%",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            "DISCOUNT",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Right white section
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              voucher.voucherName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Tap to view this voucher",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[500],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.blue[600],
                                  size: 24,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Dotted line separator
              Positioned(
                left: MediaQuery.of(context).size.width * 0.3,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    height: double.infinity,
                    width: 1,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.blue[300]!,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Scissors icons
              Positioned(
                left: MediaQuery.of(context).size.width * 0.3 - 12,
                top: -4,
                child: Transform.rotate(
                  angle: 1.5708, // 90 degrees in radians
                  child: Icon(
                    Icons.cut,
                    color: Colors.blue[400],
                    size: 24,
                  ),
                ),
              ),
              Positioned(
                left: MediaQuery.of(context).size.width * 0.3 - 12,
                bottom: -4,
                child: Transform.rotate(
                  angle: 1.5708, // 90 degrees in radians
                  child: Icon(
                    Icons.cut,
                    color: Colors.blue[400],
                    size: 24,
                  ),
                ),
              ),
              
              // Decorative circles
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.blue[500]!.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue[500]!.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}