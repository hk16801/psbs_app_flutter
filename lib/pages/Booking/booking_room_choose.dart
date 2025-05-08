import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BookingRoomChoose extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final Function(Map<String, dynamic>) onBookingDataChange;
  final Map<String, dynamic> data;

  const BookingRoomChoose({
    Key? key,
    required this.bookingData,
    required this.onBookingDataChange,
    required this.data,
  }) : super(key: key);

  @override
  _BookingRoomChooseState createState() => _BookingRoomChooseState();
}

class _BookingRoomChooseState extends State<BookingRoomChoose> {
  List<Map<String, dynamic>> rooms = [];
  List<Map<String, dynamic>> pets = [];
  bool isLoading = true;
  String? error;
  Map<String, dynamic>? selectedRoomType;
  Map<String, dynamic> formData = {
    "room": "",
    "pet": "",
    "start": "",
    "end": "",
    "price": "0",
    "camera": false,
  };

  @override
  void initState() {
    super.initState();
    formData = {...widget.bookingData};
    fetchRoomsAndPets();
  }

  Future<void> fetchRoomsAndPets() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? accountId = prefs.getString('accountId');

      // Fetch rooms
      final roomResponse = await http.get(
        Uri.parse("http://10.0.2.2:5050/api/Room/available"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (roomResponse.statusCode == 200) {
        final roomData = jsonDecode(roomResponse.body);
        if (roomData["flag"]) {
          setState(() {
            rooms = List<Map<String, dynamic>>.from(roomData["data"]);
          });

          // If room is already selected, fetch its type
          if (formData["room"].isNotEmpty) {
            await _fetchRoomTypeForSelectedRoom();
          }
        }
      }

      // Fetch pets if customer ID exists
      if (widget.data["cusId"] != null) {
        final petResponse = await http.get(
          Uri.parse(
              "http://10.0.2.2:5050/api/pet/available/${widget.data["cusId"]}"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        if (petResponse.statusCode == 200) {
          final petData = jsonDecode(petResponse.body);
          if (petData["flag"]) {
            setState(() {
              pets = List<Map<String, dynamic>>.from(petData["data"]);
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => error = "Error loading data. Please try again.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchRoomTypeForSelectedRoom() async {
    try {
      final selectedRoom = rooms.firstWhere(
        (room) => room["roomId"] == formData["room"],
        orElse: () => {},
      );

      if (selectedRoom.isNotEmpty && selectedRoom["roomTypeId"] != null) {
        await fetchRoomType(selectedRoom["roomTypeId"]);
      }
    } catch (e) {
      print('Error finding selected room: $e');
    }
  }

  Future<void> fetchRoomType(String roomTypeId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("http://10.0.2.2:5050/api/RoomType/$roomTypeId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["flag"] && data["data"] != null) {
          setState(() {
            selectedRoomType = data["data"];
          });

          // Recalculate price if dates are already set
          if (formData["start"].isNotEmpty && formData["end"].isNotEmpty) {
            calculatePrice();
          }
        }
      }
    } catch (e) {
      print('Error fetching room type: $e');
      setState(() => error = "Error loading room details");
    }
  }

  Future<void> pickDateTime(String field) async {
    if (formData["room"].isEmpty) {
      setState(() => error = "Please select a room first");
      return;
    }

    final initialDate = field == "start"
        ? DateTime.now()
        : (formData["start"].isNotEmpty
            ? DateTime.parse(formData["start"])
            : DateTime.now());

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate:
          field == "start" ? DateTime.now() : DateTime.parse(formData["start"]),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          formData[field] = fullDateTime.toIso8601String();
        });

        if (formData["start"].isNotEmpty && formData["end"].isNotEmpty) {
          calculatePrice();
        }
      }
    }
  }

  void calculatePrice() {
    if (selectedRoomType == null ||
        formData["start"].isEmpty ||
        formData["end"].isEmpty) {
      return;
    }

    try {
      final startDate = DateTime.parse(formData["start"]);
      final endDate = DateTime.parse(formData["end"]);

      if (!startDate.isBefore(endDate)) {
        setState(() => error = "End date must be after start date");
        return;
      }

      // Truncate time part
      final startDay = DateTime(startDate.year, startDate.month, startDate.day);
      final endDay = DateTime(endDate.year, endDate.month, endDate.day);

      final daysDifference = endDay.difference(startDay).inDays + 1;

      final roomPrice =
          double.tryParse(selectedRoomType!["price"].toString()) ?? 0.0;
      var totalPrice = roomPrice * daysDifference;

      if (formData["camera"] == true) {
        totalPrice += 50000;
      }

      setState(() {
        formData["price"] = totalPrice.toString();
        error = null;
      });

      widget.onBookingDataChange({
        ...formData,
        "price": totalPrice,
      });
    } catch (e) {
      print('Error calculating price: $e');
      setState(() => error = "Error calculating price");
    }
  }

  void handleChange(String field, dynamic value) {
    setState(() {
      formData[field] = value;
      error = null;
    });

    if (field == "room") {
      if (value != null) {
        final selectedRoom = rooms.firstWhere(
          (room) => room["roomId"] == value,
          orElse: () => {},
        );

        if (selectedRoom.isNotEmpty) {
          fetchRoomType(selectedRoom["roomTypeId"]);
        }
      }
    } else if (field == "camera") {
      if (selectedRoomType != null) {
        calculatePrice();
      }
    }

    widget.onBookingDataChange(formData);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Booking Details",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 20),

          // Room Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Room",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonFormField(
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Choose a room",
                    ),
                    value:
                        formData["room"].isNotEmpty ? formData["room"] : null,
                    onChanged: (value) => handleChange("room", value),
                    items: rooms.map((room) {
                      return DropdownMenuItem(
                        value: room["roomId"],
                        child: Text(
                          "${room["roomName"]} - ${room["description"]}",
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    validator: (value) =>
                        value == null ? 'Please select a room' : null,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Pet Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Pet",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonFormField(
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Choose your pet",
                    ),
                    value: formData["pet"].isNotEmpty ? formData["pet"] : null,
                    onChanged: (value) => handleChange("pet", value),
                    items: pets.map((pet) {
                      return DropdownMenuItem(
                        value: pet["petId"],
                        child: Text(
                          pet["petName"],
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    validator: (value) =>
                        value == null ? 'Please select a pet' : null,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Date/Time Pickers
          Row(
            children: [
              Expanded(
                child: _buildDateTimePicker(
                  "Start Date & Time",
                  formData["start"],
                  () => pickDateTime("start"),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDateTimePicker(
                  "End Date & Time",
                  formData["end"],
                  () => pickDateTime("end"),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Camera Option
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: CheckboxListTile(
              title: Text(
                "Add Camera Monitoring",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                "+50,000 ₫",
                style: TextStyle(color: Colors.green.shade700),
              ),
              value: formData["camera"] ?? false,
              onChanged: (bool? value) {
                handleChange("camera", value ?? false);
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),

          if (error != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade700, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 20),

          // Price Display
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  "Total Price",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "${formData["price"]} ₫",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value.isNotEmpty
                        ? "${DateFormat('MMM dd, yyyy').format(DateTime.parse(value))} at ${DateFormat('hh:mm a').format(DateTime.parse(value))}"
                        : "Select",
                    style: TextStyle(
                      color: value.isNotEmpty
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
