import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as dom;
import 'package:image/image.dart' as img;

class PetDiaryUpdatePage extends StatefulWidget {
  final Map<String, dynamic> diary;
  final String petId;

  const PetDiaryUpdatePage({Key? key, required this.diary, required this.petId})
      : super(key: key);

  @override
  _PetDiaryUpdatePageState createState() => _PetDiaryUpdatePageState();
}

class _PetDiaryUpdatePageState extends State<PetDiaryUpdatePage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _mediaFileList;
  quill.QuillController _controller = quill.QuillController.basic();
  bool isLoading = false;
  bool isFetching = true;
  FocusNode _editorFocusNode = FocusNode();
  List<String> categories = [];
  String selectedCategory = "";

  TextEditingController _categoryController = TextEditingController();

  Widget _buildCategoryInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: _showCreateCategoryDialog,
          style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          child: Text("Create new topic"),
        ),
        SizedBox(height: 10),
      ],
    );
  }

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

  Future<void> _addNewCategory() async {
    if (_categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Category cannot be empty!")),
      );
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
  Uri.parse('http://10.0.2.2:5050/api/PetDiary/categories'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "petId": widget.petId,
          "category": _categoryController.text,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          categories.add(_categoryController.text);
          selectedCategory = _categoryController.text;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Category added successfully!")),
        );
        _categoryController.clear();
      } else {
        throw Exception('Failed to add category');
      }
    } catch (error) {
      print('Error adding category: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    print("Received diary: ${widget.diary}");
    fetchCategories();
    _loadDiaryEntryFromData();

    _controller.document.changes.listen((event) {
      if (mounted) {
        // Không gọi setState() trừ khi thực sự cần thiết
        setState(() {}); // Chỉ cập nhật phần văn bản, không re-render ảnh
        _editorFocusNode.requestFocus();
      }
    });
  }

  Future<void> fetchCategories() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      print("token ne: " + token);

      print("petid nè: " + widget.petId);
      final response = await http.get(
        Uri.parse(
     'http://10.0.2.2:5050/api/PetDiary/categories/${widget.petId}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          categories = List<String>.from(jsonResponse['data']['data']);
          print("categories nè: " + categories.toString());
          selectedCategory = widget.diary["category"] ??
              (categories.isNotEmpty ? categories.first : "");
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (error) {
      print('Error fetching categories: $error');
    }
  }

  void _loadDiaryEntryFromData() async {
    String htmlContent = widget.diary['diary_Content'] ?? '';

    final cursorPosition = _controller.selection;

    // Chuyển đổi HTML -> Delta JSON
    List<dynamic> deltaJson = await convertHtmlToDelta(htmlContent);
    setState(() {
      _controller.document = quill.Document.fromJson(deltaJson);
      _controller.updateSelection(cursorPosition, quill.ChangeSource.local);
      isFetching = false;
    });
  }

  Future<List<dynamic>> convertHtmlToDelta(String html) async {
    dom.Document document = htmlParser.parse(html);
    List<dynamic> deltaOps = [];

    for (var element in document.body!.nodes) {
      if (element is dom.Element) {
        if (element.localName == "p") {
          for (var child in element.nodes) {
            if (child is dom.Text) {
              String text = child.text.trim();
              if (text.isNotEmpty) {
                deltaOps.add({"insert": "$text\n"});
              }
            } else if (child is dom.Element) {
              deltaOps.addAll(_parseElement(child));
            }
          }
        } else {
          deltaOps.addAll(_parseElement(element));
        }
      } else if (element is dom.Text) {
        deltaOps.add({"insert": element.text});
      }
    }

    return deltaOps;
  }

// Hàm xử lý từng thẻ HTML để bảo toàn format
  List<Map<String, dynamic>> _parseElement(dom.Element element) {
    List<Map<String, dynamic>> ops = [];
    String text = element.text.trim();

    if (text.isNotEmpty) {
      Map<String, dynamic> attributes = {};

      // Kiểm tra kiểu định dạng
      if (element.localName == "b" || element.localName == "strong") {
        attributes["bold"] = true;
      }
      if (element.localName == "i" || element.localName == "em") {
        attributes["italic"] = true;
      }
      if (element.localName == "u") {
        attributes["underline"] = true;
      }
      if (element.localName == "s" || element.localName == "del") {
        attributes["strike"] = true;
      }
      if (element.localName == "sup") {
        attributes["script"] = "super";
      }
      if (element.localName == "sub") {
        attributes["script"] = "sub";
      }

      // Kiểm tra heading
      if (element.localName == "h1") {
        attributes["header"] = 1;
      } else if (element.localName == "h2") {
        attributes["header"] = 2;
      } else if (element.localName == "h3") {
        attributes["header"] = 3;
      }

      // Kiểm tra blockquote
      if (element.localName == "blockquote") {
        attributes["blockquote"] = true;
      }

      // Kiểm tra code block
      if (element.localName == "code") {
        attributes["code"] = true;
      }

      // Kiểm tra danh sách (ul/ol)
      if (element.localName == "li") {
        dom.Element? parent = element.parent;
        if (parent != null) {
          if (parent.localName == "ul") {
            attributes["list"] = "bullet";
          } else if (parent.localName == "ol") {
            attributes["list"] = "ordered";
          }
        }
      }

      // Kiểm tra link
      if (element.localName == "a") {
        String? href = element.attributes['href'];
        if (href != null && href.isNotEmpty) {
          attributes["link"] = href;
        }
      }

      // Kiểm tra căn chỉnh (text-align)
      String? style = element.attributes['style'];
      if (style != null) {
        if (style.contains("text-align: center")) {
          attributes["align"] = "center";
        } else if (style.contains("text-align: right")) {
          attributes["align"] = "right";
        }
      }

      // Nếu có định dạng, thêm vào Delta JSON
      if (attributes.isNotEmpty) {
        ops.add({"insert": text, "attributes": attributes});
      } else {
        ops.add({"insert": text});
      }
    }

    // Xử lý hình ảnh
    if (element.localName == "img") {
      String? imageUrl = element.attributes['src'];
      if (imageUrl != null && imageUrl.startsWith("data:image")) {
        ops.add({
          "insert": {"image": imageUrl}
        });
        ops.add({"insert": "\n"});
      }
    }

    return ops;
  }

  Future<String> compressAndEncodeBase64(List<int> imageBytes) async {
    img.Image image = img.decodeImage(Uint8List.fromList(imageBytes))!;

    img.Image resizedImage = img.copyResize(image, width: 600);

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

          // 🔹 Nếu là ảnh cục bộ thì chuyển sang base64
          if (imagePath.startsWith("/data/") ||
              imagePath.startsWith("file://")) {
            File imageFile = File(imagePath);
            if (await imageFile.exists()) {
              List<int> imageBytes = await imageFile.readAsBytes();

              // 🔹 Nén ảnh trước khi encode base64
              String base64Image = await compressAndEncodeBase64(imageBytes);

              insert["image"] = "data:image/jpeg;base64,$base64Image";
            }
          }
        }
      }
    }

    // 🔹 Chuyển đổi Delta sang HTML
    final converter = QuillDeltaToHtmlConverter(
      deltaList,
      ConverterOptions.forEmail(),
    );

    String html = converter.convert();

// sua nhe
    html = html.replaceAllMapped(
      RegExp(r'(<img)([^>]*)(>)'),
      (match) =>
          '${match.group(1)}${match.group(2)} style="display: block; margin-bottom: 10px;"${match.group(3)}',
    );

    return html;
  }

  /// 🔹 **Hàm cập nhật nhật ký thú cưng**
  Future<void> _updateDiaryEntry() async {
    if (_controller.document.isEmpty()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The content cannot be empty!')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String deltaJson = jsonEncode(_controller.document.toDelta().toJson());
      String diaryContent = await convertDeltaToHtml(deltaJson);

      print("Updated diary content: $diaryContent");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.put(
        Uri.parse(
  'http://10.0.2.2:5050/api/PetDiary/${widget.diary['diary_ID']}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          'diary_Content': diaryContent,
          'category': selectedCategory,
        }),
      );

      print("response ne: ${response.statusCode}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet Diary Updated Successfully!')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update pet diary: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating diary entry: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Update Pet Diary')),
        body: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(12.0),
            padding: const EdgeInsets.all(16.0),
            child: isFetching
                ? const Center(child: CircularProgressIndicator())
                : Column(
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
                            DropdownButton<String>(
                              value: categories.contains(selectedCategory)
                                  ? selectedCategory
                                  : null,
                              onChanged: (newValue) {
                                setState(() {
                                  selectedCategory = newValue!;
                                });
                              },
                              isExpanded: true,
                              items: categories.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 10),
                            _buildCategoryInput(),
                          ],
                        ),
                      ), // Thêm mục nhập category mới
                      SizedBox(height: 10),

                      Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        height: 400,
                        child: quill.QuillEditor.basic(
                          controller: _controller,
                          config: quill.QuillEditorConfig(
                            embedBuilders: FlutterQuillEmbeds
                                .editorBuilders(), // Giữ nguyên ảnh
                          ),
                          focusNode: _editorFocusNode,
                        ),
                      ),
                      const SizedBox(height: 20),
                      quill.QuillSimpleToolbar(
                        controller: _controller,
                        config: quill.QuillSimpleToolbarConfig(
                          embedButtons: FlutterQuillEmbeds.toolbarButtons(
                            cameraButtonOptions:
                                QuillToolbarCameraButtonOptions(
                              afterButtonPressed: () async {
                                await _onImageButtonPressed(ImageSource.gallery,
                                    context: context);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _updateDiaryEntry,
                          style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              textStyle: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          child: isLoading
                              ? CircularProgressIndicator(color: Colors.blue)
                              : Text('Update'),
                        ),
                      )
                    ],
                  ),
          ),
        ));
  }

  @override
  void dispose() {
    _editorFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }
}

typedef OnPickImageCallback = void Function();
