import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Custom HttpOverrides to bypass SSL certificate verification in development
class DevHttpOverrides extends HttpOverrides {
  @override
   HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class VNPayWebView extends StatefulWidget {
  final String url;

  const VNPayWebView({Key? key, required this.url}) : super(key: key);

  @override
  _VNPayWebViewState createState() => _VNPayWebViewState();
}

class _VNPayWebViewState extends State<VNPayWebView> {
  late WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';
  static const String bookingBaseUrl = 'http://10.0.2.2:5050';

  @override
  void initState() {
    super.initState();
    
    // Apply certificate bypass for development
    HttpOverrides.global = DevHttpOverrides();
    
    _initializeWebView();
  }
  
  void _initializeWebView() {
  try {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _currentUrl = url;
              });
            }
            print('[DEBUG] WebView loading: $url');
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            print('[DEBUG] WebView finished loading: $url');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('[DEBUG] WebView navigation request: ${request.url}');
            
            // Check if this is the callback URL
            if (request.url.contains('/Vnpay/Callback') || 
                request.url.contains('vnp_ResponseCode=')) {
              _handlePaymentCallback(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('[ERROR] WebView error: ${error.description} (${error.errorCode})');
            print('[ERROR] WebView error type: ${error.errorType}');
            
            if (mounted && _isLoading) {
              setState(() {
                _isLoading = false;
              });
              
              // Show error message for critical errors
              if (error.errorCode == -1 || // Generic error
                  error.description.contains('ERR_CERT_')) { // Certificate errors
                _showErrorDialog('Connection Error', 
                  'Unable to connect to the payment gateway. This may be due to a certificate issue. Please try again later.');
              }
            }
          },
        ),
      );
    
    // Load the URL with error handling
    print('[DEBUG] Loading initial URL: ${widget.url}');
    _controller.loadRequest(Uri.parse(widget.url));
  } catch (e, stackTrace) {
    print('[ERROR] Failed to initialize WebView: $e');
    print('[STACK] $stackTrace');
    _showErrorDialog('Error', 'Failed to initialize payment page: $e');
  }
}


  void _handlePaymentCallback(String url) async {
    print('[DEBUG] Handling payment callback: $url');
    
    // Parse URL parameters
    final uri = Uri.parse(url);
    final queryParams = uri.queryParameters;
    
    // Check payment status from query parameters
    final responseCode = queryParams['vnp_ResponseCode'] ?? 
                         queryParams['status'] ?? 'failed';
    
    String message;
    bool success = false;
    
    // VNPay response code '00' means success
    if (responseCode == '00' || responseCode == 'success') {
      message = 'Payment successful! Your booking has been confirmed.';
      success = true;
      
      // Extract booking code from the URL or description
      String? bookingCode = await _extractBookingCode(url, queryParams);
      
      if (bookingCode != null) {
        // Call the API to update payment status
        await _updatePaymentStatus(bookingCode);
      } else {
        print('[ERROR] Could not extract booking code from callback URL');
      }
    } else {
      message = 'Payment failed or was cancelled. Please try again or choose another payment method.';
    }
    
    if (mounted) {
      await _showResultDialog(success, message);
    }
  }
  
  Future<String?> _extractBookingCode(String url, Map<String, String> queryParams) async {
    try {
      // Try to extract from vnp_OrderInfo parameter which contains the JSON description
      if (queryParams.containsKey('vnp_OrderInfo')) {
        final orderInfo = queryParams['vnp_OrderInfo']!;
        // The order info might be URL encoded and contain JSON
        if (orderInfo.contains('bookingCode')) {
          // Simple extraction - this assumes a specific format
          final startIndex = orderInfo.indexOf('bookingCode') + 13; // Length of 'bookingCode":"'
          final endIndex = orderInfo.indexOf('"', startIndex);
          if (startIndex > 13 && endIndex > startIndex) {
            return orderInfo.substring(startIndex, endIndex);
          }
        }
      }
      
      // If we can't extract it, check if we stored it when starting the payment
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('current_payment_booking_code');
    } catch (e) {
      print('[ERROR] Error extracting booking code: $e');
      return null;
    }
  }
  
  Future<void> _updatePaymentStatus(String bookingCode) async {
    try {
      print('[DEBUG] Updating payment status for booking: $bookingCode');
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        print('[ERROR] No authentication token found');
        return;
      }
      
      final response = await http.get(
        Uri.parse('$bookingBaseUrl/Bookings/Vnpay/Callback/update-status?bookingCode=$bookingCode'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      
      if (response.statusCode == 200) {
        print('[DEBUG] Payment status updated successfully');
      } else {
        print('[ERROR] Failed to update payment status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[ERROR] Exception updating payment status: $e');
    }
  }
  
  Future<void> _showResultDialog(bool success, String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(success ? 'Payment Successful' : 'Payment Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              
              // If successful, also pop the booking screen to go back to the list
              if (success) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }else {
              // Just go back to the previous screen (add booking page)
              Navigator.of(context).pop();
            }
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('VNPay Payment'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading payment page...'),
                  SizedBox(height: 8),
                  Text(
                    'Please wait, this may take a moment',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
