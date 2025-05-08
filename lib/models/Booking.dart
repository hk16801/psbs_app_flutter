class Booking {
  final String bookingId;
  final String bookingCode;
  final String accountId;
  final String bookingStatusId;
  final String paymentTypeId;
  final String? voucherId;
  final String bookingTypeId;
  final double totalAmount;
  final String bookingDate;
  final String notes;
  final bool isPaid;

  Booking({
    required this.bookingId,
    required this.bookingCode,
    required this.accountId,
    required this.bookingStatusId,
    required this.paymentTypeId,
    this.voucherId,
    required this.bookingTypeId,
    required this.totalAmount,
    required this.bookingDate,
    required this.notes,
    required this.isPaid,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['bookingId'],
      bookingCode: json['bookingCode'],
      accountId: json['accountId'],
      bookingStatusId: json['bookingStatusId'],
      paymentTypeId: json['paymentTypeId'],
      voucherId: json['voucherId'],
      bookingTypeId: json['bookingTypeId'],
      totalAmount: json['totalAmount'].toDouble(),
      bookingDate: json['bookingDate'],
      notes: json['notes'] ?? '',
      isPaid: json['isPaid'],
    );
  }
}
