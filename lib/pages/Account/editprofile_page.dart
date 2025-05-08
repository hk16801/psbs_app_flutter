import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage(
      {super.key, required String title, required String accountId});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  String accountId = '';
  String? email;
  String role = "user";
  String gender = "male";
  DateTime? dob;
  bool isImagePicked = false;
  File? profileImage;
  String? imagePreview;
  Map<String, dynamic>? account;

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
    if (accountId.isNotEmpty) {
      _fetchAccountData();
    }
  }

  Future<void> _fetchAccountData() async {
    if (accountId.isEmpty) return;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/Account?AccountId=$accountId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          nameController.text = data['accountName'] ?? '';
          email = data['accountEmail'];
          phoneController.text = data['accountPhoneNumber'] ?? '';
          addressController.text = data['accountAddress'] ?? '';
          gender = data['accountGender'] ?? 'male';
          role = data['roleId'] ?? 'user';
          dob = data['accountDob'] != null
              ? DateTime.parse(data['accountDob'])
              : null;

          if (data['accountImage'] != null) {
            fetchImage(data['accountImage']);
          }
        });
      } else {
        _showToast('Failed to load account data.', backgroundColor: Colors.red);
      }
    } catch (error) {
      _showToast('Error fetching account data: $error',
          backgroundColor: Colors.red);
    }
  }

  Future<void> fetchImage(String filename) async {
    if (filename.isEmpty) return;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final imageResponse = await http.get(
        Uri.parse(
            'http://10.0.2.2:5050/api/Account/loadImage?filename=$filename'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (imageResponse.statusCode == 200) {
        final imageData = jsonDecode(imageResponse.body);
        if (imageData['flag'] && imageData['data']?['fileContents'] != null) {
          String base64String = imageData['data']['fileContents'];
          if (base64String.contains(",")) {
            base64String = base64String.split(",")[1];
          }
          setState(() {
            imagePreview = base64String;
          });
        }
      }
    } catch (error) {
      print("Error fetching image: $error");
    }
  }

  // Hàm showToast sử dụng Fluttertoast để hiển thị thông báo
  void _showToast(String message, {Color backgroundColor = Colors.black54}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('http://10.0.2.2:5050/api/Account'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'application/json';
      String updatedAt =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      request.fields['accountTempDTO.accountId'] = accountId;
      request.fields['accountTempDTO.accountName'] = nameController.text;
      request.fields['accountTempDTO.accountEmail'] = email ?? '';
      request.fields['accountTempDTO.accountPhoneNumber'] =
          phoneController.text;
      request.fields['accountTempDTO.accountGender'] = gender;
      request.fields['accountTempDTO.accountDob'] =
          dob != null ? DateFormat('yyyy-MM-dd').format(dob!) : '';
      request.fields['accountTempDTO.accountAddress'] = addressController.text;
      request.fields['accountTempDTO.isPickImage'] = isImagePicked.toString();
      request.fields['accountTempDTO.roleId'] = role;
      request.fields['accountTempDTO.updatedAt'] = updatedAt;

      if (isImagePicked && profileImage != null) {
        var file = await http.MultipartFile.fromPath(
          'uploadModel.imageFile',
          profileImage!.path,
          filename: profileImage!.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(file);
      }

      final response = await request.send();
      final responseCompleted = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final result = json.decode(responseCompleted.body);
        if (result['flag']) {
          _showToast('Profile updated successfully!',
              backgroundColor: Colors.green);
          Navigator.of(context).pop(true);
        } else {
          _showToast(result['message'] ?? 'Something went wrong.',
              backgroundColor: Colors.red);
        }
      } else {
        _showToast('Failed to update profile.', backgroundColor: Colors.red);
      }
    } catch (error) {
      _showToast('Error: $error', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.blue,
            automaticallyImplyLeading: false,
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
              background: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    profileImage != null
                        ? Image.file(profileImage!, fit: BoxFit.cover)
                        : (imagePreview != null && imagePreview!.isNotEmpty)
                            ? Image.memory(base64Decode(imagePreview!),
                                fit: BoxFit.cover)
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ProfileField(label: 'Name', controller: nameController),
                    const SizedBox(height: 20),
                    ProfileField(
                      label: 'Email',
                      controller: TextEditingController(text: email),
                      enabled: false,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Birthday',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: dob ?? DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (selectedDate != null) {
                              setState(() => dob = selectedDate);
                            }
                          },
                        ),
                      ),
                      controller: TextEditingController(
                        text: dob != null
                            ? DateFormat('dd/MM/yyyy').format(dob!)
                            : '',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ProfileField(
                      label: 'Phone Number',
                      controller: phoneController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        final regex = RegExp(r'^0\d{9}$');
                        if (!regex.hasMatch(value)) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ProfileField(
                        label: 'Address', controller: addressController),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: const Text("Save",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: const Text("Back",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        profileImage = File(pickedFile.path);
        imagePreview = null;
        isImagePicked = true;
      });
      print("Selected image file: ${pickedFile.path.split('/').last}");
    } else {
      setState(() {
        isImagePicked = false;
      });
      print("No image selected.");
    }
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;

  const ProfileField({
    super.key,
    required this.label,
    required this.controller,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black)),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            enabled: enabled,
            validator: validator,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
        ],
      ),
    );
  }
}
