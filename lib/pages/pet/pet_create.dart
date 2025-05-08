import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:psbs_app_flutter/pages/pet/pet_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psbs_app_flutter/main.dart';

class PetCreate extends StatefulWidget {
  const PetCreate({super.key});

  @override
  _PetCreateState createState() => _PetCreateState();
}

class _PetCreateState extends State<PetCreate> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  List<PetType> _petTypes = [];
  List<PetBreed> _breeds = [];
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _furTypeController = TextEditingController();
  final TextEditingController _furColorController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _selectedPetTypeId;
  String? _selectedBreedId;
  bool _petGender = true;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    _fetchPetTypes();
  }

  Future<void> _fetchPetTypes() async {
    try {
      setState(() => _isLoading = true);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/petType/available'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          final List<dynamic> data = jsonResponse['data'];

          setState(() {
            _petTypes = data
                .where((type) => type['isDelete'] != true)
                .map((json) => PetType.fromJson(json))
                .toList();
          });
        } else {
          throw Exception('Invalid API response format');
        }
      } else {
        throw Exception('Failed to fetch pet types: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error loading pet types: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBreeds(String petTypeId) async {
    try {
      setState(() => _isLoading = true);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/petBreed/byPetType/$petTypeId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['flag'] == true && data['data'] != null) {
          setState(() {
            _breeds = (data['data'] as List)
                .map((json) => PetBreed.fromJson(json))
                .toList();
          });
        } else {
          setState(() => _breeds = []);
          _showMessage('No breeds available for this pet type');
        }
      } else {
        throw Exception('Failed to fetch breeds');
      }
    } catch (e) {
      _showErrorDialog('Error loading breeds: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select Image Source'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  GestureDetector(
                    child: ListTile(
                      leading: Icon(Icons.photo_library),
                      title: Text('Photo Library'),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          setState(() => _image = File(image.path));
                        }
                      } catch (e) {
                        print('Gallery Error: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error accessing gallery: $e')),
                        );
                      }
                    },
                  ),
                  GestureDetector(
                    child: ListTile(
                      leading: Icon(Icons.photo_camera),
                      title: Text('Camera'),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          setState(() => _image = File(image.path));
                        }
                      } catch (e) {
                        print('Camera Error: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error accessing camera: $e')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _image == null) {
      if (_image == null) {
        _showErrorDialog('Please select a pet image');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accountId = prefs.getString('accountId');
      String? token = prefs.getString('token');

      if (accountId == null || accountId.isEmpty) {
        _showErrorDialog('User not logged in.');
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:5050/api/pet'),
      );

      request.headers.addAll({
        'Authorization': token != null ? 'Bearer $token' : '',
        'Content-Type': 'multipart/form-data',
      });

      request.fields.addAll({
        'petName': _nameController.text,
        'petGender': _petGender.toString(),
        'dateOfBirth': _dateOfBirth != null
            ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
            : '',
        'petBreedId': _selectedBreedId ?? '',
        'petWeight': _weightController.text,
        'petFurType': _furTypeController.text,
        'petFurColor': _furColorController.text,
        'petNote': _noteController.text,
        'accountId': accountId,
      });

      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'imageFile',
          _image!.path,
        ));
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200 && jsonResponse['flag'] == true) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(jsonResponse['message'] ?? 'Failed to create pet');
      }
    } catch (e) {
      _showErrorDialog('Failed to create pet: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 70,
              ),
              SizedBox(height: 15),
              Text(
                'Success!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Pet created successfully',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () async {
                  Navigator.of(context, rootNavigator: true)
                      .pop(); 
                  Navigator.of(context)
                      .pop(true); 
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 70,
              ),
              SizedBox(height: 15),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 15),
              Text(
                message,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blue))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
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
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Add New Pet',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [Colors.blue, Colors.blue.shade700],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Image Picker
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: _image != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.file(_image!,
                                          fit: BoxFit.contain),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 50,
                                          color: Colors.blue,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'Add Pet Photo',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          SizedBox(height: 24),

                          // Basic Information Section
                          _buildSectionTitle('Basic Information'),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Pet Name',
                            icon: Icons.pets,
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Please enter pet name'
                                : null,
                          ),
                          SizedBox(height: 16),

                          // Gender and DOB Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  value: _petGender,
                                  label: 'Gender',
                                  icon: Icons.transgender,
                                  items: [
                                    DropdownMenuItem(
                                      value: true,
                                      child: Text('Male'),
                                    ),
                                    DropdownMenuItem(
                                      value: false,
                                      child: Text('Female'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _petGender = value!);
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildDateField(
                                  label: 'Date of Birth',
                                  value: _dateOfBirth,
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _dateOfBirth ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setState(() => _dateOfBirth = date);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),

                          // Pet Details Section
                          _buildSectionTitle('Pet Details'),
                          _buildDropdownField<String?>(
                            value: _selectedPetTypeId,
                            label: 'Pet Type',
                            icon: Icons.category,
                            items: _petTypes.map((type) {
                              return DropdownMenuItem<String?>(
                                value: type.id,
                                child: Text(type.name),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              setState(() {
                                _selectedPetTypeId = value;
                                _selectedBreedId = null;
                                if (value != null) {
                                  _fetchBreeds(value);
                                }
                              });
                            },
                          ),
                          SizedBox(height: 16),

                          _buildDropdownField<String?>(
                            value: _selectedBreedId,
                            label: 'Breed',
                            icon: Icons.pets,
                            items: _breeds.map((breed) {
                              return DropdownMenuItem<String?>(
                                value: breed.id,
                                child: Text(breed.name),
                              );
                            }).toList(),
                            onChanged: _selectedPetTypeId == null
                                ? null
                                : (String? value) {
                                    setState(() => _selectedBreedId = value);
                                  },
                          ),
                          SizedBox(height: 16),

                          _buildTextField(
                            controller: _weightController,
                            label: 'Weight (kg)',
                            icon: Icons.monitor_weight,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter weight';
                              }
                              if (double.tryParse(value) == null ||
                                  double.parse(value) <= 0) {
                                return 'Please enter a valid weight';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 24),

                          // Appearance Section
                          _buildSectionTitle('Appearance'),
                          _buildTextField(
                            controller: _furTypeController,
                            label: 'Fur Type',
                            icon: Icons.brush,
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Please enter fur type'
                                : null,
                          ),
                          SizedBox(height: 16),

                          _buildTextField(
                            controller: _furColorController,
                            label: 'Fur Color',
                            icon: Icons.palette,
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Please enter fur color'
                                : null,
                          ),
                          SizedBox(height: 24),

                          // Notes Section
                          _buildSectionTitle('Additional Notes'),
                          _buildTextField(
                            controller: _noteController,
                            label: 'Notes',
                            icon: Icons.note,
                            maxLines: 3,
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Please enter notes'
                                : null,
                          ),
                          SizedBox(height: 32),

                          // Submit Button
                          ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'Create Pet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) => value == null ? 'Please select an option' : null,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.calendar_today, color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          // Thêm hint text để chỉ rõ định dạng
          hintText: 'dd/mm/yyyy',
        ),
        controller: TextEditingController(
          // Đổi định dạng hiển thị thành dd/mm/yyyy
          text: value == null ? '' : DateFormat('dd/MM/yyyy').format(value),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select date of birth';
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _furTypeController.dispose();
    _furColorController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}

class PetType {
  final String id;
  final String name;

  PetType({required this.id, required this.name});

  factory PetType.fromJson(Map<String, dynamic> json) {
    return PetType(
      id: json['petType_ID'],
      name: json['petType_Name'],
    );
  }
}

class PetBreed {
  final String id;
  final String name;

  PetBreed({required this.id, required this.name});

  factory PetBreed.fromJson(Map<String, dynamic> json) {
    return PetBreed(
      id: json['petBreedId'],
      name: json['petBreedName'],
    );
  }
}
