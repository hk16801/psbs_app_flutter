import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:psbs_app_flutter/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psbs_app_flutter/pages/pet/pet_page.dart';

class PetEdit extends StatefulWidget {
  final String petId;

  const PetEdit({super.key, required this.petId});

  @override
  _PetEditState createState() => _PetEditState();
}

class _PetEditState extends State<PetEdit> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  String? _imagePreview;
  String? _oldPetImage;
  List<PetType> _petTypes = [];
  List<PetBreed> _breeds = [];
  bool _isLoading = false;
  final Map<String, String> _errors = {};
  bool _hasInteractedWithImage = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _furTypeController = TextEditingController();
  final TextEditingController _furColorController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _selectedPetTypeId;
  String? _selectedBreedId;
  bool _petGender = true;
  DateTime? _dateOfBirth;
  String? _accountId;
  late String userId;
  @override
  void initState() {
    super.initState();
    _fetchPetData();
    _fetchPetTypes();
    _loadAccountId();
  }

  Future<void> _loadAccountId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('accountId') ?? ""; // Ensure it's never null
    });
  }

  Future<void> _fetchPetData() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/pet/${widget.petId}'),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['flag']) {
          final petData = data['data'];
          setState(() {
            _nameController.text = petData['petName'];
            _weightController.text = petData['petWeight'].toString();
            _furTypeController.text = petData['petFurType'];
            _furColorController.text = petData['petFurColor'];
            _noteController.text = petData['petNote'];
            _petGender = petData['petGender'];
            _dateOfBirth = DateTime.parse(petData['dateOfBirth']);
            _selectedPetTypeId = petData['petTypeId'];
            _selectedBreedId = petData['petBreedId'];
            _accountId = petData['accountId'];
            _imagePreview = petData['petImage'] != null
                ? 'http://10.0.2.2:5050/pet-service${petData['petImage']}'
                : null;
            _oldPetImage = petData['petImage'];
          });

          if (_selectedPetTypeId != null) {
            await _fetchBreeds(_selectedPetTypeId!);
          }
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to fetch pet details');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPetTypes() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/petType/available'),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
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
          _showErrorDialog('Invalid API response format');
        }
      } else {
        _showErrorDialog('Failed to fetch pet types: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Failed to fetch pet types');
    }
  }

  Future<void> _fetchBreeds(String petTypeId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/petBreed/byPetType/$petTypeId'),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['flag'] && data['data'] != null) {
          setState(() {
            _breeds = (data['data'] as List)
                .map((json) => PetBreed.fromJson(json))
                .toList();
          });
        } else {
          setState(() => _breeds = []);
          _showMessage('No breeds available for this pet type');
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to fetch breeds');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Photo Library'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      setState(() {
                        _image = File(image.path);
                        _imagePreview = image.path;
                        _hasInteractedWithImage = true;
                      });
                    }
                  } catch (e) {
                    _showErrorDialog('Error accessing gallery');
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      setState(() {
                        _image = File(image.path);
                        _imagePreview = image.path;
                        _hasInteractedWithImage = true;
                      });
                    }
                  } catch (e) {
                    _showErrorDialog('Error accessing camera');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    bool confirm = await showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.yellow.shade100,
                    radius: 45,
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 50,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Are you sure?",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Do you want to update this \n pet's information?\nThis action may affect related data in the system.",
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Update',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      setState(() => _isLoading = true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('http://10.0.2.2:5050/api/pet'),
      );
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      request.fields.addAll({
        'petId': widget.petId,
        'accountId': _accountId!,
        'petName': _nameController.text,
        'petGender': _petGender.toString(),
        'dateOfBirth': DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
        'petBreedId': _selectedBreedId!,
        'petWeight': _weightController.text,
        'petFurType': _furTypeController.text,
        'petFurColor': _furColorController.text,
        'petNote': _noteController.text,
      });
      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'imageFile',
          _image!.path,
        ));
      }
      var response = await request.send();
      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        String responseData = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseData);
        String errorMessage =
            decodedResponse['message'] ?? 'Lỗi không xác định';
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      _showErrorDialog('Lỗi khi cập nhật thú cưng: $e');
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 70,
              ),
              SizedBox(height: 20),
              Text(
                'Success!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Pet updated successfully',
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
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.pop(context, 'refresh');
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 70,
              ),
              SizedBox(height: 20),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
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
                onPressed: () {
                  Navigator.of(context).pop();
                },
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
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
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
                      'Edit Pet',
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
                          colors: [Colors.blue.shade300, Colors.blue.shade700],
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
                                ),
                              ),
                              child: _imagePreview != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: _image != null
                                          ? Image.file(_image!,
                                              fit: BoxFit.contain)
                                          : Image.network(_imagePreview!,
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
                                          'Change Pet Photo',
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
                              if (value?.isEmpty ?? true)
                                return 'Please enter weight';
                              if (double.tryParse(value!) == null ||
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

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  'Update',
                                  Icons.check,
                                  Colors.blue,
                                  _handleSubmit,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildActionButton('Cancel', Icons.close,
                                    Colors.red, () => Navigator.pop(context)),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
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
          hintText: 'dd/mm/yyyy',
        ),
        controller: TextEditingController(
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

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Add these classes at the end of the file
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
