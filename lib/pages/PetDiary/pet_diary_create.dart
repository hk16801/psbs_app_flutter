import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:http/http.dart' as http;
import 'package:psbs_app_flutter/pages/PetDiary/pet_diary_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class PetDiaryCreatePage extends StatefulWidget {
  final String petId;

  const PetDiaryCreatePage({Key? key, required this.petId}) : super(key: key);

  @override
  _PetDiaryCreatePageState createState() => _PetDiaryCreatePageState();
}

class _PetDiaryCreatePageState extends State<PetDiaryCreatePage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _mediaFileList;
  List<String> categories = [];
  String? selectedCategory;
  bool isLoadingCategories = true;

  void _showCreateCategoryDialog() {
    TextEditingController newCategoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Create New Category"),
          content: TextField(
            controller: newCategoryController,
            decoration: InputDecoration(
              labelText: "Category Name",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String newCategory = newCategoryController.text.trim();
                if (newCategory.isNotEmpty &&
                    !categories.contains(newCategory)) {
                  setState(() {
                    categories.add(newCategory);
                    selectedCategory = newCategory;
                  });
                }

                Navigator.pop(context);
              },
              child: Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void _setImageFileListFromFile(XFile? value) {
    _mediaFileList = value == null ? null : <XFile>[value];
  }

  QuillController _controller = QuillController.basic();
  TextEditingController categoryTextController = TextEditingController();

  bool isLoading = false;

  Future<void> _saveDiaryEntry() async {
    print(_mediaFileList);

    if (_controller.document.isEmpty()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('The content cannot be empty!')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String deltaJson = jsonEncode(_controller.document.toDelta().toJson());

      String diaryContent = await convertDeltaToHtml(deltaJson);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5050/api/PetDiary'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          'pet_ID': widget.petId,
          'diary_Content': diaryContent,
          'category': categoryTextController.text.isNotEmpty
              ? categoryTextController.text
              : selectedCategory,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pet Diary Created Successfully!')),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to create pet diary: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving diary entry')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:5050/api/PetDiary/categories/${widget.petId}'),
        headers: {
          'Accept': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        print("response ne: " + response.body);
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        List<dynamic> data = jsonResponse["data"]["data"];

        setState(() {
          categories = data.map((item) => item.toString()).toList();
          selectedCategory = categories.isNotEmpty ? categories[0] : null;
          isLoadingCategories = false;
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  Future<void> _displayPickImageDialog(
      BuildContext context, bool isMulti, OnPickImageCallback onPick) async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add optional parameters'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                  child: const Text('PICK'),
                  onPressed: () {
                    onPick();
                    Navigator.of(context).pop();
                  }),
            ],
          );
        });
  }

  Future<void> _onImageButtonPressed(
    ImageSource source, {
    required BuildContext context,
    bool isMultiImage = false,
  }) async {
    if (!context.mounted) return;

    if (context.mounted) {
      await _displayPickImageDialog(context, true, () async {
        try {
          final List<XFile> pickedFileList = await _picker.pickMultiImage();

          setState(() {
            _mediaFileList = pickedFileList;
          });
        } catch (e) {
          print(e);
        }
      });
    }
  }

  // Hàm nén ảnh trước khi encode base64
  Future<String> compressAndEncodeBase64(List<int> imageBytes) async {
    img.Image image = img.decodeImage(Uint8List.fromList(imageBytes))!;

    // Resize ảnh nhỏ hơn (ví dụ: chiều rộng 800px)
    img.Image resizedImage = img.copyResize(image, width: 600);

    // Giảm chất lượng ảnh (ví dụ: 75%)
    List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 60);

    return base64Encode(compressedBytes);
  }

  Future<String> convertDeltaToHtml(String deltaJsonString) async {
    List<dynamic> deltaJson = jsonDecode(deltaJsonString);
    List<Map<String, dynamic>> deltaList =
        List<Map<String, dynamic>>.from(deltaJson);

    for (var op in deltaList) {
      if (op.containsKey("insert") && op["insert"] is Map<String, dynamic>) {
        var insert = op["insert"];
        if (insert.containsKey("image")) {
          String imagePath = insert["image"];

          // Chuyển ảnh sang base64 nếu là đường dẫn cục bộ
          if (imagePath.startsWith("/data/") ||
              imagePath.startsWith("file://")) {
            File imageFile = File(imagePath);
            if (await imageFile.exists()) {
              List<int> imageBytes = await imageFile.readAsBytes();

              // Nén ảnh trước khi encode base64
              String base64Image = await compressAndEncodeBase64(imageBytes);

              insert["image"] =
                  "data:image/jpeg;base64,$base64Image"; // Base64 format
            }
          }
        }
      }
    }

    final converter =
        QuillDeltaToHtmlConverter(deltaList, ConverterOptions.forEmail());

    String html = converter.convert();

    // Sua cho nay cach them khoang trang
    html = html.replaceAllMapped(
      RegExp(r'(<img)([^>]*)(>)'),
      (match) =>
          '${match.group(1)}${match.group(2)} style="display: block; margin-bottom: 10px;"${match.group(3)}',
    );

    return html;
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Create Pet Diary')),
        body: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(12.0),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select a topic:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      isLoadingCategories
                          ? CircularProgressIndicator()
                          : DropdownButton<String>(
                              value: (selectedCategory != null &&
                                      categories.contains(selectedCategory))
                                  ? selectedCategory
                                  : null,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedCategory = newValue!;
                                });
                              },
                              isExpanded: true, // Ensures full width
                              items: categories.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _showCreateCategoryDialog,
                        style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            textStyle: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        child: Text("Create new topic"),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  height: 400,
                  child: QuillEditor.basic(
                    controller: _controller,
                    config: QuillEditorConfig(
                        embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                        placeholder: "Start typing here..."),
                  ),
                ),
                QuillSimpleToolbar(
                  controller: _controller,
                  config: QuillSimpleToolbarConfig(
                    embedButtons: FlutterQuillEmbeds.toolbarButtons(
                        cameraButtonOptions: QuillToolbarCameraButtonOptions(
                            afterButtonPressed: () async {
                      await _onImageButtonPressed(ImageSource.gallery,
                          context: context);
                    })),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _saveDiaryEntry,
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.blue)
                        : Text('Save'),
                  ),
                )
              ],
            ),
          ),
        ));
  }

  @override
  void dispose() {
    _controller.dispose();
    categoryTextController.dispose();
    super.dispose();
  }
}

typedef OnPickImageCallback = void Function();
