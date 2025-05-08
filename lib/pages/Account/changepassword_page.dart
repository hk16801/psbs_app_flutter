import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ChangePasswordPage extends StatefulWidget {
  final String accountId;
  const ChangePasswordPage(
      {super.key, required this.accountId, required String title});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? account;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String accountId = '';
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  Future<void>? _fetchDataFuture;
  String? imagePreview;
  String? accountName;

  @override
  void initState() {
    super.initState();
    _loadAccountId();
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/Account?AccountId=$accountId'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'App-Version': '1.0.0',
          'Device-ID': '12345',
          'User-Agent': 'PetEaseApp/1.0.0',
          'Platform': 'Android',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          account = data;
          accountName = data['accountName'];
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final imageResponse = await http.get(
        Uri.parse(
            'http://10.0.2.2:5050/api/Account/loadImage?filename=$filename'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'App-Version': '1.0.0',
          'Device-ID': '12345',
          'User-Agent': 'PetEaseApp/1.0.0',
          'Platform': 'Android',
          if (token != null) 'Authorization': 'Bearer $token',
        },
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
      print("Error fetching image: $error");
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final String apiUrl =
          'http://10.0.2.2:5050/api/Account/ChangePassword$accountId';
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'App-Version': '1.0.0',
          'Device-ID': '12345',
          'User-Agent': 'PetEaseApp/1.0.0',
          'Platform': 'Android',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
          'confirmPassword': _confirmPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        _showToast('Password changed successfully!');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final errorData = jsonDecode(response.body);
        _showToast(errorData['message'] ?? 'Failed to change password');
      }
    } catch (error) {
      print("Error change password: $error");
      _showToast('An error occurred. Please try again.');
    }
  }

  Widget buildPasswordField(String label, TextEditingController controller,
      bool isPasswordVisible, VoidCallback toggleVisibility) {
    return TextFormField(
      controller: controller,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: toggleVisibility,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (label == "New Password" || label == "Confirm Password") {
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
        }
        if (label == "Confirm Password") {
          if (value != _newPasswordController.text) {
            return 'Passwords do not match';
          }
        }
        return null;
      },
    );
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
                  return Center(child: Text('Lỗi khi tải dữ liệu'));
                }
                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 300,
                      pinned: true,
                      backgroundColor: Colors.blue,
                      leading: IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_back, color: Colors.blue),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            (imagePreview != null && imagePreview!.isNotEmpty)
                                ? Image.memory(
                                    base64Decode(imagePreview!.split(",")[1]),
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
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              account?['accountName'] ?? 'Your Account Name',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey, width: 1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: buildPasswordField(
                                      'Current Password',
                                      _currentPasswordController,
                                      _showCurrentPassword,
                                      () {
                                        setState(() => _showCurrentPassword =
                                            !_showCurrentPassword);
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey, width: 1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: buildPasswordField(
                                      'New Password',
                                      _newPasswordController,
                                      _showNewPassword,
                                      () {
                                        setState(() => _showNewPassword =
                                            !_showNewPassword);
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey, width: 1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: buildPasswordField(
                                      'Confirm Password',
                                      _confirmPasswordController,
                                      _showConfirmPassword,
                                      () {
                                        setState(() => _showConfirmPassword =
                                            !_showConfirmPassword);
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: _changePassword,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 12),
                                        ),
                                        child: Text("Change Password",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
