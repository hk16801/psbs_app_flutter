import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import '../models/gift.dart';

class GiftService {
  static const String _baseUrl = "http://10.0.2.2:5050";

  static Future<List<Gift>> fetchGifts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse("$_baseUrl/Gifts"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print("Response Body: ${response.body}");
        List jsonResponse = json.decode(response.body)['data'];
        return jsonResponse.map((gift) => Gift.fromJson(gift)).toList();
      } else {
        throw Exception("Failed to load gifts: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching gifts: $e");
    }
  }
}
