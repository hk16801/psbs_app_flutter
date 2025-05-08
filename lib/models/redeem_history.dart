import 'dart:convert';

class RedeemHistory {
  final String? redeemHistoryId;
  final String giftName;
  final String? giftImage;
  final int giftPoint;
  final String? giftCode;
  final DateTime redeemDate;
  final String redeemStatusId;
  final String redeemStatusName;

  RedeemHistory({
    this.redeemHistoryId,
    required this.giftName,
    this.giftImage,
    required this.giftPoint,
    this.giftCode,
    required this.redeemDate,
    required this.redeemStatusId,
    required this.redeemStatusName,
  });

  factory RedeemHistory.fromJson(Map<String, dynamic> json) {
    return RedeemHistory(
      redeemHistoryId: json['redeemHistoryId'],
      giftName: json['giftName'],
      giftImage: json['giftImage'],
      giftPoint: json['giftPoint'],
      giftCode: json['giftCode'],
      redeemDate: DateTime.parse(json['redeemDate']),
      redeemStatusId: json['redeemStatusId'],
      redeemStatusName: json['redeemStatusName'],
    );
  }

  static List<RedeemHistory> fromJsonList(String jsonString) {
    final data = jsonDecode(jsonString);
    if (data['flag'] == true && data['data'] != null) {
      return List<RedeemHistory>.from(
        data['data'].map((item) => RedeemHistory.fromJson(item)),
      );
    }
    return [];
  }
}
