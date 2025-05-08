import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'booking_room_form.dart';
import 'booking_service_form.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'vnpay_webview.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class AddBookingPage extends StatefulWidget {
  @override
  _AddBookingPageState createState() => _AddBookingPageState();
}

class _AddBookingPageState extends State<AddBookingPage> {
  // Network configuration
  static const String apiBaseUrl = 'http://10.0.2.2:5050';
  static const String bookingBaseUrl = 'http://10.0.2.2:5050';

  static const String paymentBaseUrl = 'https://10.0.2.2:5201';


  // Rest of your existing variables
  int _currentStep = 0;
  String? _cusId;
  List<Map<String, dynamic>> _paymentTypes = [];
  String? _selectedPaymentType;
  String _serviceType = '';
  List<Map<String, dynamic>> _bookingRoomData = [];
  List<Map<String, dynamic>> _bookingServiceData = [];
  List<Map<String, dynamic>> _vouchers = [];
  String? _selectedVoucher;
  double _totalPrice = 0.0;
  Map<String, String> _roomNames = {};
  Map<String, String> _petNames = {};
  bool _isProcessing = false;
  String _voucherSearchCode = '';
  bool _searchLoading = false;
  String _searchError = '';
  final _currencyFormatter = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);

  @override
  void initState() {
    super.initState();
    _loadCustomerId();
    _fetchPaymentTypes();
    _fetchVouchers();
  }

  Future<void> _loadCustomerId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _cusId = prefs.getString('accountId');
      });
    }
  }

  Future<void> _fetchPaymentTypes() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/PaymentType'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          _paymentTypes = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (e) {
      print("Error fetching payment types: $e");
    }
  }

  Future<void> _fetchVouchers() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/Voucher/valid-voucher'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          _vouchers = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (e) {
      print("Error fetching vouchers: $e");
    }
  }

  void _updateBookingRoomData(List<Map<String, dynamic>> data) {
    if (!mounted) return;
    setState(() {
      _bookingRoomData = data;
      _calculateTotalPrice();
    });
    for (var room in data) {
      if (room.containsKey('room')) {
        _fetchRoomName(room['room'].toString());
      }
      if (room.containsKey('pet')) {
        _fetchPetName(room['pet'].toString());
      }
    }
  }

  void _updateBookingServiceData(List<Map<String, dynamic>> data) {
    print('=== AddBookingPage: _updateBookingServiceData ===');
    print('Received Data:');
    print(json.encode(data));

    if (mounted) {
      setState(() {
        _bookingServiceData = List<Map<String, dynamic>>.from(data);
        print(
            'Updated _bookingServiceData length: ${_bookingServiceData.length}');
        print(
            'Updated Service Variant: ${_bookingServiceData.first['serviceVariant']['content']} - ${_bookingServiceData.first['serviceVariant']['price']}');
        _calculateTotalPrice();
      });
    }
  }

  void _calculateTotalPrice() {
    double total = 0.0;
    double subtotal = 0.0;

    if (_serviceType == "Room") {
      subtotal = _bookingRoomData.fold(0.0, (sum, room) {
        double price = double.tryParse(room["price"].toString()) ?? 0.0;
        return sum + price;
      });
    } else if (_serviceType == "Service") {
      subtotal = _bookingServiceData.fold(0.0, (sum, service) {
        if (service["serviceVariant"] != null) {
          double price =
              double.tryParse(service["serviceVariant"]["price"].toString()) ??
                  0.0;
          return sum + price;
        }
        return sum;
      });
    }

    // Apply voucher discount if selected
    if (_selectedVoucher != null) {
      var voucher = _vouchers.firstWhere(
          (v) => v['voucherId'] == _selectedVoucher,
          orElse: () => {});

      if (voucher.isNotEmpty) {
        double discount =
            double.tryParse(voucher['voucherDiscount'].toString()) ?? 0.0;
        double maxDiscount =
            double.tryParse(voucher['voucherMaximum'].toString()) ?? 0.0;

        // Calculate discount amount
        double discountAmount =
            (subtotal * discount / 100).clamp(0, maxDiscount);
        total = subtotal - discountAmount;

        print('=== Price Calculation with Voucher ===');
        print('Subtotal: $subtotal');
        print('Discount Percentage: $discount%');
        print('Maximum Discount: $maxDiscount');
        print('Applied Discount: $discountAmount');
        print('Final Total: $total');
      } else {
        total = subtotal;
      }
    } else {
      total = subtotal;
    }

    if (mounted) {
      setState(() {
        _totalPrice = total;
      });
    }
  }

  Future<void> _fetchRoomName(String roomId) async {
    if (_roomNames.containsKey(roomId)) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/Room/$roomId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          _roomNames[roomId] = data['data']['roomName'] ?? 'Unknown Room';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _roomNames[roomId] = 'Unknown Room';
        });
      }
    }
  }

  Future<void> _fetchPetName(String petId) async {
    if (_petNames.containsKey(petId)) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/pet/$petId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          _petNames[petId] = data['data']['petName'] ?? 'Unknown Pet';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _petNames[petId] = 'Unknown Pet';
        });
      }
    }
  }

  Future<void> _searchVoucher() async {
    if (_voucherSearchCode.trim().isEmpty) {
      setState(() {
        _searchError = "Please enter a voucher code";
      });
      return;
    }

    setState(() {
      _searchLoading = true;
      _searchError = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      final response = await http.get(
        Uri.parse(
            '$apiBaseUrl/api/Voucher/search-gift-code?voucherCode=$_voucherSearchCode'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['flag'] && data['data'] != null) {
          // Check if this voucher is already in our list
          bool exists =
              _vouchers.any((v) => v['voucherId'] == data['data']['voucherId']);

          if (!exists) {
            setState(() {
              _vouchers = [..._vouchers, data['data']];
            });
          }

          setState(() {
            _selectedVoucher = data['data']['voucherId'];
            _calculateTotalPrice();
          });
        } else {
          setState(() {
            _searchError = data['message'] ?? "Voucher not found";
          });
        }
      }
    } catch (e) {
      setState(() {
        _searchError = "Error searching voucher";
      });
      print("Error searching voucher: $e");
    } finally {
      setState(() {
        _searchLoading = false;
      });
    }
  }

  Future<bool> _launchUrl(String url) async {
  try {
    print('[DEBUG] Attempting to launch URL: $url');

    final uri = Uri.parse(url);
    
    // First check if we can launch the URL
    if (await canLaunchUrl(uri)) {
      // Try to launch in external application
      final result = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      print('[DEBUG] launchUrl result: $result');
      return result;
    } else {
      print('[WARNING] Cannot launch URL: $url');
      return false;
    }
  } catch (e, stackTrace) {
    print('[ERROR] Exception in _launchUrl: $e\n$stackTrace');
    return false;
  }
}



  Future<String?> _getPaymentTypeName(String paymentTypeId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/PaymentType/$paymentTypeId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['flag']) {
          return data['data']['paymentTypeName'];
        }
      }
      return null;
    } catch (e) {
      print("Error fetching payment type: $e");
      return null;
    }
  }

  Future<void> _processVNPayPayment(String bookingCode, double amount) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    
    // Apply certificate bypass
    HttpOverrides.global = DevHttpOverrides();
    
    await prefs.setString('current_payment_booking_code', bookingCode);
    
    final description = jsonEncode({
      'bookingCode': bookingCode.trim(),
      'redirectPath': '/customer/bookings'
    });
    
    final response = await _secureGet(
      '$paymentBaseUrl/api/VNPay/CreatePaymentUrl?'
      'moneyToPay=${amount.toInt()}&'
      'description=${Uri.encodeComponent(description)}',
      {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      final vnpayUrl = response.body.trim();
      
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VNPayWebView(url: vnpayUrl),
          ),
        );
        
        // If we get a result back, we can handle it here
        if (result == true) {
          // Payment was successful, navigate back to booking list
          Navigator.pop(context, true);
        }
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: ${e.toString()}')),
      );
    }
  }
}

// Add this method to your _AddBookingPageState class
Future<http.Response> _secureGet(String url, Map<String, String> headers) async {
  // Apply certificate bypass for development
  HttpOverrides.global = DevHttpOverrides();
  
  try {
    final client = http.Client();
    final response = await client.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(Duration(seconds: 30));
    
    return response;
  } catch (e) {
    print('[ERROR] HTTP request failed: $e');
    rethrow;
  }
}



  Future<void> _sendRoomBookingRequest() async {
    if (mounted) setState(() => _isProcessing = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? accountId = prefs.getString('accountId');

      String? paymentTypeName =
          await _getPaymentTypeName(_selectedPaymentType ?? '');

      final customerResponse = await http.get(
        Uri.parse('$apiBaseUrl/api/Account/$accountId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (customerResponse.statusCode != 200) {
        throw Exception('Failed to fetch customer information');
      }

      final customerData = json.decode(customerResponse.body)['data'];

      Map<String, dynamic> requestData = {
        'bookingRooms': _bookingRoomData
            .map((room) => {
                  'room': room['room'],
                  'pet': room['pet'],
                  'start': room['start'],
                  'end': room['end'],
                  'price': room['price'],
                  'camera': room['camera'],
                  'petName': _petNames[room['pet'].toString()] ?? 'Unknown Pet'
                })
            .toList(),
        'customer': {
          'cusId': accountId,
          'name': customerData['accountName'],
          'address': customerData['accountAddress'],
          'phone': customerData['accountPhoneNumber'],
          'note': '',
          'paymentMethod': _selectedPaymentType
        },
        'selectedOption': 'Room',
        'voucherId': _selectedVoucher ?? '00000000-0000-0000-0000-000000000000',
        'totalPrice': _totalPrice,
        'discountedPrice': _totalPrice
      };

      final response = await http.post(
        Uri.parse('$bookingBaseUrl/Bookings/room'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
      final result = json.decode(response.body);
      final bookingCode = result['data'].toString().trim();

      if (paymentTypeName == "VNPay") {
        await _processVNPayPayment(bookingCode, _totalPrice);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room booking created successfully')),
          );
          Navigator.pop(context);
        }
      }
    } else {
      throw Exception('Failed to create room booking: ${response.body}');
    }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating room booking: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendServiceBookingRequest() async {
    if (mounted) setState(() => _isProcessing = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? accountId = prefs.getString('accountId');

      String? paymentTypeName =
          await _getPaymentTypeName(_selectedPaymentType ?? '');

      final customerResponse = await http.get(
        Uri.parse('$apiBaseUrl/api/Account/$accountId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (customerResponse.statusCode != 200) {
        throw Exception('Failed to fetch customer information');
      }

      final customerData = json.decode(customerResponse.body)['data'];

      List<Map<String, dynamic>> services = _bookingServiceData.map((service) {
        return {
          "service": service["service"]["id"].toString(),
          "pet": service["pet"]["id"].toString(),
          "price": service["price"] ?? 0.0,
          "serviceVariant": service["serviceVariant"]["id"].toString(),
        };
      }).toList();

      Map<String, dynamic> requestData = {
        "services": services,
        "customer": {
          "cusId": accountId,
          "name": customerData['accountName'],
          "address": customerData['accountAddress'],
          "phone": customerData['accountPhoneNumber'],
          "note": '',
          "paymentMethod": _selectedPaymentType
        },
        "selectedOption": "Service",
        "voucherId": _selectedVoucher ?? "00000000-0000-0000-0000-000000000000",
        "totalPrice": _totalPrice,
        "discountedPrice": _totalPrice,
        "bookingServicesDate": _bookingServiceData.isNotEmpty
            ? _bookingServiceData[0]["bookingDate"].toString().substring(0, 16)
            : DateTime.now().toIso8601String().substring(0, 16)
      };

      final response = await http.post(
        Uri.parse('$bookingBaseUrl/Bookings/service'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
      final result = json.decode(response.body);
      final bookingCode = result['data'].toString().trim();

      if (paymentTypeName == "VNPay") {
        await _processVNPayPayment(bookingCode, _totalPrice);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service booking created successfully')),
          );
          Navigator.pop(context);
        }
      }
    } else {
      throw Exception('Failed to create service booking: ${response.body}');
    }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating service booking: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  StepState _getStepState(int step) {
  if (_currentStep > step) {
    return StepState.complete;
  } else if (_currentStep == step) {
    return StepState.editing;
  } else if (step == _currentStep + 1) {
    return StepState.indexed; // Next step
  }
  return StepState.disabled; // Future steps
}


  List<Step> _getSteps() {
    return [
      Step(
        title: Text("Type", style: TextStyle(fontSize: 10)),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Select the booking type you want to book.",
                style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildServiceOption("Room"),
                SizedBox(width: 16),
                _buildServiceOption("Service"),
              ],
            ),
          ],
        ),
        isActive: _currentStep >= 0,
        state: _getStepState(0),
      ),
      Step(
        title: Text("Details", style: TextStyle(fontSize: 10)),
        content: Column(
          children: [
            _serviceType == "Room"
                ? BookingRoomForm(
                    cusId: _cusId,
                    onBookingDataChange: _updateBookingRoomData,
                  )
                : _serviceType == "Service"
                    ? BookingServiceForm(
                        cusId: _cusId,
                        onBookingServiceDataChange: _updateBookingServiceData)
                    : Text("Please select a booking type."),
            SizedBox(height: 20)
          ],
        ),
        isActive: _currentStep >= 1,
        state: _getStepState(1),
      ),
      Step(
        title: Text("Voucher", style: TextStyle(fontSize: 10)),
        content: Column(
          children: [
            // Voucher Search Section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Voucher by Code',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: _voucherSearchCode),
                    onChanged: (value) {
                      setState(() {
                        _voucherSearchCode = value;
                      });
                    },
                    enabled: !_searchLoading,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchLoading || _voucherSearchCode.trim().isEmpty
                      ? null
                      : _searchVoucher,
                  child: _searchLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text("Apply Voucher"),
                ),
              ],
            ),
            if (_searchError.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  _searchError,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(height: 16),
            _vouchers.isEmpty
                ? Text("No vouchers available")
                : DropdownButtonFormField<String>(
                    value: _selectedVoucher,
                    hint: Text("Select a Voucher (Optional)"),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text("No Voucher"),
                      ),
                      ..._vouchers.map((voucher) {
                        return DropdownMenuItem(
                          value: voucher['voucherId'].toString(),
                          child: Text(
                              "${voucher['voucherName']} - ${voucher['voucherDiscount']}% (Max ${voucher['voucherMaximum']} VND)"),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedVoucher = value;
                        _calculateTotalPrice();
                      });
                    },
                  ),
          ],
        ),
        isActive: _currentStep >= 2,
        state: _getStepState(2),
      ),
      Step(
         title: Text("Payment", style: TextStyle(fontSize: 10)),
        content: _paymentTypes.isEmpty
            ? CircularProgressIndicator()
            : Column(
                children: _paymentTypes.map((type) {
                  return RadioListTile(
                    title: Text(type['paymentTypeName']),
                    value: type['paymentTypeId'],
                    groupValue: _selectedPaymentType,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentType = value.toString();
                      });
                    },
                  );
                }).toList(),
              ),
        isActive: _currentStep >= 3,
      state: _getStepState(3),
      ),
      Step(
        title: Text("Summary", style: TextStyle(fontSize: 10)),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Service Type Header
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Service Type: $_serviceType",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            SizedBox(height: 16),

            Text(
              "Booking Details:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 8),

            if (_serviceType == "Room") ...[
              ..._bookingRoomData.map((room) => Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            icon: Icons.meeting_room,
                            label: "Room",
                            value: _roomNames[room["room"].toString()] ??
                                "Loading...",
                          ),
                          _buildDetailRow(
                            icon: Icons.pets,
                            label: "Pet",
                            value: _petNames[room["pet"].toString()] ??
                                "Loading...",
                          ),
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            label: "Start Date",
                            value: _formatDate(room["start"]),
                          ),
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            label: "End Date",
                            value: _formatDate(room["end"]),
                          ),
                          _buildDetailRow(
                            icon: Icons.attach_money,
                            label: "Room Price",
                            value: _currencyFormatter.format(room["price"]),
                            valueStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          _buildDetailRow(
                            icon: Icons.videocam,
                            label: "Camera",
                            value: room["camera"] ? "Yes (+50,000 ₫)" : "No",
                          ),
                          Divider(height: 20),
                        ],
                      ),
                    ),
                  )),
              _buildPriceRow(
                label: "Subtotal",
                value: _currencyFormatter.format(_calculateSubtotal()),
              ),
              if (_selectedVoucher != null) ...[
                SizedBox(height: 8),
                _buildDetailRow(
                  icon: Icons.local_offer,
                  label: "Voucher Applied",
                  value: _vouchers.firstWhere(
                      (v) => v['voucherId'] == _selectedVoucher,
                      orElse: () => {})['voucherName'],
                  valueStyle: TextStyle(color: Colors.blue.shade700),
                ),
                _buildPriceRow(
                  label: "Discount",
                  value: _currencyFormatter.format(_calculateDiscount()),
                  isDiscount: true,
                ),
              ],
              Divider(thickness: 2, height: 24),
              _buildPriceRow(
                label: "Final Total",
                value: _currencyFormatter.format(_totalPrice),
                isTotal: true,
              ),
            ] else ...[
              ..._bookingServiceData.map((service) => Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service["service"]?["name"] ?? "Unknown Service",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.category,
                            label: "Variant",
                            value: service["serviceVariant"]?["content"] ??
                                "No Variant",
                          ),
                          _buildDetailRow(
                            icon: Icons.attach_money,
                            label: "Price",
                            value:
                                _currencyFormatter.format(service["serviceVariant"]?["price"] ?? 0),
                            valueStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          _buildDetailRow(
                            icon: Icons.pets,
                            label: "Pet",
                            value: service["pet"]?["name"] ?? "Unknown Pet",
                          ),_buildDetailRow(
          icon: Icons.calendar_today,
          label: "Booking Date",
          value: _formatDate(service["bookingDate"] ?? ""),
          valueStyle: TextStyle(
            color: Colors.blue.shade700,
          ),
        ),
                          Divider(height: 20),
                        ],
                      ),
                    ),
                  )),
              _buildPriceRow(
                label: "Total Price",
                value: _currencyFormatter.format(_totalPrice),
              ),
            ],
            SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.local_offer,
              label: "Voucher Applied",
              value: _vouchers.firstWhere(
                      (v) => v['voucherId'] == _selectedVoucher,
                      orElse: () => {})['voucherName'] ??
                  "No Voucher",
            ),
            _buildDetailRow(
              icon: Icons.payment,
              label: "Payment Type",
              value: _paymentTypes.firstWhere(
                      (p) => p['paymentTypeId'] == _selectedPaymentType,
                      orElse: () => {})['paymentTypeName'] ??
                  "Not Selected",
            ),
          ],
        ),
        isActive: _currentStep >= 4,
      state: _getStepState(4),
      ),
    ];
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          SizedBox(width: 8),
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? TextStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow({
  required String label,
  required String value,
  bool isDiscount = false,
  bool isTotal = false,
}) {
  return Container(
    padding: EdgeInsets.all(12),
    margin: EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: isTotal ? Colors.blue.shade50 : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDiscount ? Colors.red.shade700 : Colors.grey.shade800,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 16 : 14,
            color: isDiscount
                ? Colors.red.shade700
                : isTotal
                    ? Colors.blue.shade800
                    : Colors.green.shade700,
          ),
        ),
      ],
    ),
  );
}



  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildServiceOption(String option) {
    return GestureDetector(
      onTap: () {
        setState(() => _serviceType = option);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: _serviceType == option ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _serviceType == option ? Colors.green : Colors.grey,
            width: 2,
          ),
        ),
        child: Text(
          option,
          style: TextStyle(
            color: _serviceType == option ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _onStepContinue() {
  // Step 0 validation - must choose service type
  if (_currentStep == 0 && _serviceType.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please select a booking type'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    return;
  }

  // Step 1 validation - must have valid booking data
  if (_currentStep == 1) {
    if (_serviceType == "Room") {
      if (_bookingRoomData.isEmpty ||
          _bookingRoomData.any((room) =>
              room["room"] == null ||
              room["pet"] == null ||
              room["start"].isEmpty || // Validate start date
              room["end"].isEmpty || // Validate end date
              DateTime.parse(room["start"]).isAfter(DateTime.parse(room["end"])))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please complete all booking room information, including valid start and end dates'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
    } else if (_serviceType == "Service" && _bookingServiceData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one service booking'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
  }

  // Step 3 validation - must select payment type
  if (_currentStep == 3 && _selectedPaymentType == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please select a payment method'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    return;
  }

  if (_currentStep < _getSteps().length - 1) {
    // Add haptic feedback
    HapticFeedback.selectionClick();
    
    // Smooth transition to next step
    setState(() {
      _currentStep += 1;
    });
    
    // Scroll to top of the new step content
    Timer(Duration(milliseconds: 300), () {
      if (mounted) {
        Scrollable.ensureVisible(
          context,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  } else {
    if (_serviceType == "Room") {
      _sendRoomBookingRequest();
    } else if (_serviceType == "Service") {
      _sendServiceBookingRequest();
    }
  }
}

void _onStepCancel() {
  // Add haptic feedback
  HapticFeedback.selectionClick();
  
  if (_currentStep > 0) {
    setState(() => _currentStep -= 1);
  } else {
    Navigator.pop(context);
  }
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Add Booking"),
      backgroundColor: Colors.blue,
    ),
    body: SafeArea(
      child: Column(
        children: [
          // Progress indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _getSteps().length,
              backgroundColor: Colors.blue.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          // Custom step indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStepIndicator(0, "Type", Icons.category),
                _buildStepIndicator(1, "Details", Icons.description),
                _buildStepIndicator(2, "Voucher", Icons.card_giftcard),
                _buildStepIndicator(3, "Payment", Icons.payment),
                _buildStepIndicator(4, "Summary", Icons.summarize),
              ],
            ),
          ),
          
          // Stepper content area (without the stepper navigation)
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _getSteps()[_currentStep].content,
              ),
            ),
          ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _onStepCancel,
                    icon: Icon(Icons.arrow_back),
                    label: Text('Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      elevation: 2,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  )
                else
                  SizedBox.shrink(),
                
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _onStepContinue,
                  icon: _isProcessing 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(_currentStep == _getSteps().length - 1
                          ? Icons.check
                          : Icons.arrow_forward),
                  label: Text(_currentStep == _getSteps().length - 1
                      ? 'Submit'
                      : 'Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildStepIndicator(int step, String title, IconData icon) {
  bool isActive = _currentStep >= step;
  bool isCurrent = _currentStep == step;
  
  return GestureDetector(
    onTap: () {
      // Only allow going back to previous steps
      if (_currentStep > step) {
        setState(() {
          _currentStep = step;
        });
      }
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCurrent 
                ? Colors.blue 
                : isActive 
                    ? Colors.blue.shade100 
                    : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent 
                  ? Colors.blue.shade700 
                  : isActive 
                      ? Colors.blue.shade300 
                      : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: isCurrent 
                  ? Colors.white 
                  : isActive 
                      ? Colors.blue.shade700 
                      : Colors.grey.shade600,
              size: 20,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent 
                ? Colors.blue.shade700 
                : isActive 
                    ? Colors.blue.shade900 
                    : Colors.grey.shade600,
          ),
        ),
      ],
    ),
  );
}


  double _calculateSubtotal() {
    if (_serviceType == "Room") {
      return _bookingRoomData.fold(0.0, (sum, room) {
        double price = double.tryParse(room["price"].toString()) ?? 0.0;
        return sum + price;
      });
    }
    return 0.0;
  }

  double _calculateDiscount() {
    if (_selectedVoucher == null) return 0.0;

    var voucher = _vouchers.firstWhere(
        (v) => v['voucherId'] == _selectedVoucher,
        orElse: () => {});

    if (voucher.isEmpty) return 0.0;

    double subtotal = _calculateSubtotal();
    double discount =
        double.tryParse(voucher['voucherDiscount'].toString()) ?? 0.0;
    double maxDiscount =
        double.tryParse(voucher['voucherMaximum'].toString()) ?? 0.0;

    return (subtotal * discount / 100).clamp(0, maxDiscount);
  }
}

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = 
          (X509Certificate cert, String host, int port) => true;
  }
}