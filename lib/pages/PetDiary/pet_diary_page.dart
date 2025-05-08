import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:psbs_app_flutter/pages/PetDiary/pet_diary_create.dart';
import 'package:psbs_app_flutter/pages/PetDiary/pet_diary_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PetDiaryPage extends StatefulWidget {
  final String petId;
  final String petName;
  final String petImage;
  final String petDob;

  const PetDiaryPage({
    Key? key,
    required this.petId,
    this.petName = "Unknown Pet",
    this.petImage = "",
    this.petDob = "Unknown",
  }) : super(key: key);

  @override
  _PetDiaryPageState createState() => _PetDiaryPageState();
}

class _PetDiaryPageState extends State<PetDiaryPage> {
  List<dynamic> diaryEntries = [];
  int pageIndex = 1;
  int totalPages = 1;
  bool isLoading = false;
  List<String> categories = ["All"];
  String selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchPetDiary(widget.petId, pageIndex);
  }

  Future<void> fetchCategories() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:5050/api/PetDiary/categories/${widget.petId}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> categoryList = data['data']['data'];

        setState(() {
          categories = ["All", ...categoryList.cast<String>()];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories')),
      );
    }
  }

  Future<void> refreshData() async {
    await fetchCategories();
    await fetchPetDiary(widget.petId, pageIndex);
  }

  Future<void> fetchPetDiary(String petId, int page) async {
    setState(() => isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2:5050/api/PetDiary/diaries/$petId?category=${selectedCategory == "All" ? "" : selectedCategory}&pageIndex=$page&pageSize=4',
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final entries = data['data']?['data'];
        print('co toi day ne');
        print(widget.petImage);

        setState(() {
          diaryEntries = entries ?? [];
          totalPages = data['data']?['meta']?['totalPages'] ?? 1;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _onEditPressed(Map<String, dynamic> diary) async {
    print("Diary being edited: $diary");
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PetDiaryUpdatePage(diary: diary, petId: widget.petId),
      ),
    );

    if (result == true) {
      await refreshData();
    }
  }

  Future<void> _confirmDelete(String diaryId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete this diary entry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:5050/api/PetDiary/$diaryId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          diaryEntries.removeWhere((entry) => entry['diary_ID'] == diaryId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Diary entry deleted successfully")),
        );

        await refreshData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete diary entry")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting diary entry")),
      );
    }
  }

  void _nextPage() {
    if (pageIndex < totalPages) {
      setState(() => pageIndex++);
      fetchPetDiary(widget.petId, pageIndex);
    }
  }

  void _previousPage() {
    if (pageIndex > 1) {
      setState(() => pageIndex--);
      fetchPetDiary(widget.petId, pageIndex);
    }
  }

  String _formatPetDob(String petDob) {
    try {
      if (petDob.isEmpty || petDob == "Unknown") return "Unknown Date";

      DateTime parsedDate = DateTime.parse(petDob);
      return DateFormat('MM/dd/yyyy').format(parsedDate);
    } catch (e) {
      return "Invalid Date";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: widget.petImage.isNotEmpty
                          ? NetworkImage(
                              'http://10.0.2.2:5050/pet-service${widget.petImage}')
                          : AssetImage('assets/sampleUploadImage.jpg')
                              as ImageProvider,
                    ),
                    SizedBox(height: 10),
                    Text(
                      widget.petName,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      'Date of Birth: ${_formatPetDob(widget.petDob)}',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "View by topic: ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedCategory = newValue!;
                      });
                      fetchPetDiary(widget.petId, 1);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Danh sách nhật ký
          isLoading
              ? SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : diaryEntries.isEmpty
                  ? SliverFillRemaining(
                      child: Center(child: Text('No diary entries found')),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = diaryEntries[index];
                          String diaryContent =
                              entry['diary_Content'] ?? "No Content";
                          String diaryDate = "Unknown Date";
                          if (entry['diary_Date'] != null) {
                            DateTime parsedDate =
                                DateTime.parse(entry['diary_Date']);
                            diaryDate = DateFormat('HH:mm MM/dd/yyyy')
                                .format(parsedDate); // Định dạng tháng/ngày/năm
                          }
                          bool isExpanded = false;

                          return StatefulBuilder(
                            builder: (context, setState) {
                              return Card(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            diaryDate,
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit,
                                                color: Colors.blue),
                                            onPressed: () =>
                                                _onEditPressed(entry),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => _confirmDelete(
                                                entry['diary_ID']),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          entry['category'] ?? 'No Category',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        constraints: BoxConstraints(
                                          maxHeight: isExpanded
                                              ? MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.6
                                              : 150,
                                        ), // Giới hạn chiều cao khi thu gọn
                                        child: SingleChildScrollView(
                                          physics: isExpanded
                                              ? null
                                              : NeverScrollableScrollPhysics(),
                                          child: Html(
                                            data: diaryContent,
                                            style: {
                                              "p": Style(fontSize: FontSize(16))
                                            },
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            setState(() {
                                              isExpanded = !isExpanded;
                                            });
                                          },
                                          child: Text(isExpanded
                                              ? "Show less"
                                              : "Show more"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: diaryEntries.length,
                      ),
                    ),

          // Pagination Buttons
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: pageIndex > 1 ? _previousPage : null,
                  icon: Icon(Icons.arrow_back),
                ),
                Text('Page $pageIndex of $totalPages'),
                IconButton(
                  onPressed: pageIndex < totalPages ? _nextPage : null,
                  icon: Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetDiaryCreatePage(petId: widget.petId),
            ),
          );

          if (result == true) {
            await refreshData();
          }
        },
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
