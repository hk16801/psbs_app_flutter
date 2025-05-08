import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';

class NotificationService {
  static const String _baseUrl = "http://10.0.2.2:5050";

  static Future<List<NotificationModel>> fetchNotifications(
      String accountId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(
        Uri.parse("$_baseUrl/api/notification/user/$accountId"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['flag'] == true && jsonResponse['data'] != null) {
          List<dynamic> data = jsonResponse['data'];
          return data.map((gift) => NotificationModel.fromJson(gift)).toList();
        } else {
          // Return an empty list instead of throwing an exception
          return [];
        }
      } else {
        throw Exception("Failed to load notification: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching notification: $e");
    }
  }

  static Future<bool> deleteNotification(String notificationId) async {
    print("day la id ne" + notificationId);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse("$_baseUrl/api/notification/user/$notificationId"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['flag'] == true) {
          return true;
        } else {
          return false;
        }
      } else {
        throw Exception("Failed to delete notification");
      }
    } catch (e) {
      throw Exception("Error deleting notification: $e");
    }
  }
   static Future<bool> markAsRead(String notificationId) async {
    print("day la id ne" + notificationId);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse("$_baseUrl/api/Notification/user/isRead/$notificationId"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['flag'] == true) {
          return true;
        } else {
          return false;
        }
      } else {
        throw Exception("Failed to read notification");
      }
    } catch (e) {
      throw Exception("Error read notification: $e");
    }
  }
}
