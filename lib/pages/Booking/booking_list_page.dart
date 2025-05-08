import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/Booking.dart';
import '../../services/booking_service.dart';
import '../../services/booking_type_service.dart';
import 'booking_detail_page.dart';
import 'booking_hotel_detail_page.dart';
import 'booking_service_detail_page.dart';
import 'add_booking.dart';

class BookingListScreen extends StatefulWidget {
  @override
  _BookingListScreenState createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  late Future<List<Booking>> futureBookings;
  final BookingTypeService bookingTypeService = BookingTypeService();
  Map<String, String> bookingTypeNames = {};
  final ScrollController _scrollController = ScrollController();
  final RefreshIndicatorState _refreshIndicatorState = RefreshIndicatorState();

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      futureBookings = BookingService().fetchBookings().then((bookings) {
        // Sort bookings by date (newest first)
        bookings.sort((a, b) => DateTime.parse(b.bookingDate)
            .compareTo(DateTime.parse(a.bookingDate)));
        return bookings;
      });
    });
  }

  Future<void> _handleRefresh() async {
    await _loadBookings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  Future<void> getBookingTypeName(String bookingTypeId) async {
    if (!bookingTypeNames.containsKey(bookingTypeId)) {
      String? typeName = await bookingTypeService.fetchBookingType(bookingTypeId);
      if (typeName != null) {
        setState(() {
          bookingTypeNames[bookingTypeId] = typeName;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(Icons.add, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => AddBookingPage(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      );
                    },
                  ),
                ).then((_) {
                  _handleRefresh(); // Refresh after adding new booking
                });
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: FutureBuilder<List<Booking>>(
          future: futureBookings,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(strokeWidth: 3),
                    SizedBox(height: 16),
                    Text('Loading your bookings...', 
                      style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 48, color: Colors.blue),
                    SizedBox(height: 16),
                    Text('No bookings yet', 
                      style: TextStyle(fontSize: 18, color: Colors.grey[800])),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 48, color: Colors.blue),
                    SizedBox(height: 16),
                    Text('No bookings yet', 
                      style: TextStyle(fontSize: 18, color: Colors.grey[800])),
                    SizedBox(height: 8),
                    Text('Tap the + button to create a new booking', 
                      style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              );
            }

            List<Booking> bookings = snapshot.data!;

            return ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                Booking booking = bookings[index];

                if (!bookingTypeNames.containsKey(booking.bookingTypeId)) {
                  getBookingTypeName(booking.bookingTypeId);
                }

                return AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: _buildBookingCard(context, booking, index),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking, int index) {
    return Card(
      key: ValueKey(booking.bookingId), // Important for animations
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _navigateToDetail(context, booking);
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.bookingCode,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: booking.isPaid ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: booking.isPaid ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          booking.isPaid ? Icons.check_circle : Icons.pending,
                          size: 16,
                          color: booking.isPaid ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 4),
                        Text(
                          booking.isPaid ? 'Paid' : 'Unpaid',
                          style: TextStyle(
                            color: booking.isPaid ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    formatDate(booking.bookingDate),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Type: ${bookingTypeNames[booking.bookingTypeId] ?? 'Loading...'}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(booking.totalAmount ?? 0)}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Booking booking) {
    String? bookingTypeName = bookingTypeNames[booking.bookingTypeId];

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          if (bookingTypeName == "Hotel") {
            return CustomerRoomBookingDetail(bookingId: booking.bookingId);
          } else if (bookingTypeName == "Service") {
            return CustomerServiceBookingDetail(bookingId: booking.bookingId);
          } else {
            return BookingDetailScreen(booking: booking);
          }
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }
}