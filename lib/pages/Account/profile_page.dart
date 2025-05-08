import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final String accountId;
  const ProfilePage(
      {super.key, required this.accountId, required String title});
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? account;
  String? imagePreview;
  String accountId = '';
  Future<void>? _fetchDataFuture;

  @override
  void initState() {
    super.initState();
    _loadAccountId();
  }

  // Hàm định dạng ngày
  String formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  // Hàm lấy header với token từ SharedPreferences
  Future<Map<String, String>> getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _loadAccountId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      accountId = prefs.getString('accountId') ?? '';
    });
    print("Loaded Account ID: $accountId");
    if (accountId.isNotEmpty) {
      setState(() {
        _fetchDataFuture = fetchAccountData();
      });
    }
  }

  Future<void> fetchAccountData() async {
    if (accountId.isEmpty) {
      print("Lỗi: Account ID rỗng.");
      return;
    }
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/Account?AccountId=$accountId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          account = data;
          if (account?['accountImage'] != null) {
            fetchImage(account?['accountImage']);
          }
        });
      } else {
        print("Error account: ${response.statusCode}");
      }
    } catch (error) {
      print("Error call API: $error");
    }
  }

  Future<void> fetchImage(String filename) async {
    if (filename.isEmpty) {
      print("Error: Filename null.");
      return;
    }
    try {
      final headers = await getHeaders();
      final imageResponse = await http.get(
        Uri.parse(
            'http://10.0.2.2:5050/api/Account/loadImage?filename=$filename'),
        headers: headers,
      );
      if (imageResponse.statusCode == 200) {
        final imageData = jsonDecode(imageResponse.body);
        if (imageData['flag']) {
          setState(() {
            imagePreview =
                "data:image/png;base64,${imageData['data']['fileContents']}";
          });
        }
      }
    } catch (error) {
      print("Error Image: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _fetchDataFuture == null
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<void>(
              future: _fetchDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error load data'));
                }
                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      automaticallyImplyLeading:
                          false, // Không hiển thị nút back tự động
                      expandedHeight: 300,
                      pinned: true,
                      backgroundColor: Colors.blue,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            imagePreview != null
                                ? Image.memory(
                                    base64Decode(imagePreview!.split(',')[1]),
                                    fit: BoxFit.cover,
                                  )
                                : Container(color: Colors.grey),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12, blurRadius: 5)
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    account?['accountName'] ?? 'N/A',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  ProfileField(
                                      label: "Email",
                                      value: account?['accountEmail'] ?? 'N/A'),
                                  ProfileField(
                                      label: "Birthday",
                                      value: formatDate(
                                          account?['accountDob'] ?? '')),
                                  ProfileField(
                                      label: "Phone Number",
                                      value: account?['accountPhoneNumber'] ??
                                          'N/A'),
                                  ProfileField(
                                      label: "Address",
                                      value:
                                          account?['accountAddress'] ?? 'N/A'),
                                  ProfileField(
                                      label:
                                          "Loyalty Points", // Thêm Loyalty Point ở đây
                                      value: account?['accountLoyaltyPoint']
                                              ?.toString() ??
                                          '0'),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, "/editprofile")
                                        .then((result) {
                                      if (result == true) {
                                        setState(() {
                                          _fetchDataFuture = fetchAccountData();
                                        });
                                      }
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                  child: Text("Edit",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                        context, "/changepassword");
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[400],
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                  child: Text("Change Password",
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 16)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final String value;
  const ProfileField({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black)),
          SizedBox(height: 4),
          TextField(
            controller: TextEditingController(text: value),
            enabled: false,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
        ],
      ),
    );
  }
}
