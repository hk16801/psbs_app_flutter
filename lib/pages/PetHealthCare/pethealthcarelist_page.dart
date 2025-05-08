import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pethealthcaredetail_page.dart';

class PetHealthBookList extends StatefulWidget {
  final String? petId;
  PetHealthBookList({this.petId});

  @override
  _PetHealthBookListState createState() => _PetHealthBookListState();
}

class _PetHealthBookListState extends State<PetHealthBookList> {
  List mergedPets = [];
  String searchQuery = "";
  String? accountId;

  @override
  void initState() {
    super.initState();
    loadAccountIdAndFetchData();
  }

  Future<void> loadAccountIdAndFetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedAccountId = prefs.getString('accountId');
    if (storedAccountId != null) {
      setState(() {
        accountId = storedAccountId;
      });
      await fetchData();
    } else {
      print("No accountId found in SharedPreferences");
    }
  }

  Future<Map<String, String>> getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  String getStatus(String nextVisitDate) {
    try {
      DateTime parsedDate = DateTime.parse(nextVisitDate);
      if (parsedDate.isBefore(DateTime.now()) ||
          parsedDate.isAtSameMomentAs(DateTime.now())) {
        return "Done";
      } else {
        return "Pending";
      }
    } catch (e) {
      return "Unknown";
    }
  }

  Future<void> fetchData() async {
    if (accountId == null) return;
    try {
      final headers = await getHeaders();

      final petHealthRes = await http.get(
        Uri.parse("http://10.0.2.2:5050/api/PetHealthBook"),
        headers: headers,
      );
      final medicinesRes = await http.get(
        Uri.parse("http://10.0.2.2:5050/Medicines"),
        headers: headers,
      );
      final petsRes = await http.get(
        Uri.parse("http://10.0.2.2:5050/api/pet"),
        headers: headers,
      );
      final bookingServiceItemsRes = await http.get(
        Uri.parse(
            "http://10.0.2.2:5050/api/BookingServiceItems/GetBookingServiceList"),
        headers: headers,
      );

      if (petHealthRes.statusCode != 200 ||
          medicinesRes.statusCode != 200 ||
          petsRes.statusCode != 200 ||
          bookingServiceItemsRes.statusCode != 200) {
        print("Failed to fetch data");
        return;
      }

      var petHealthData = jsonDecode(petHealthRes.body);
      if (petHealthData is Map) {
        petHealthData = petHealthData['data'] ?? [];
      }
      var medicinesData = jsonDecode(medicinesRes.body);
      if (medicinesData is Map) {
        medicinesData = medicinesData['data'] ?? [];
      }
      var petsData = jsonDecode(petsRes.body);
      if (petsData is Map) {
        petsData = petsData['data'] ?? [];
      }
      var bookingServiceItemsData = jsonDecode(bookingServiceItemsRes.body);
      if (bookingServiceItemsData is Map) {
        bookingServiceItemsData = bookingServiceItemsData['data'] ?? [];
      }

      List accountPets =
          (petsData as List).where((p) => p['accountId'] == accountId).toList();

      List result = accountPets.map((pet) {
        List healthForThisPet = (petHealthData as List).where((health) {
          var bsi = bookingServiceItemsData.firstWhere(
            (item) =>
                item['bookingServiceItemId'] == health['bookingServiceItemId'],
            orElse: () => null,
          );
          if (bsi == null) return false;
          return bsi['petId'] == pet['petId'];
        }).toList();

        List healthRecords = healthForThisPet.map((health) {
          List medIds = health['medicineIds'] ?? [];
          List medNames = (medicinesData as List)
              .where((m) => medIds.contains(m['medicineId']))
              .map((m) => m['medicineName'])
              .toList();

          String medicineNames = medNames.isNotEmpty
              ? medNames.join(", ")
              : "No Medicines Assigned";

          return {
            'healthBookId': health['healthBookId'] ?? "",
            'medicineNames': medicineNames,
            'performBy': health['performBy'] ?? "Unknown",
            'nextVisitDate': health['nextVisitDate'] ?? "",
          };
        }).toList();

        return {
          'petId': pet['petId'],
          'petName': pet['petName'] ?? "Unknown",
          'dateOfBirth': pet['dateOfBirth'] ?? "",
          'petGender': pet['petGender'] ?? true,
          'petImage': pet['petImage'] ?? "",
          'healthBooks': healthRecords,
        };
      }).toList();

      setState(() {
        mergedPets = result;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  String formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return date;
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

  @override
  Widget build(BuildContext context) {
    List filteredPets = widget.petId != null && widget.petId!.isNotEmpty
        ? mergedPets
            .where((record) =>
                record['petId'].toString() == widget.petId.toString())
            .toList()
        : mergedPets.where((record) {
            String petName = record['petName'].toString().toLowerCase();
            String healthInfo = "";
            if (record['healthBooks'] is List) {
              healthInfo = (record['healthBooks'] as List)
                  .map((h) => "${h['medicineNames']} ${h['performBy']}")
                  .join(" ")
                  .toLowerCase();
            }
            return petName.contains(searchQuery) ||
                healthInfo.contains(searchQuery);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.blue,
            flexibleSpace: FlexibleSpaceBar(
              title: widget.petId == null || widget.petId!.isEmpty
                  ? Text("Pet Health Book List")
                  : null,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.petId != null &&
                      widget.petId!.isNotEmpty &&
                      filteredPets.isNotEmpty)
                    Image.network(
                      "http://10.0.2.2:5050/pet-service${filteredPets.first['petImage']}",
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: Colors.grey),
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
          ),
          if (widget.petId == null || widget.petId!.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Search Pets...",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                var petRecord = filteredPets[index];
                return Card(
                  color: Colors.white,
                  elevation: 3,
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Center(
                                    child: Text(
                                      petRecord['petName'],
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildInfoChip(
                                        petRecord['petGender']
                                            ? 'Male'
                                            : 'Female',
                                        petRecord['petGender']
                                            ? Icons.male
                                            : Icons.female,
                                        petRecord['petGender']
                                            ? Colors.blue
                                            : Colors.pink,
                                      ),
                                      SizedBox(
                                          width:
                                              8), // Khoảng cách nhỏ giữa 2 chip
                                      _buildInfoChip(
                                        formatDate(petRecord['dateOfBirth']),
                                        Icons.cake,
                                        Colors.blue,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        petRecord['healthBooks'].isEmpty
                            ? Text("No Health Book Records")
                            : Column(
                                children: List.generate(
                                  petRecord['healthBooks'].length,
                                  (i) {
                                    var health = petRecord['healthBooks'][i];
                                    return ListTile(
                                      title: Text(
                                        "Medicine: ${health['medicineNames']}",
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              "Performed By: ${health['performBy']}"),
                                          Text(
                                              "Next Visit Date: ${formatDate(health['nextVisitDate'])}"),
                                          Text(
                                            "Status: ${getStatus(health['nextVisitDate'])}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: getStatus(health[
                                                          'nextVisitDate']) ==
                                                      'Done'
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.info,
                                            color: Colors.grey),
                                        onPressed: () {
                                          if (health['healthBookId'] == null ||
                                              health['healthBookId'].isEmpty) {
                                            print(
                                                "Error: healthBookId is null or empty");
                                            return;
                                          }
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PetHealthBookDetail(
                                                healthBookId:
                                                    health['healthBookId'],
                                                pet: petRecord,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ],
                    ),
                  ),
                );
              },
              childCount: filteredPets.length,
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildPetImage(String? imagePath) {
  if (imagePath != null && imagePath.isNotEmpty) {
    String imageUrl = "http://10.0.2.2:5050$imagePath";
    return Image.network(
      imageUrl,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.error, size: 50, color: Colors.red);
      },
    );
  } else {
    return Icon(Icons.pets, size: 50);
  }
}
