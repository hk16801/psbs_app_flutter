import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class GiftDetailPage extends StatefulWidget {
  final String giftId;

  const GiftDetailPage({Key? key, required this.giftId}) : super(key: key);

  @override
  _GiftDetailPageState createState() => _GiftDetailPageState();
}

class _GiftDetailPageState extends State<GiftDetailPage> {
  Map<String, dynamic>? gift;
  bool isLoading = true;
  String? error;
  late String userId;
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadAccountId(); // Ensure userId is set first
    fetchGiftDetail(); // Then fetch gift details
  }

  Future<void> _loadAccountId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('accountId') ?? "";
  }

  Future<void> fetchGiftDetail() async {
    final String apiUrl = 'http://10.0.2.2:5050/Gifts/detail/${widget.giftId}';

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token', // ✅ Add token
        },
      );

      final data = json.decode(response.body);

      if (data['flag']) {
        setState(() {
          gift = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          error = data['message'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'An error occurred while fetching gift details.';
        isLoading = false;
      });
    }
  }

  void handleRedeem() async {
    final String redeemUrl =
        'http://10.0.2.2:5050/api/Account/redeem-points/${userId}';
    print(redeemUrl);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse(redeemUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token', // ✅ Add token
        },
        body: json.encode({
          "giftId": widget.giftId, // Sending gift ID
          "requiredPoints": gift!['giftPoint'], // Sending required points
        }),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      final data = json.decode(response.body);

      if (data['flag']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gift redeemed successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Redeem failed!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred while redeeming the gift.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gift Details'),
        backgroundColor: Colors.blue,
        ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : error != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            'http://10.0.2.2:5050${gift!['giftImage']}',
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported,
                                    size: 100),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          gift!['giftName'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),

                        // Points with icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars,
                                color: Colors.orange, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              "Points: ${gift!['giftPoint']}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Divider
                        const Divider(thickness: 1.2),

                        // Description with icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.description,
                                color: Colors.green, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${gift!['giftDescription'] ?? "No description available"}",
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.justify,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Animated Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: handleRedeem,
                            icon: const Icon(Icons.card_giftcard, size: 24),
                            label: const Text(
                              'Redeem Gift',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 5,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
