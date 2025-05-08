import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'booking_service_choose.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/booking_service_type.dart';
import 'package:intl/intl.dart';


class BookingServiceForm extends StatefulWidget {
  final String? cusId;
  final Function(List<Map<String, dynamic>>) onBookingServiceDataChange;

  const BookingServiceForm({
    required this.cusId,
    required this.onBookingServiceDataChange,
    Key? key,
  }) : super(key: key);

  @override
  _BookingServiceFormState createState() => _BookingServiceFormState();
}

class _BookingServiceFormState extends State<BookingServiceForm> {
  DateTime _selectedDate = DateTime.now();
  List<BookingChoice> _bookingChoices = [];
  List<Service> _services = [];
  List<Pet> _pets = [];
  List<String> _selectedServices = [];
  List<String> _selectedPets = [];
  bool _selectAllServices = false;
  bool _selectAllPets = false;
  String? _error;
  double _totalPrice = 0.0;
  final _currencyFormatter = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _fetchPets();
  }

  Future<void> _fetchServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/Service'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['flag']) {
          setState(() {
            _services = (data['data'] as List)
                .map((service) => Service.fromMap(service))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching services: $e');
    }
  }

  Future<void> _fetchPets() async {
    if (widget.cusId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/pet/available/${widget.cusId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['flag']) {
          setState(() {
            _pets =
                (data['data'] as List).map((pet) => Pet.fromMap(pet)).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching pets: $e');
    }
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    if (pickedTime == null) return;

    final fullDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (fullDateTime.isBefore(DateTime.now().add(const Duration(hours: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time at least 1 hour from now'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _selectedDate = fullDateTime;
    });
  }

  void _handleServiceSelect(String serviceId) {
    setState(() {
      if (serviceId == 'all') {
        _selectAllServices = !_selectAllServices;
        _selectedServices =
            _selectAllServices ? _services.map((s) => s.id).toList() : [];
      } else {
        _selectAllServices = false;
        if (_selectedServices.contains(serviceId)) {
          _selectedServices.remove(serviceId);
        } else {
          _selectedServices.add(serviceId);
        }
      }
    });
  }

  void _handlePetSelect(String petId) {
    setState(() {
      if (petId == 'all') {
        _selectAllPets = !_selectAllPets;
        _selectedPets = _selectAllPets ? _pets.map((p) => p.id).toList() : [];
      } else {
        _selectAllPets = false;
        if (_selectedPets.contains(petId)) {
          _selectedPets.remove(petId);
        } else {
          _selectedPets.add(petId);
        }
      }
    });
  }

  Future<void> _handleCreateBookingServices() async {
    setState(() {
      _error = null;
      _bookingChoices = [];
    });

    await Future.delayed(Duration(milliseconds: 10));

    if (_selectedDate.isBefore(DateTime.now().add(const Duration(hours: 1)))) {
      setState(() {
        _error = 'Please select a valid booking date and time (at least 1 hour from now)';
      });
      return;
    }

    final servicesToBook = _selectAllServices
        ? _services
        : _services.where((s) => _selectedServices.contains(s.id)).toList();

    final petsToBook = _selectAllPets
        ? _pets
        : _pets.where((p) => _selectedPets.contains(p.id)).toList();

    if (servicesToBook.isEmpty || petsToBook.isEmpty) {
      setState(() {
        _error = 'Please select at least one service and one pet';
      });
      return;
    }

    // Create booking choices for each pet-service combination
    for (final pet in petsToBook) {
      for (final service in servicesToBook) {
        final variants = await _fetchServiceVariants(service.id);

        if (variants.isEmpty) {
          print('Warning: No variants found for service ${service.name}');
          continue; // Skip this service if no variants available
        }

        // Always select the first variant by default
        final defaultVariant = variants.first;
        
        setState(() {
          _bookingChoices.add(BookingChoice(
            service: service,
            pet: pet,
            serviceVariant: defaultVariant, // Set first variant as default
            price: defaultVariant.price,    // Set price from first variant
            bookingDate: _selectedDate.toIso8601String(),
            variants: variants,
          ));
        });
      }
    }
    _selectedServices = [];
    _selectedPets = [];
    _selectAllServices = false;
    _selectAllPets = false;
    _totalPrice = 0;

    _updateBookingServiceData();
    _calculateTotalPrice();
  }

  Future<List<ServiceVariant>> _fetchServiceVariants(String serviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse("http://10.0.2.2:5050/api/ServiceVariant/service/$serviceId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody.containsKey("data") && responseBody["data"] is List) {
          return (responseBody["data"] as List)
              .map((variant) => ServiceVariant.fromMap(variant))
              .toList();
        }
      }
    } catch (error) {
      print("Error fetching service variants: $error");
    }
    return [];
  }

  void _updateBookingServiceData() {
    print('=== BookingServiceForm: _updateBookingServiceData ===');
    
    final formattedData = _bookingChoices.map((choice) {
      final serviceVariant = choice.serviceVariant;
      print('Processing choice - Service: ${choice.service.name}, Variant: ${serviceVariant?.content}, Price: ${serviceVariant?.price}');
      
      final data = {
        'service': {
          'id': choice.service.id,
          'name': choice.service.name,
        },
        'pet': {
          'id': choice.pet.id,
          'name': choice.pet.name,
        },
        'serviceVariant': {
          'id': serviceVariant?.id ?? '',
          'content': serviceVariant?.content ?? '',
          'price': serviceVariant?.price ?? 0.0,
        },
        'price': serviceVariant?.price ?? 0.0,
        'bookingDate': choice.bookingDate,
      };
      
      print('Formatted data for ${choice.service.name}:');
      print(json.encode(data));
      return data;
    }).toList();

    widget.onBookingServiceDataChange(formattedData);
  }

  void _removeBookingChoice(int index) {
    setState(() {
      _bookingChoices.removeAt(index);
    });
    _updateBookingServiceData();
    _calculateTotalPrice();
  }

  void _calculateTotalPrice() {
    final total =
        _bookingChoices.fold(0.0, (sum, choice) => sum + choice.price);
    setState(() {
      _totalPrice = total;
    });
  }

  void _onBookingChoiceUpdate() {
    print('=== BookingServiceForm: _onBookingChoiceUpdate ===');
    print('Current Booking Choices:');
    for (var choice in _bookingChoices) {
      print('Service: ${choice.service.name}');
      print('Variant: ${choice.serviceVariant?.content} - ${choice.serviceVariant?.price}');
    }
    
    _updateBookingServiceData();
    _calculateTotalPrice();
  }

  void _handleVariantChange(BookingChoice updatedChoice) {
    print('=== BookingServiceForm: _handleVariantChange ===');
    print('Updated Variant: ${updatedChoice.serviceVariant?.content} - ${updatedChoice.serviceVariant?.price}');
    
    setState(() {
      final index = _bookingChoices.indexWhere(
        (choice) => choice.service.id == updatedChoice.service.id && 
                    choice.pet.id == updatedChoice.pet.id
      );
      
      if (index != -1) {
        _bookingChoices[index] = updatedChoice;
      }
    });
    
    _updateBookingServiceData();
  }

String _getMonthName(int month) {
  const monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return monthNames[month - 1];
}


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Date Selection
Card(
  margin: const EdgeInsets.all(8),
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(
        colors: [
          Colors.blue.shade50,
          Colors.white,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                "Select Booking Date & Time",
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.blue.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade200.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _selectDateTime,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    // Format date as dd mm yyyy HH:mm
                    "${_selectedDate.day.toString().padLeft(2, '0')} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year} ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedDate.isBefore(DateTime.now().add(const Duration(hours: 1))))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Please select a time at least 1 hour from now",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
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

          // Services Selection
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Services",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  CheckboxListTile(
                    title: const Text("All Services"),
                    value: _selectAllServices,
                    onChanged: (bool? value) => _handleServiceSelect('all'),
                  ),
                  if (!_selectAllServices)
                    ..._services.map((service) => CheckboxListTile(
                          title: Text(service.name),
                          value: _selectedServices.contains(service.id),
                          onChanged: (bool? value) =>
                              _handleServiceSelect(service.id),
                        )),
                ],
              ),
            ),
          ),

          // Pets Selection
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Pets",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  CheckboxListTile(
                    title: const Text("All Pets"),
                    value: _selectAllPets,
                    onChanged: (bool? value) => _handlePetSelect('all'),
                  ),
                  if (!_selectAllPets)
                    ..._pets.map((pet) => CheckboxListTile(
                          title: Text(pet.name),
                          value: _selectedPets.contains(pet.id),
                          onChanged: (bool? value) => _handlePetSelect(pet.id),
                        )),
                ],
              ),
            ),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          ElevatedButton(
            onPressed: _handleCreateBookingServices,
            child: const Text("Create Booking Services"),
          ),

          // Booking Choices List
          ..._bookingChoices.asMap().entries.map((entry) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    title: Text("Service Booking #${entry.key + 1}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeBookingChoice(entry.key),
                    ),
                  ),
                  BookingServiceChoice(
                    cusId: widget.cusId ?? "",
                    bookingChoices: [_bookingChoices[entry.key]],
                    onRemove: (index) => _removeBookingChoice(index),
                    onUpdate: _onBookingChoiceUpdate,
                    onVariantChange: _handleVariantChange,
                  ),
                ],
              ),
            );
          }).toList(),

          // Price Summary
          Card(
  margin: const EdgeInsets.all(8),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Price Summary",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          "Total Price: ${_currencyFormatter.format(_totalPrice)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    ),
  ),
),
        ],
      ),
    );
  }
}
