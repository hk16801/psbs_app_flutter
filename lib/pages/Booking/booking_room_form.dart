import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'booking_room_choose.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class BookingRoomForm extends StatefulWidget {
  final String? cusId;
  final Function(List<Map<String, dynamic>>)? onBookingDataChange;

  BookingRoomForm({
    required this.cusId,
    this.onBookingDataChange,
  });

  @override
  _BookingRoomFormState createState() => _BookingRoomFormState();
}

class _BookingRoomFormState extends State<BookingRoomForm> {
  List<Map<String, dynamic>> _bookingRooms = [];
  double _totalPrice = 0.0;
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _pets = [];
  List<String> _selectedRooms = [];
  List<String> _selectedPets = [];
  bool _selectAllRooms = false;
  bool _selectAllPets = false;
  String? _error;
  Map<String, String> _petNames = {};
  Map<String, double> _roomPrices = {};

  @override
  void initState() {
    super.initState();
    _fetchRooms();
    _fetchPets();
  }

  Future<void> _fetchRooms() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/Room/available'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['flag']) {
          setState(() {
            _rooms = List<Map<String, dynamic>>.from(data['data']);
          });
          // Fetch price for each room
          for (var room in _rooms) {
            await _fetchRoomPrice(room['roomTypeId']);
          }
        }
      }
    } catch (e) {
      print('Error fetching rooms: $e');
    }
  }

  Future<void> _fetchPets() async {
    if (widget.cusId == null) return;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/pet/available/${widget.cusId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['flag']) {
          setState(() {
            _pets = List<Map<String, dynamic>>.from(data['data']);
            // Initialize pet names
            for (var pet in _pets) {
              _petNames[pet['petId']] = pet['petName'];
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching pets: $e');
    }
  }

  Future<void> _fetchRoomPrice(String roomTypeId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/RoomType/$roomTypeId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['flag']) {
          setState(() {
            _roomPrices[roomTypeId] =
                double.parse(data['data']['price'].toString());
          });
        }
      }
    } catch (e) {
      print('Error fetching room price: $e');
    }
  }

  void _handleRoomSelect(String roomId) {
    setState(() {
      if (roomId == 'all') {
        _selectAllRooms = !_selectAllRooms;
        if (_selectAllRooms) {
          _selectedRooms = _rooms.map((r) => r['roomId'].toString()).toList();
        } else {
          _selectedRooms = [];
        }
      } else {
        _selectAllRooms = false;
        if (_selectedRooms.contains(roomId)) {
          _selectedRooms.remove(roomId);
        } else {
          _selectedRooms.add(roomId);
        }
      }
    });
  }

  void _handlePetSelect(String petId) {
    setState(() {
      if (petId == 'all') {
        _selectAllPets = !_selectAllPets;
        if (_selectAllPets) {
          _selectedPets = _pets.map((p) => p['petId'].toString()).toList();
        } else {
          _selectedPets = [];
        }
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

  bool _checkTimeOverlap(
      String start1, String end1, String start2, String end2) {
    if (start1.isEmpty || end1.isEmpty || start2.isEmpty || end2.isEmpty)
      return false;
    final s1 = DateTime.parse(start1);
    final e1 = DateTime.parse(end1);
    final s2 = DateTime.parse(start2);
    final e2 = DateTime.parse(end2);
    return (s1.isBefore(e2) && e1.isAfter(s2));
  }

  void _handleCreateBookingRooms() async {
    setState(() {
      _error = null;
      _bookingRooms = [];
    });

    // Small delay to ensure UI updates
    await Future.delayed(Duration(milliseconds: 10));

    // Check if number of rooms is sufficient
    final numRooms = _selectAllRooms ? _rooms.length : _selectedRooms.length;
    final numPets = _selectAllPets ? _pets.length : _selectedPets.length;

    if (numRooms < numPets) {
      setState(() {
        _error =
            "Number of rooms must be greater than or equal to the number of pets";
      });
      return;
    }

    final selectedRoomsList = _selectAllRooms
        ? _rooms
        : _rooms
            .where((r) => _selectedRooms.contains(r['roomId'].toString()))
            .toList();
    final selectedPetsList = _selectAllPets
        ? _pets
        : _pets
            .where((p) => _selectedPets.contains(p['petId'].toString()))
            .toList();

    final newBookingRooms = <Map<String, dynamic>>[];
    for (var i = 0;
        i < selectedPetsList.length && i < selectedRoomsList.length;
        i++) {
      newBookingRooms.add({
        "room": selectedRoomsList[i]['roomId'],
        "pet": selectedPetsList[i]['petId'],
        "start": "",
        "end": "",
        "price": 0,
        "camera": false
      });
    }

    // Check for time overlaps
    for (var i = 0; i < newBookingRooms.length; i++) {
      for (var j = i + 1; j < newBookingRooms.length; j++) {
        if (newBookingRooms[i]['room'] == newBookingRooms[j]['room']) {
          if (_checkTimeOverlap(
            newBookingRooms[i]['start'],
            newBookingRooms[i]['end'],
            newBookingRooms[j]['start'],
            newBookingRooms[j]['end'],
          )) {
            setState(() {
              _error = "Time slots cannot overlap for the same room";
            });
            return;
          }
        }
      }
    }

    setState(() {
      _bookingRooms = newBookingRooms;
      // Clear selections after creating
      _selectedRooms = [];
      _selectedPets = [];
      _selectAllRooms = false;
      _selectAllPets = false;
      _totalPrice = 0;
    });
    _notifyParent();
  }

  void _updateBookingData(int index, Map<String, dynamic> newData) {
    setState(() {
      if (newData["price"] is String) {
        newData["price"] = double.tryParse(newData["price"]) ?? 0.0;
      }
      _bookingRooms[index] = newData;
      _calculateTotalPrice();
    });
    _notifyParent();
  }

  void _calculateTotalPrice() {
    _totalPrice = _bookingRooms.fold(0.0, (sum, room) {
      // Handle both string and numeric price values
      double price;
      if (room["price"] is String) {
        price = double.tryParse(room["price"]) ?? 0.0;
      } else {
        price = room["price"] is num ? room["price"].toDouble() : 0.0;
      }
      return sum + price;
    });
  }

  void _notifyParent() {
    if (widget.onBookingDataChange != null) {
      widget.onBookingDataChange!(_bookingRooms);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return Column(
      children: [
        // Rooms Selection
        Card(
          margin: EdgeInsets.all(8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Rooms",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: Text("All Rooms"),
                  value: _selectAllRooms,
                  onChanged: (bool? value) => _handleRoomSelect('all'),
                ),
                if (!_selectAllRooms)
                  ..._rooms.map((room) => CheckboxListTile(
                        title: Text(
                            "${room['roomName']} - ${currencyFormat.format(_roomPrices[room['roomTypeId']] ?? 0)}"),
                        value:
                            _selectedRooms.contains(room['roomId'].toString()),
                        onChanged: (bool? value) =>
                            _handleRoomSelect(room['roomId'].toString()),
                      )),
              ],
            ),
          ),
        ),

        // Pets Selection
        Card(
          margin: EdgeInsets.all(8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Pets",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: Text("All Pets"),
                  value: _selectAllPets,
                  onChanged: (bool? value) => _handlePetSelect('all'),
                ),
                if (!_selectAllPets)
                  ..._pets.map((pet) => CheckboxListTile(
                        title: Text(pet['petName']),
                        value: _selectedPets.contains(pet['petId'].toString()),
                        onChanged: (bool? value) =>
                            _handlePetSelect(pet['petId'].toString()),
                      )),
              ],
            ),
          ),
        ),

        if (_error != null)
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red),
            ),
          ),

        ElevatedButton(
          onPressed: _handleCreateBookingRooms,
          child: Text("Create Booking Rooms"),
        ),

        // Display Booking Rooms
        ..._bookingRooms.asMap().entries.map((entry) {
          int index = entry.key;
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                ListTile(
                  title: Text("Room Booking #${index + 1}"),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _bookingRooms.removeAt(index);
                        _calculateTotalPrice();
                      });
                      _notifyParent();
                    },
                  ),
                ),
                BookingRoomChoose(
                  bookingData: {
                    ..._bookingRooms[index],
                    'petName':
                        _petNames[_bookingRooms[index]['pet']] ?? 'Loading...',
                  },
                  onBookingDataChange: (data) =>
                      _updateBookingData(index, data),
                  data: {"cusId": widget.cusId},
                ),
              ],
            ),
          );
        }).toList(),

        SizedBox(height: 20),
        Text(
          "Total Price: ${currencyFormat.format(_totalPrice)}",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
