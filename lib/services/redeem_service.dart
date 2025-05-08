import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/redeem_history.dart';

class RedeemService {
  static const String _baseUrl = "http://10.0.2.2:5050";

  static Future<List<RedeemHistory>> fetchRedeemHistories(
      String accountId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(
        Uri.parse("$_baseUrl/redeemhistory/app/$accountId"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['flag'] == true && jsonResponse['data'] != null) {
          List<dynamic> data = jsonResponse['data'];
          return data.map((gift) => RedeemHistory.fromJson(gift)).toList();
        } else {
          // Return an empty list instead of throwing an exception
          return [];
        }
      } else {
        throw Exception("Failed to load gifts: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching gifts: $e");
    }
  }

  static Future<bool> cancelRedemption(
      String accountId, String giftId, int requiredPoints) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token'; // ✅ Add token correctly
    }

    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/api/Account/refundPoint?accountId=$accountId"),
        headers: headers, // ✅ Use headers here
        body: json.encode({
          'giftId': giftId,
          'requiredPoints': requiredPoints,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse['flag'] == true;
      } else {
        throw Exception("Failed to cancel redemption: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error cancelling redemption: $e");
    }
  }
}
