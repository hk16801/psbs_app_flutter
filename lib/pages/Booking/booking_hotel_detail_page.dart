import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:psbs_app_flutter/pages/Camera/CameraFeed/camera_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'vnpay_webview.dart';
import 'dart:io';

class CustomerRoomBookingDetail extends StatefulWidget {
  final String bookingId;

  const CustomerRoomBookingDetail({Key? key, required this.bookingId})
      : super(key: key);

  @override
  _CustomerRoomBookingDetailState createState() =>
      _CustomerRoomBookingDetailState();
}

class _CustomerRoomBookingDetailState extends State<CustomerRoomBookingDetail> {
  Map<String, dynamic>? booking;
  List<dynamic> roomHistory = [];
  String roomName = "Unknown";
  String paymentTypeName = "Unknown";
  String accountName = "Unknown";
  String bookingStatusName = "Unknown";
  bool isLoading = true;
  String? error;

  String? voucherName;
  String? voucherCode;
  double? voucherDiscount;
  double? voucherMaximum;
  bool isVoucherLoaded = false;

  @override
  void initState() {
    super.initState();
    fetchBookingDetails();
  }

  Future<void> fetchBookingDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Fetch booking details
      final bookingResponse = await http.get(
        Uri.parse("http://10.0.2.2:5050/Bookings/${widget.bookingId}"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      final bookingData = json.decode(bookingResponse.body)['data'];

      // Fetch payment type
      final paymentResponse = await http.get(
        Uri.parse(
            "http://10.0.2.2:5050/api/PaymentType/${bookingData['paymentTypeId']}"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      // Fetch account name
      final accountResponse = await http.get(
        Uri.parse(
            "http://10.0.2.2:5050/api/Account?AccountId=${bookingData['accountId']}"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      // Fetch booking status
      final statusResponse = await http.get(
        Uri.parse(
            "http://10.0.2.2:5050/api/BookingStatus/${bookingData['bookingStatusId']}"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      // Fetch room history
      final historyResponse = await http.get(
        Uri.parse("http://10.0.2.2:5050/api/RoomHistories/${widget.bookingId}"),

        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final historyData = json.decode(historyResponse.body)['data'] ?? [];

      setState(() {
        booking = bookingData;
        paymentTypeName = json.decode(paymentResponse.body)['data']
                ['paymentTypeName'] ??
            "Unknown";
        accountName =
            json.decode(accountResponse.body)['accountName'] ?? "Unknown";
        bookingStatusName = json.decode(statusResponse.body)['data']
                ['bookingStatusName'] ??
            "Unknown";
        roomHistory = historyData;
      });

      if (historyData.isNotEmpty) {
        await fetchRoomName(historyData[0]['roomId']);
        await fetchPetNames();
      }
    } catch (error) {
      setState(() {
        this.error = "Failed to load booking details. Please try again.";
      });
      print("Error fetching booking details: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchPetNames() async {
    List<dynamic> updatedRoomHistory = List.from(roomHistory);

    for (var history in updatedRoomHistory) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        final petResponse = await http.get(
          Uri.parse("http://10.0.2.2:5050/api/pet/${history['petId']}"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );
        final petData = json.decode(petResponse.body)['data'];
        history['petName'] = petData['petName'] ?? "Unknown Pet";
      } catch (error) {
        history['petName'] = "Unknown Pet";
      }
    }

    setState(() {
      roomHistory = updatedRoomHistory;
    });
  }

  Future<void> fetchRoomName(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final roomResponse = await http.get(
        Uri.parse("http://10.0.2.2:5050/api/Room/$roomId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      setState(() {
        roomName =
            json.decode(roomResponse.body)['data']['roomName'] ?? "Unknown";
      });
    } catch (error) {
      print("Error fetching room name: $error");
    }
  }

  Future<void> cancelBooking() async {
  bool confirm = await showCancelConfirmationDialog();
  if (!confirm) return;

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.put(
      Uri.parse("http://10.0.2.2:5050/Bookings/cancel/${widget.bookingId}"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
    final responseData = json.decode(response.body);

    if (responseData['flag']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseData['message'] ?? "Booking has been cancelled."),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(20),
          backgroundColor: Colors.green,
        ),
      );

      // Add a delay before updating the UI
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        bookingStatusName = "Cancelled";
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseData['message'] ?? "The booking can't be cancelled."),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(20),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to cancel booking. Please try again."),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(20),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Future<bool> showCancelConfirmationDialog() async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(20),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hotel, color: Colors.orange, size: 60),
                    SizedBox(height: 16),
                    Text(
                      "Cancel Room Booking?",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "This will cancel all associated room reservations. Are you sure?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            backgroundColor: Colors.grey[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "No",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            "Yes, Cancel",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  String formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return "Invalid date";
    }
  }

  Future<void> fetchVoucherDetails(String voucherId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print("Error: User is not logged in.");
        return;
      }

      final response = await http.get(
        Uri.parse("http://10.0.2.2:5050/api/Voucher/$voucherId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final responseData = json.decode(response.body);
      if (responseData['flag'] && responseData['data'] != null) {
        setState(() {
          voucherName = responseData['data']['voucherName'];
          voucherCode = responseData['data']['voucherCode'];
          voucherDiscount = responseData['data']['voucherDiscount'];
          voucherMaximum = responseData['data']['voucherMaximum'];
          isVoucherLoaded = true;
        });
      }
    } catch (error) {
      print("Error fetching voucher details: $error");
    }
  }

  Future<void> handleVNPayPayment() async {
    try {
      if (booking == null) return;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "User is not logged in. Please log in to proceed with payment."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Apply certificate bypass for development
      HttpOverrides.global = DevHttpOverrides();

      // Store the booking code for the current payment session
      await prefs.setString(
          'current_payment_booking_code', booking!['bookingCode']);

      // Create description with booking code and redirect path
      final description = jsonEncode({
        'bookingCode': booking!['bookingCode'].trim(),
        'redirectPath': '/customer/bookings'
      });



      // Use the secure get method
      final response = await _secureGet(
        'https://10.0.2.2:5201/api/VNPay/CreatePaymentUrl?'
        'moneyToPay=${booking!['totalAmount']}&'
        'description=${Uri.encodeComponent(description)}',
        {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print('[DEBUG] Response status code: ${response.statusCode}');
      print('[DEBUG] Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // The response body directly contains the VNPay URL as text
        final vnpayUrl = response.body.trim();
        print('[DEBUG] Received VNPay URL: $vnpayUrl');

        if (vnpayUrl.isEmpty || !vnpayUrl.startsWith('http')) {
          throw Exception('Invalid VNPay URL received: $vnpayUrl');
        }

        // Try to open the URL in WebView first (more reliable)
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

          // Refresh the booking details after payment
          fetchBookingDetails();
        }
      } else {
        throw Exception(
            'Failed to get VNPay URL: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('[ERROR] VNPay payment processing error: $e');
      print('[STACK] $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing payment: $e')),
        );
      }
    }
  }

// Add this helper method for secure HTTP requests
  Future<http.Response> _secureGet(
      String url, Map<String, String> headers) async {
    // Apply certificate bypass for development
    HttpOverrides.global = DevHttpOverrides();

    try {
      final client = http.Client();
      final response = await client
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(Duration(seconds: 30));

      return response;
    } catch (e) {
      print('[ERROR] HTTP request failed: $e');
      rethrow;
    }
  }

  Future<void> handleCameraSettings(Map<String, dynamic> roomHistory) async {
  // Check if there's a camera assigned to this room
  final cameraId = roomHistory['cameraId'];
  
  if (cameraId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("No camera is assigned to this room."),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // Show the camera modal
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return CameraModal(
        cameraId: cameraId,
        onClose: () => Navigator.of(context).pop(),
        open: true,
      );
    },
  );
}

  Widget _buildVoucherSection() {
    if (!isVoucherLoaded || voucherName == null) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Applied Voucher",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text("Voucher Name: $voucherName", style: TextStyle(fontSize: 14)),
          Text("Code: $voucherCode", style: TextStyle(fontSize: 14)),
          Text(
            "Discount: ${voucherDiscount?.toStringAsFixed(2)}% (Max ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(voucherMaximum)})",
            style: TextStyle(fontSize: 14, color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      if (booking?['isPaid'] == false && paymentTypeName == "VNPay" && bookingStatusName == "Pending" || bookingStatusName == "Confirmed")
        ElevatedButton(
          onPressed: handleVNPayPayment,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: Colors.blue.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.payment, size: 20),
              SizedBox(width: 8),
              Text(
                "Pay with VNPay",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      SizedBox(height: 16), // Add spacing between buttons
      if (bookingStatusName == "Pending" || bookingStatusName == "Confirmed")
      ElevatedButton(
        onPressed: cancelBooking,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          backgroundColor: Colors.red.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, size: 20),
            SizedBox(width: 8),
            Text(
              "Cancel Booking",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Room Booking Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.blue.shade100,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                      SizedBox(height: 16),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: fetchBookingDetails,
                        child: Text("Retry"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Booking Summary Card
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Booking Summary",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(bookingStatusName),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      bookingStatusName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                height: 24,
                                thickness: 1,
                                color: Colors.grey.shade200,
                              ),
                              _buildDetailRow(
                                Icons.confirmation_number,
                                "Booking Code:",
                                booking?['bookingCode'] ?? "N/A",
                              ),
                              _buildDetailRow(
                                Icons.person,
                                "Account Name:",
                                accountName,
                              ),
                              _buildDetailRow(
                                Icons.calendar_today,
                                "Booking Date:",
                                formatDate(booking?['bookingDate'] ??
                                    DateTime.now().toString()),
                              ),
                              _buildDetailRow(
                                Icons.payment,
                                "Payment Type:",
                                paymentTypeName,
                              ),
                              _buildDetailRow(
                                Icons.money,
                                "Total Amount:",
                                "${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(booking?['totalAmount'] ?? 0)}",
                              ),
                              _buildDetailRow(
                                Icons.note,
                                "Notes:",
                                booking?['notes']?.isNotEmpty == true
                                    ? booking!['notes']
                                    : "No notes",
                              ),
                              _buildDetailRow(
                                Icons.payment,
                                "Payment Status:",
                                booking?['isPaid'] == true ? "Paid" : "Unpaid",
                                isPaid: booking?['isPaid'],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Room Bookings Section
                      Text(
                        "Room Reservations",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 12),
                      roomHistory.isNotEmpty
                          ? ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: roomHistory.length,
                              itemBuilder: (context, index) {
                                final history = roomHistory[index];
                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  margin: EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child:
                                        _buildRoomDetailRowWithCamera(history),
                                  ),
                                );
                              },
                            )
                          : Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.grey),
                                  SizedBox(width: 10),
                                  Text(
                                    "No room reservations found for this booking.",
                                    style:
                                        TextStyle(color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),

                      // Voucher Section
                      _buildVoucherSection(),

                      // Action Buttons
                      _buildActionButtons(),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value,
      {bool? isPaid}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.blue.shade700,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isPaid != null
                        ? isPaid
                            ? Colors.green.shade700
                            : Colors.red.shade700
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade600,
          ),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDetailRowWithCamera(Map<String, dynamic> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.king_bed, color: Colors.blue.shade700, size: 24),
            SizedBox(width: 8),
            Text(
              roomName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _buildRoomDetailRow(
          Icons.pets,
          "Pet:",
          history['petName'] ?? "Unknown Pet",
        ),
        _buildRoomDetailRow(
          Icons.login,
          "Check-in:",
          formatDate(history['bookingStartDate']),
        ),
        _buildRoomDetailRow(
          Icons.logout,
          "Check-out:",
          formatDate(history['bookingEndDate']),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.circle,
                color: _getStatusColor(history['status']), size: 16),
            SizedBox(width: 8),
            Text(
              history['status'] ?? "Unknown",
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
              SizedBox(height: 8),
              if (bookingStatusName.toLowerCase() == "checked in" && 
          (history['status']?.toString().toLowerCase() == "checked in"))
          ElevatedButton(
          onPressed: () => handleCameraSettings(history),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: Colors.blue.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam, size: 20),
                SizedBox(width: 8),
                Text(
                  "View Camera Feed",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'checked in':
        return Colors.purple;
      case 'checked out':
        return Colors.teal;
      default:
        return Colors.grey;
    }
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