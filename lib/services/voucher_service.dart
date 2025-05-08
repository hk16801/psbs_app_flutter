import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/voucher.dart';

class VoucherService {
  static Future<List<Voucher>> fetchVouchers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    Map<String, String> headers = {};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/Voucher/customer'),
        headers: headers);

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body)['data'];
      return jsonResponse.map((voucher) => Voucher.fromJson(voucher)).toList();
    } else {
      throw Exception('Failed to load vouchers');
    }
  }
}
