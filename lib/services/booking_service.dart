import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/Booking.dart';

class BookingService {
  Future<List<Booking>> fetchBookings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? accountId = prefs.getString('accountId'); // Retrieve accountId

    if (token == null || accountId == null) {
      throw Exception('No token or accountId found. User must log in.');
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/Bookings/list/$accountId'), // API URL
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Attach token
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['flag'] == true) {
          List<dynamic> data = jsonResponse['data'];
          return data.map((json) => Booking.fromJson(json)).toList();
        } else {
          throw Exception(
              'Failed to load bookings: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Failed to load bookings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }
}
