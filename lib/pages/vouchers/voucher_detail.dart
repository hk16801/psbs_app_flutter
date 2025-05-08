import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:psbs_app_flutter/models/voucher.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class VoucherDetailScreen extends StatelessWidget {
  final Voucher voucher;

  const VoucherDetailScreen({Key? key, required this.voucher})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher Details'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.blue.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(
                  Icons.card_giftcard,
                  size: 80,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 16),

              // Voucher Code Section
              _buildSectionTitle('Voucher Code'),
              const SizedBox(height: 8),
              _buildContainer(
                child: TextFormField(
                  readOnly: true,
                  initialValue: voucher.voucherCode,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      color: Colors.blue.shade800),
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: Icon(Icons.copy, color: Colors.blue.shade700),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: voucher.voucherCode));
                        Fluttertoast.showToast(
                          msg: "Copied to clipboard!",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.blue.shade700,
                          textColor: Colors.white,
                          fontSize: 14.0,
                        );
                      },
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Voucher Details Section
              _buildSectionTitle('Voucher Details'),
              _buildContainer(
                child: Column(
                  children: [
                    _buildDetailRow('Name:', voucher.voucherName),
                    _buildDivider(),
                    _buildDetailRow('Discount:',
                        '${voucher.voucherDiscount.toStringAsFixed(0)}%'),
                    if (voucher.voucherMaximum != null) _buildDivider(),
                    if (voucher.voucherMaximum != null)
                      _buildDetailRow('Maximum Discount:',
                          currencyFormatter.format(voucher.voucherMaximum!)),
                    _buildDivider(),
                    _buildDetailRow('Minimum Spend:',
                        currencyFormatter.format(voucher.voucherMinimumSpend)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Validity Period Section
              _buildSectionTitle('Validity Period'),
              _buildContainer(
                child: Column(
                  children: [
                    _buildDetailRow('Start Date:',
                        formatter.format(voucher.voucherStartDate)),
                    _buildDivider(),
                    _buildDetailRow(
                        'End Date:', formatter.format(voucher.voucherEndDate)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description Section
              _buildSectionTitle('Description'),
              _buildContainer(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    voucher.voucherDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: Colors.blue.shade800,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.blue.shade200, 
      thickness: 1, 
      height: 10
    );
  }
}