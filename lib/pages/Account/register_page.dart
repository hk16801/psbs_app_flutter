import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String email = '';
  String phoneNumber = '';
  String password = '';
  String gender = '';
  DateTime? dob;
  String address = '';

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:5050/api/Account/register'),
          headers: {'accept': 'text/plain'},
          body: {
            'RegisterTempDTO.AccountName': name,
            'RegisterTempDTO.AccountEmail': email,
            'RegisterTempDTO.AccountPhoneNumber': phoneNumber,
            'RegisterTempDTO.AccountPassword': password,
            'RegisterTempDTO.AccountGender': gender,
            'RegisterTempDTO.AccountDob': DateFormat('yyyy-MM-dd').format(dob!),
            'RegisterTempDTO.AccountAddress': address,
            'RegisterTempDTO.AccountImage': 'default.jpg',
          },
        );

        final result = jsonDecode(response.body);
        if (response.statusCode == 200 && result['flag']) {
          _showToast('Registration Successful! Please log in.');
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          _showToast(
              result['message'] ?? 'Registration failed. Please try again.');
        }
      } catch (error) {
        _showToast('An error occurred. Please try again.');
      }
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            color: Colors.white,
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, color: Colors.blue, size: 48),
                        SizedBox(width: 8),
                        Text(
                          'Pet',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Ease',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    Text(
                      'Register',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: InputBorder.none,
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Name is required' : null,
                        onSaved: (value) => name = value!,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: InputBorder.none,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value!.isEmpty) return 'Email is required';
                          final emailRegex = RegExp(
                              r'^[a-zA-Z0-9._%-]+@[a-zA0-9.-]+\.[a-zA-Z]{2,6}$');
                          return emailRegex.hasMatch(value)
                              ? null
                              : 'Enter a valid email';
                        },
                        onSaved: (value) => email = value!,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          border: InputBorder.none,
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value!.isEmpty) return 'Phone number is required';
                          final phoneRegex = RegExp(r'^0\d{9}$');
                          return phoneRegex.hasMatch(value)
                              ? null
                              : 'Enter a valid phone number';
                        },
                        onSaved: (value) => phoneNumber = value!,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: InputBorder.none,
                        ),
                        obscureText: true,
                        validator: (value) => value!.length < 6
                            ? 'Password must be at least 6 characters'
                            : null,
                        onSaved: (value) => password = value!,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          labelStyle: TextStyle(color: Colors.black),
                          border: InputBorder.none,
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 'male',
                              child: Text('Male',
                                  style: TextStyle(color: Colors.black))),
                          DropdownMenuItem(
                              value: 'female',
                              child: Text('Female',
                                  style: TextStyle(color: Colors.black))),
                        ],
                        onChanged: (value) => gender = value!,
                        validator: (value) =>
                            value == null ? 'Gender is required' : null,
                        style: TextStyle(color: Colors.black),
                        dropdownColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          border: InputBorder.none,
                        ),
                        readOnly: true,
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setState(() => dob = pickedDate);
                          }
                        },
                        validator: (value) =>
                            dob == null ? 'Date of Birth is required' : null,
                        controller: TextEditingController(
                          text: dob == null
                              ? ''
                              : DateFormat('yyyy-MM-dd').format(dob!),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Address',
                          border: InputBorder.none,
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Address is required' : null,
                        onSaved: (value) => address = value!,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                        backgroundColor: Colors.grey[500],
                        foregroundColor: Colors.white,
                      ),
                      child: Text('REGISTER'),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(color: Colors.black, fontSize: 14),
                          children: [
                            TextSpan(text: "Already have an account? "),
                            TextSpan(
                              text: "Login here",
                              style: TextStyle(color: Colors.cyan),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () =>
                                    Navigator.pushNamed(context, '/login'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
