import 'dart:convert';
import 'package:http/http.dart' as http;

class BookingTypeService {
  Future<String?> fetchBookingType(String bookingTypeId) async {
    final String url = 'http://10.0.2.2:5050/api/BookingType/$bookingTypeId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['data']['bookingTypeName']; // Extract the booking type name
      } else {
        throw Exception('Failed to load booking type');
      }
    } catch (error) {
      print('Error fetching booking type: $error');
      return null;
    }
  }
}
