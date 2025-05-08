import 'package:intl/intl.dart'; // Import for date formatting

class Voucher {
  final String voucherId;
  final String voucherName;
  final String voucherDescription;
  final int voucherQuantity;
  final double voucherDiscount;
  final double? voucherMaximum; // Make voucherMaximum nullable
  final double voucherMinimumSpend;
  final String voucherCode;
  final DateTime voucherStartDate;
  final DateTime voucherEndDate;
  final bool isGift;
  final bool isDeleted;

  Voucher({
    required this.voucherId,
    required this.voucherName,
    required this.voucherDescription,
    required this.voucherQuantity,
    required this.voucherDiscount,
    this.voucherMaximum,
    required this.voucherMinimumSpend,
    required this.voucherCode,
    required this.voucherStartDate,
    required this.voucherEndDate,
    required this.isGift,
    required this.isDeleted,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    // Date parsing with intl package
    final DateFormat formatter =
        DateFormat('yyyy-MM-ddTHH:mm:ss'); // Match your date format
    final DateTime startDate = formatter.parse(json['voucherStartDate']);
    final DateTime endDate = formatter.parse(json['voucherEndDate']);

    return Voucher(
      voucherId: json['voucherId'] ?? '',
      voucherName: json['voucherName'] ?? '',
      voucherDescription: json['voucherDescription'] ?? '',
      voucherQuantity: json['voucherQuantity'] ?? 0,
      voucherDiscount: (json['voucherDiscount'] as num?)?.toDouble() ?? 0.0,
      voucherMaximum:
          (json['voucherMaximum'] as num?)?.toDouble(), // Handle nullable
      voucherMinimumSpend:
          (json['voucherMinimumSpend'] as num?)?.toDouble() ?? 0.0,
      voucherCode: json['voucherCode'] ?? '',
      voucherStartDate: startDate,
      voucherEndDate: endDate,
      isGift: json['isGift'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}
