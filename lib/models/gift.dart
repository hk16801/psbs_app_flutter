import 'dart:convert';

class Gift {
  final String giftId;
  final String giftName;
  final String giftDescription;
  final String giftImage;
  final int giftPoint;
  final String? giftCode;

  Gift({
    required this.giftId,
    required this.giftName,
    required this.giftDescription,
    required this.giftImage,
    required this.giftPoint,
    this.giftCode,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      giftId: json['giftId'],
      giftName: json['giftName'],
      giftDescription: json['giftDescription'],
      giftImage: json['giftImage'],
      giftPoint: json['giftPoint'],
      giftCode: json['giftCode'],
    );
  }

  static List<Gift> fromJsonList(String jsonString) {
    final data = jsonDecode(jsonString);
    if (data['flag'] == true && data['data'] != null) {
      return List<Gift>.from(data['data'].map((gift) => Gift.fromJson(gift)));
    }
    return [];
  }
}
