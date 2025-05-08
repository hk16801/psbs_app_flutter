import 'dart:convert';

class NotificationModel {
  final String notificationId;
  final String userId;
  final String notiTypeName;
  final String notificationTitle;
  final String notificationContent;
  final DateTime createdDate;
  final bool isDeleted;
  bool isRead;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.notiTypeName,
    required this.notificationTitle,
    required this.notificationContent,
    required this.createdDate,
    required this.isDeleted,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'],
      userId: json['userId'],
      notiTypeName: json['notiTypeName'],
      notificationTitle: json['notificationTitle'],
      notificationContent: json['notificationContent'],
      createdDate: DateTime.parse(json['createdDate']),
      isDeleted: json['isDeleted'],
      isRead: json['isRead'],
    );
  }

  static List<NotificationModel> fromJsonList(String jsonString) {
    final data = jsonDecode(jsonString);
    if (data['flag'] == true && data['data'] != null) {
      return List<NotificationModel>.from(
        data['data'].map((item) => NotificationModel.fromJson(item)),
      );
    }
    return [];
  }
}
