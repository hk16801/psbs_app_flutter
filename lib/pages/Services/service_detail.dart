import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ServiceDetail extends StatefulWidget {
  final String serviceId;

  const ServiceDetail({super.key, required this.serviceId});

  @override
  _ServiceDetailState createState() => _ServiceDetailState();
}

class _ServiceDetailState extends State<ServiceDetail> {
  bool loading = true;
  Map<String, dynamic> detail = {};
  List<dynamic> dataVariant = [];
  bool showFullDescription = false;

  String get imageURL => 'http://10.0.2.2:5023${detail['serviceImage'] ?? ''}';

  @override
  void initState() {
    super.initState();
    fetchDetail();
    print("hinh ne" + imageURL);
    fetchVariantData();
  }

  Future<void> fetchDetail() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5050/api/Service/${widget.serviceId}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          detail = responseData['data'];
          loading = false;
        });
      } else {
        throw Exception('Failed to load service detail');
      }
    } catch (e) {
      print('Failed fetching detail: $e');
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> fetchVariantData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:5050/api/ServiceVariant/service/${widget.serviceId}?showAll=false'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          dataVariant = responseData['data'];
        });
      } else {
        throw Exception('Failed to load service variants');
      }
    } catch (e) {
      print('Error fetching variants: $e');
    }
  }

  Widget buildVariantItem(Map<String, dynamic> variant, int index) {
    return ListTile(
      leading: Text('${index + 1}.'),
      title: Text(variant['serviceContent'] ?? 'No content'),
      subtitle: Text('Price: ${variant['servicePrice']} VND',
          style: TextStyle(color: Colors.red)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service Details'),
        backgroundColor: Colors.blue,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 300,
                    child: detail['serviceImage'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imageURL,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            height: 300,
                            color: Colors.grey[300],
                            child: Center(child: Text('No Image')),
                          ),
                  ),
                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          detail['serviceName'] ?? '',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Type: ${detail['serviceType'] != null ? detail['serviceType']['typeName'] : ''}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey),
                      )
                    ],
                  ),
                  SizedBox(height: 20),
                  // Button "Book Now"
                  Center(
                    child: SizedBox(
                      width: 400,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/booking');
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.red[600]),
                        ),
                        child: Text(
                          'Book Now',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),
                  // Hiển thị danh sách Variant (nếu có)
                  Text(
                    'List of variants you can book: ',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  dataVariant.isEmpty
                      ? Center(child: Text('No variants available'))
                      : Container(
                          margin: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: dataVariant.length,
                            itemBuilder: (context, index) =>
                                buildVariantItem(dataVariant[index], index),
                          ),
                        ),
                  SizedBox(height: 20),
                  Text(
                    'Description',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    detail['serviceDescription'] ?? '',
                    maxLines: showFullDescription ? null : 7,
                    overflow: showFullDescription
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        showFullDescription = !showFullDescription;
                      });
                    },
                    child: Text(
                      showFullDescription ? 'Show Less' : 'Show More',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
