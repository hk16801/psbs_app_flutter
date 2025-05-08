import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pethealthcaredetail_page.dart';

class PetHealthBookDetail extends StatefulWidget {
  final String healthBookId;
  const PetHealthBookDetail({
    Key? key,
    required this.healthBookId,
    required pet,
  }) : super(key: key);

  @override
  _PetHealthBookDetailState createState() => _PetHealthBookDetailState();
}

class _PetHealthBookDetailState extends State<PetHealthBookDetail> {
  Map<String, dynamic>? petHealthBook;
  List<dynamic> medicines = [];
  List<dynamic> treatments = [];
  String petImage = '';
  String petName = '';
  String dateOfBirth = '';
  // Thêm biến petGender (true: Male, false: Female)
  bool petGender = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<Map<String, String>> getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> fetchData() async {
    try {
      final headers = await getHeaders();
      final healthBookRes = await http.get(
        Uri.parse(
            'http://10.0.2.2:5050/api/PetHealthBook/${widget.healthBookId}'),
        headers: headers,
      );
      final medicinesRes = await http.get(
        Uri.parse('http://10.0.2.2:5050/Medicines'),
        headers: headers,
      );
      final treatmentsRes = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/Treatment'),
        headers: headers,
      );
      final bookingsRes = await http.get(
        Uri.parse('http://10.0.2.2:5050/Bookings'),
        headers: headers,
      );
      final petsRes = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/pet'),
        headers: headers,
      );
      final bookingServiceItemsRes = await http.get(
        Uri.parse(
            'http://10.0.2.2:5050/api/BookingServiceItems/GetBookingServiceList'),
        headers: headers,
      );

      if (!healthBookRes.statusCode.toString().startsWith('2') ||
          !medicinesRes.statusCode.toString().startsWith('2') ||
          !treatmentsRes.statusCode.toString().startsWith('2') ||
          !bookingsRes.statusCode.toString().startsWith('2') ||
          !petsRes.statusCode.toString().startsWith('2') ||
          !bookingServiceItemsRes.statusCode.toString().startsWith('2')) {
        print("Error fetching data from API");
        return;
      }
      var healthBookData = jsonDecode(healthBookRes.body)['data'];
      if (healthBookData is List && healthBookData.isNotEmpty) {
        healthBookData = healthBookData.first;
      } else if (healthBookData is! Map) {
        healthBookData = {};
      }
      var medicinesData = jsonDecode(medicinesRes.body)['data'] ?? [];
      var treatmentsData = jsonDecode(treatmentsRes.body)['data'] ?? [];
      var bookingsData = jsonDecode(bookingsRes.body)['data'] ?? [];
      var petsData = jsonDecode(petsRes.body)['data'] ?? [];
      var bookingServiceItemsData =
          jsonDecode(bookingServiceItemsRes.body)['data'] ?? [];

      setState(() {
        petHealthBook = healthBookData;
        List<dynamic> medicineIds = petHealthBook?['medicineIds'] ?? [];
        medicines = medicinesData
            .where((m) => medicineIds.contains(m['medicineId']))
            .toList();
        List<dynamic> treatmentIds = medicines
            .map((medicine) => medicine['treatmentId'])
            .where((treatmentId) => treatmentId != null)
            .toList();
        treatments = treatmentsData
            .where(
                (treatment) => treatmentIds.contains(treatment['treatmentId']))
            .toList();

        if (healthBookData['bookingServiceItemId'] != null) {
          var bsi = bookingServiceItemsData.firstWhere(
            (item) =>
                item['bookingServiceItemId'] ==
                healthBookData['bookingServiceItemId'],
            orElse: () => null,
          );
          if (bsi != null && bsi['petId'] != null) {
            var pet = petsData.firstWhere(
              (p) => p['petId'] == bsi['petId'],
              orElse: () => null,
            );
            if (pet != null) {
              petImage = pet['petImage'] ?? '';
              petName = pet['petName'] ?? 'Unknown';
              dateOfBirth = pet['dateOfBirth'] ?? '';
              // Nếu pet có trường petGender, gán giá trị cho biến petGender
              petGender = pet['petGender'] ?? true;
            }
          }
        }
      });
    } catch (error) {
      print("Error fetching data: $error");
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "Unknown";
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return "Invalid Date";
    }
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRowText(String title, String value) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(width: 30),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (petHealthBook == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: DefaultTextStyle(
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          color: Colors.black,
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
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
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  petName,
                  style: TextStyle(fontSize: 16),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    petImage.isNotEmpty
                        ? Image.network(
                            'http://10.0.2.2:5050/pet-service$petImage',
                            fit: BoxFit.cover,
                          )
                        : Container(color: Colors.grey),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        petName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildInfoChip(
                          petGender ? 'Male' : 'Female',
                          petGender ? Icons.male : Icons.female,
                          petGender ? Colors.blue : Colors.pink,
                        ),
                        SizedBox(width: 8),
                        _buildInfoChip(
                          formatDate(dateOfBirth),
                          Icons.cake,
                          Colors.blue,
                        ),
                      ],
                    ),
                    Divider(),
                    _buildRowText(
                      'Treatment',
                      treatments.isNotEmpty
                          ? treatments.map((t) => t['treatmentName']).join(", ")
                          : 'No Treatments Found',
                    ),
                    Divider(),
                    _buildRowText(
                        'Performed By', petHealthBook!['performBy'] ?? ''),
                    Divider(),
                    _buildRowText(
                        'Visit Date', formatDate(petHealthBook!['visitDate'])),
                    Divider(),
                    _buildRowText('Next Visit Date',
                        formatDate(petHealthBook!['nextVisitDate'])),
                    Divider(),
                    _buildRowText(
                      'Medicine',
                      medicines.isNotEmpty
                          ? medicines.map((m) => m['medicineName']).join(", ")
                          : 'No Medicines Assigned',
                    ),
                    Divider(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
