import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:psbs_app_flutter/pages/Services/service_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  _ServicePageState createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  List<dynamic> services = [];
  List<dynamic> filteredServices = [];
  List<dynamic> serviceTypes = [];
  bool isLoading = true;
  bool isGridView = true;
  String searchQuery = '';
  String? selectedServiceTypeId;
  TextEditingController searchController = TextEditingController();

  Future<void> fetchServices() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final responseServices = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/Service?showAll=false'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (responseServices.statusCode == 200) {
        final dataServices = json.decode(responseServices.body);
        setState(() {
          services = dataServices['data'];
          filteredServices = services;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load services');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching data: $e');
    }
  }

  Future<void> fetchServiceTypes() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/Service/serviceTypes'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          serviceTypes = data['data'];
        });
      } else {
        throw Exception('Failed to load service types');
      }
    } catch (e) {
      print('Error fetching service types: $e');
    }
  }

  void filterServices() {
    setState(() {
      if (searchQuery.isEmpty && selectedServiceTypeId == null) {
        filteredServices = services;
      } else {
        filteredServices = services.where((service) {
          bool matchesSearch = searchQuery.isEmpty ||
              service['serviceName']
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase());

          bool matchesType = selectedServiceTypeId == null ||
              service['serviceTypeId'].toString() == selectedServiceTypeId;

          return matchesSearch && matchesType;
        }).toList();
      }
    });
  }

  void clearFilters() {
    setState(() {
      searchController.clear();
      searchQuery = '';
      selectedServiceTypeId = null;
      filteredServices = services;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchServices();
    fetchServiceTypes();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text;
        filterServices();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget buildServiceCard(Map<String, dynamic> service) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ServiceDetail(serviceId: service['serviceId'].toString()),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Service Image with Rounded Corners
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  child: service['serviceImage'] != null
                      ? Image.network(
                          'http://10.0.2.2:5023${service['serviceImage']}',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: Center(
                            child: Text('No Image',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ),
                ),
                // Gradient Overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['serviceName'] ?? 'No Name',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Type: ${service['serviceType']?['typeName'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      ),
                      icon: Icon(Icons.arrow_forward_ios, size: 18),
                      label: Text(
                        "See More",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServiceDetail(
                                serviceId: service['serviceId'].toString()),
                          ),
                        );
                      },
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

  Widget buildServiceListItem(Map<String, dynamic> service) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ServiceDetail(serviceId: service['serviceId'].toString()),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            children: [
              // Service Image with Rounded Corners and Gradient
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: service['serviceImage'] != null
                    ? Stack(
                        children: [
                          Image.network(
                            'http://10.0.2.2:5023${service['serviceImage']}',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.2),
                                  Colors.transparent
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Center(
                          child:
                              Text('No Image', style: TextStyle(fontSize: 12)),
                        ),
                      ),
              ),
              SizedBox(width: 12),
              // Service Name & Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['serviceName'] ?? 'No Name',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Type: ${service['serviceType']?['typeName'] ?? 'Unknown'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              // Animated "See More" Button
              IconButton(
                icon: Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetail(
                          serviceId: service['serviceId'].toString()),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearchAndFilterBar() {
    bool hasActiveFilters =
        searchQuery.isNotEmpty || selectedServiceTypeId != null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search Bar with Clear Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                searchQuery = '';
                                filterServices();
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Service Type Filter
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text('Filter by service type'),
                value: selectedServiceTypeId,
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Service Types'),
                  ),
                  ...serviceTypes.map<DropdownMenuItem<String>>((type) {
                    return DropdownMenuItem<String>(
                      value: type['serviceTypeId'].toString(),
                      child: Text(type['typeName']),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedServiceTypeId = value;
                    filterServices();
                  });
                },
              ),
            ),
          ),

          // Clear All Filters Button (only shown when filters are active)
          if (hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton.icon(
                onPressed: clearFilters,
                icon: Icon(Icons.filter_alt_off),
                label: Text('Clear All Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Services For Your Pets'),
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await fetchServices();
                filterServices();
              },
              child: ListView(
                children: [
                  buildSearchAndFilterBar(),
                  if (filteredServices.isEmpty)
                    Container(
                      height: 300,
                      alignment: Alignment.center,
                      child: Text(
                        'No services match your search criteria',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  else
                    ...filteredServices
                        .map((service) => isGridView
                            ? buildServiceCard(service)
                            : buildServiceListItem(service))
                        .toList(),
                ],
              ),
            ),
    );
  }
}
