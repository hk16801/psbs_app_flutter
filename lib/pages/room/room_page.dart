import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:psbs_app_flutter/pages/room/room_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});

  @override
  _RoomPageState createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  List<dynamic> rooms = [];
  List<dynamic> roomTypes = [];
  List<dynamic> filteredRooms = [];
  bool isLoading = true;
  bool isGridView = true;
  TextEditingController searchController = TextEditingController();
  String? selectedRoomType;
  String? selectedPriceRange;

  final currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 3,
  );

  String formatCurrency(num value) {
    if (value == value.toInt()) {
      return NumberFormat.currency(
              locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
          .format(value);
    }
    return currencyFormatter.format(value);
  }

  @override
  void initState() {
    super.initState();
    fetchRooms();
    searchController.addListener(_filterRooms);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Fetch rooms and room types data
  Future<void> fetchRooms() async {
    setState(() {
      isLoading = true;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      if (token == null || token.isEmpty) {
        throw Exception("Token does not exist. Please log in again.");
      }
      // Fetch both rooms and room types in parallel
      final responses = await Future.wait([
        http.get(
          Uri.parse('http://10.0.2.2:5050/api/Room/available'),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
        http.get(
          Uri.parse('http://10.0.2.2:5050/api/RoomType/available'),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      ]);

      final responseRooms = responses[0];
      final responseTypes = responses[1];

      if (responseRooms.statusCode == 200 && responseTypes.statusCode == 200) {
        final dataRooms = json.decode(responseRooms.body);
        final dataTypes = json.decode(responseTypes.body);
        final availableRooms = (dataRooms['data'] as List?)
                ?.where((room) => room['isDeleted'] != true)
                .toList() ??
            [];

        setState(() {
          rooms = availableRooms;
          filteredRooms = availableRooms;
          roomTypes = dataTypes['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          rooms = [];
          filteredRooms = [];
          isLoading = false;
        });
        if (responseRooms.statusCode == 404) {
          print("No available rooms.");
        } else {
          throw Exception('Failed to load rooms.');
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        rooms = [];
        filteredRooms = [];
      });
      print('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load rooms: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Filter rooms based on search term and filters
  void _filterRooms() {
    if (rooms.isEmpty) return;
    setState(() {
      filteredRooms = rooms.where((room) {
        final matchesSearchTerm = room['roomName']
            .toString()
            .toLowerCase()
            .contains(searchController.text.toLowerCase());
        final matchesRoomType =
            selectedRoomType == null || selectedRoomType!.isEmpty
                ? true
                : room['roomTypeId'].toString() == selectedRoomType;
        bool matchesPrice = true;
        if (selectedPriceRange != null && selectedPriceRange!.isNotEmpty) {
          final roomType = roomTypes.firstWhere(
            (type) =>
                type['roomTypeId'].toString() == room['roomTypeId'].toString(),
            orElse: () => {'price': 0},
          );
          final price = roomType['price'] ?? 0;
          switch (selectedPriceRange) {
            case 'Low':
              matchesPrice = price < 100000;
              break;
            case 'Medium':
              matchesPrice = price >= 100000 && price <= 200000;
              break;
            case 'High':
              matchesPrice = price > 200000;
              break;
          }
        }
        return matchesSearchTerm && matchesRoomType && matchesPrice;
      }).toList();
    });
  }

  // Function to get room type name by ID
  String getRoomTypeName(String roomTypeId) {
    final roomType = roomTypes.firstWhere(
      (type) => type['roomTypeId'].toString() == roomTypeId.toString(),
      orElse: () => {'name': 'Unknown'},
    );
    return roomType['name'] ?? 'Unknown';
  }

  // Function to get room type price by ID
  String getRoomTypePrice(String roomTypeId) {
    final roomType = roomTypes.firstWhere(
      (type) => type['roomTypeId'].toString() == roomTypeId.toString(),
      orElse: () => {'price': 0},
    );

    final price = (roomType['price'] ?? 0) as num; 
    return formatCurrency(price);
  }

  // Clear all filters
  void _clearFilters() {
    setState(() {
      searchController.text = '';
      selectedRoomType = null;
      selectedPriceRange = null;
      filteredRooms = rooms;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.grey.shade50,
              Colors.yellow.shade50,
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: Colors.blue.shade600,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Luxury Pet Rooms',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
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
              actions: [
                IconButton(
                  icon: Icon(
                    isGridView ? Icons.view_list : Icons.grid_view,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      isGridView = !isGridView;
                    });
                  },
                ),
              ],
            ),

            // Search and Filter Section (only show when not loading)
            if (!isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by room name...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Filter Section
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedRoomType,
                                  hint: Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('Room Type'),
                                  ),
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down),
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  borderRadius: BorderRadius.circular(12),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: '',
                                      child: Text('All Room Types'),
                                    ),
                                    ...roomTypes
                                        .map<DropdownMenuItem<String>>((type) {
                                      return DropdownMenuItem<String>(
                                        value: type['roomTypeId'].toString(),
                                        child: Text(type['name']),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedRoomType = value;
                                      _filterRooms();
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedPriceRange,
                                  hint: Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('Price Range'),
                                  ),
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down),
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  borderRadius: BorderRadius.circular(12),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: '',
                                      child: Text('All Prices'),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'Low',
                                      child: Text('Under 100.000₫'),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'Medium',
                                      child: Text('100.000₫ - 200.000₫'),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'High',
                                      child: Text('Over 200.000₫'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedPriceRange = value;
                                      _filterRooms();
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Clear Filters Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _clearFilters,
                          icon: Icon(Icons.clear_all, size: 18),
                          label: Text('Clear Filters'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Results Count
                      Text(
                        '${filteredRooms.length} ${filteredRooms.length == 1 ? 'room' : 'rooms'} found',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Room List/Grid or Loading/Empty State
            isLoading
                ? SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  )
                : filteredRooms.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : isGridView
                        ? _buildGridView()
                        : _buildListView(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Colors.blue.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No Rooms Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search criteria',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Grid View Implementation
  Widget _buildGridView() {
    return SliverPadding(
      padding: EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 0.95,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final room = filteredRooms[index];
            return _buildRoomCard(context, room);
          },
          childCount: filteredRooms.length,
        ),
      ),
    );
  }

  // List View Implementation
  Widget _buildListView() {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final room = filteredRooms[index];
            return _buildRoomListItem(context, room);
          },
          childCount: filteredRooms.length,
        ),
      ),
    );
  }

  // Room Card (Grid View)
  Widget _buildRoomCard(BuildContext context, Map<String, dynamic> room) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Status Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  'http://10.0.2.2:5050/facility-service${room['roomImage']}',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(room['status']).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        room['status'],
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Room Information
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room['roomName'],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            getRoomTypeName(room['roomTypeId']),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        getRoomTypePrice(room['roomTypeId']),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 25),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerRoomDetail(
                            roomId: room['roomId'],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // List Item Card
  Widget _buildRoomListItem(BuildContext context, Map<String, dynamic> room) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerRoomDetail(
              roomId: room['roomId'],
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Room Image
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Image.network(
                    'http://10.0.2.2:5050/facility-service${room['roomImage']}',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported,
                            color: Colors.grey[400]),
                      );
                    },
                  ),
                ),

                // Room Info
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room['roomName'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          getRoomTypeName(room['roomTypeId']),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                getRoomTypePrice(room['roomTypeId']),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Status Badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor(room['status']),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(room['status']).withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      room['status'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to get color based on room status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Free':
        return Colors.green;
      case 'In Use':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}
