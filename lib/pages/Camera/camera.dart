import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? streamUrl;
  bool loading = false;
  String? errorMessage;
  String? token; // Token lấy từ SharedPreferences

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? "";
    });
    print("Loaded token: $token");
  }

  Future<void> fetchCameraStream() async {
    final cameraCode = _controller.text.trim();
    if (cameraCode.isEmpty) {
      setState(() {
        errorMessage = "Please enter the camera code";
      });
      return;
    }
    if (token == null || token!.isEmpty) {
      setState(() {
        errorMessage = "Token not found, please log in again.";
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
      streamUrl = null;
    });

    try {
      final url =
          "http://10.0.2.2:5050/api/Camera/stream/$cameraCode?_=${DateTime.now().millisecondsSinceEpoch}";
      print("Fetching stream from URL: $url");
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode != 200) {
        String backendMessage = "Unknown error";
        try {
          final errorData = json.decode(response.body);
          backendMessage = errorData["message"] ?? backendMessage;
        } catch (e) {
          backendMessage = response.body;
        }
        print("Backend error: $backendMessage");

        if (backendMessage.toLowerCase().contains("camera not found")) {
          backendMessage = "Camera not found. Please check the camera code.";
        } else if (backendMessage.toLowerCase().contains("camera is deleted")) {
          backendMessage =
              "Camera is deleted. Please contact the administrator.";
        } else if (backendMessage
            .toLowerCase()
            .contains("camera is not active")) {
          backendMessage = "Camera is not active. Please try again later.";
        } else if (backendMessage
            .toLowerCase()
            .contains("camera address not found")) {
          backendMessage = "Camera address not found.";
        }
        throw Exception(backendMessage);
      }

      final data = json.decode(response.body);
      print("Parsed data: $data");
      if (data["streamUrl"] != null) {
        setState(() {
          streamUrl = data["streamUrl"];
        });
        print("Stream URL: $streamUrl");
        // Scroll lên đầu màn hình sau khi lấy được stream thành công
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      } else {
        throw Exception("Stream not found");
      }
    } catch (e) {
      print("Error fetching stream: $e");
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 4,
        title: const Text(
          "📹 CAMERA",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white, // Nền trắng cho vòng tròn
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.blueAccent, // Icon màu blue
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          constraints:
              BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xfff5f7fa), Color(0xffc3cfe2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Input Field Card with improved style
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Enter Camera Code",
                      labelStyle: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                      hintText: "",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon:
                          const Icon(Icons.videocam, color: Colors.blueAccent),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.blueAccent.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.blueAccent, width: 2),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: fetchCameraStream,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "View Stream",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Loading Indicator
              if (loading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
              ],
              // Error Message
              if (errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              // Video Player Container
              if (streamUrl != null && !loading)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: HLSPlayerWidget(streamUrl: streamUrl!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class HLSPlayerWidget extends StatefulWidget {
  final String streamUrl;
  const HLSPlayerWidget({Key? key, required this.streamUrl}) : super(key: key);

  @override
  _HLSPlayerWidgetState createState() => _HLSPlayerWidgetState();
}

class _HLSPlayerWidgetState extends State<HLSPlayerWidget> {
  late VideoPlayerController _videoController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Replace "localhost" with "10.0.2.2" if present.
    String url = widget.streamUrl;
    if (url.contains("localhost")) {
      url = url.replaceFirst("localhost", "10.0.2.2");
    }
    // Append timestamp to avoid caching.
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    url = url.contains('?') ? "$url&t=$timestamp" : "$url?t=$timestamp";
    print("Final video URL: $url");

    _videoController = VideoPlayerController.network(url)
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
        _videoController.play();
      }).catchError((error) {
        print("Error initializing video controller: $error");
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _initialized
          ? AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: VideoPlayer(_videoController),
            )
          : const CircularProgressIndicator(),
    );
  }
}
