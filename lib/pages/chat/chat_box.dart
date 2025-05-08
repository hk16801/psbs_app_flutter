import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:psbs_app_flutter/models/chat_message.dart';
import 'package:psbs_app_flutter/models/user.dart';
import 'package:psbs_app_flutter/services/signal_r_service.dart';
import 'package:psbs_app_flutter/utils/dialog_utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

class ChatBoxWidget extends StatefulWidget {
  final User currentUser;
  final User? chatUser;
  final String chatId;
  final bool isSupportChat;

  ChatBoxWidget({
    required this.currentUser,
    this.chatUser,
    required this.chatId,
    required this.isSupportChat,
  });

  @override
  _ChatBoxWidgetState createState() => _ChatBoxWidgetState();
}

class _ChatBoxWidgetState extends State<ChatBoxWidget> {
  List<ChatMessage> _chat = [];
  String _text = "";
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  File? _selectedImage;
  String _imageUrl = '';
  @override
  void initState() {
    super.initState();
    _startSignalR();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _startSignalR() async {
    signalRService.invoke("JoinChatRoom", [widget.chatId]);

    signalRService.on("UpdateChatMessages", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final messages = (arguments[0] as List)
            .map((item) => ChatMessage.fromJson(item))
            .toList();
        _updateChat(messages);
      }
    });

    signalRService.on("ReceiveMessage", (arguments) {
      if (arguments != null && arguments.length >= 3) {
        final senderId = arguments[0].toString();
        final messageText = arguments[1].toString();
        final updatedAt = arguments[2].toString();
        final image = arguments[3].toString();
        _receiveMessage(senderId, messageText, updatedAt, image);
      }
    });

    signalRService.on("removestafffailed", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        showErrorDialog(context, arguments[0].toString());
      }
    });

    signalRService.on("NewSupporterRequested", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        showSuccessDialog(context, arguments[0].toString());
        Navigator.pop(context);
      }
    });

    signalRService.on("RequestNewSupporterFailed", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        showErrorDialog(context, arguments[0].toString());
      }
    });

    signalRService.invoke(
        "GetChatMessages", [widget.chatId, widget.currentUser.accountId]);
  }

  Future<void> _updateChat(List<ChatMessage> messages) async {
    if (mounted) {
      setState(() {
        _chat = messages;
        print("Chat Messages:");
        _chat.forEach((message) {
          print(
              "  - Sender: ${message.senderId}, Text: ${message.text}, Image: ${message.image}, CreatedAt: ${message.createdAt}");
        });
      });
    }
    _scrollToBottom();
  }

  void _receiveMessage(String senderId, String messageText, String updatedAt,
      String messageImage) {
    if (mounted) {
      setState(() {
        _chat.add(ChatMessage(
            createdAt: updatedAt,
            senderId: senderId,
            text: messageText,
            image: messageImage));
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleSend() async {
    String trimmedText = _textController.text.trim();

    if (trimmedText.isNotEmpty || _selectedImage != null) {
      try {
        if (_selectedImage != null) {
          await _uploadImage(); // Upload image first
          if (_imageUrl.isNotEmpty) {
            // Send image URL with the message
            await signalRService.invoke("SendMessage", [
              widget.chatId,
              widget.currentUser.accountId,
              trimmedText,
              _imageUrl
            ]);
            _imageUrl = ''; // Reset the image URL after sending
          } else {
            showErrorDialog(context, "Failed to upload image.");
            return;
          }
        } else {
          await signalRService.invoke("SendMessage",
              [widget.chatId, widget.currentUser.accountId, trimmedText, ""]);
        }
        _textController.clear();
        _text = '';
        setState(() {
          _selectedImage = null; // Reset selected image after sending
        });
      } catch (e) {
        print("Error sending message: $e");
        showErrorDialog(context, "Failed to send message.");
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    try {
      // Get file extension
      final extension = path.extension(_selectedImage!.path).toLowerCase();

      // Map extension to content type
      final contentType = {
            '.jpg': 'image/jpeg',
            '.jpeg': 'image/jpeg',
            '.png': 'image/png',
            '.gif': 'image/gif',
          }[extension] ??
          'image/jpeg'; // Default to jpeg if unknown

      print("File path: ${_selectedImage!.path}");
      print("File extension: $extension");
      print("Content type being set: $contentType");

      // Create multipart request
      var request = http.MultipartRequest('POST',
          Uri.parse('http://10.0.2.2:5050/api/ChatControllers/upload-image'));

      // Create multipart file with explicit content type
      var multipartFile = await http.MultipartFile.fromPath(
          'image', _selectedImage!.path,
          filename: path.basename(_selectedImage!.path),
          contentType: MediaType.parse(contentType));

      request.files.add(multipartFile);

      // Print request details for debugging
      print(
          "Request files: ${request.files.map((f) => '${f.filename}: ${f.contentType}').join(', ')}");

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print("Response status code: ${response.statusCode}");
      print("Response body: $responseBody");

      var decodedResponse = json.decode(responseBody);

      if (decodedResponse['flag']) {
        setState(() {
          _imageUrl = decodedResponse['data'];
        });
        print("Image uploaded successfully: $_imageUrl");
      } else {
        throw Exception(decodedResponse['message']);
      }
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  void _handleKeyPress(String value) {
    String trimmedText = _text.trim(); // Trim leading/trailing whitespace
    if (trimmedText.isNotEmpty) {
      _handleSend();
    }
  }

  void _handleExitRoom() {
    if (widget.currentUser.roleId == "user") {
      showConfirmationDialog(context, "Request another supporter?",
          "Are you sure you want to request?", () {
        signalRService.invoke("RequestNewSupporter", [widget.chatId]);
      });
    } else {
      showConfirmationDialog(context, "Leave Support Conversation?",
          "Are you sure you want to leave this support chat?", () {
        signalRService.invoke("RemoveStaffFromChatRoom",
            [widget.chatId, widget.currentUser.accountId]);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  void dispose() {
    signalRService.invoke("LeaveChatRoom", [widget.chatId]);

    signalRService.off("UpdateChatMessages");
    signalRService.off("ReceiveMessage");
    signalRService.off("removestafffailed");
    signalRService.off("NewSupporterRequested");
    signalRService.off("RequestNewSupporterFailed");

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.chatUser?.accountImage != null
                  ? NetworkImage(
                      "http://10.0.2.2:5050/account-service/images/${widget.chatUser?.accountImage}")
                  : AssetImage("assets/default-avatar.png") as ImageProvider,
              radius: 25,
            ),
            SizedBox(width: 10),
            Text(
              widget.isSupportChat && widget.currentUser.roleId == "user"
                  ? "Support Agent"
                  : widget.chatUser?.accountName ?? "Unknown",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          if (widget.isSupportChat)
            IconButton(
              icon: Icon(Icons.exit_to_app, color: Colors.white),
              onPressed: _handleExitRoom,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Color.fromARGB(
                  255, 230, 244, 255), // Changed chat body background color
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _chat.length,
                itemBuilder: (context, index) {
                  final message = _chat[index];
                  final isOwnMessage = widget.currentUser.roleId == "user"
                      ? message.senderId == widget.currentUser.accountId
                      : (widget.isSupportChat &&
                              widget.currentUser.accountId !=
                                  widget.chatUser?.accountId &&
                              message.senderId != widget.chatUser?.accountId) ||
                          (!widget.isSupportChat &&
                              message.senderId == widget.currentUser.accountId);
                  // Log the message.image before rendering
                  print("Message Image: ${message.image}");
                  return Align(
                    alignment: isOwnMessage
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      decoration: BoxDecoration(
                        color: isOwnMessage
                            ? const Color.fromARGB(255, 193, 227, 255)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.grey[400]!,
                            width: 0.5), // Added thin border
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.image != null &&
                              message.image!.isNotEmpty &&
                              message.image != "null")
                            Image.network(
                              "http://10.0.2.2:5050${message.image!}",
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          if (message.text.isNotEmpty)
                            Text(
                              message.text,
                              style: TextStyle(fontSize: 16),
                            ),
                          Text(
                            DateFormat('yyyy-MM-dd HH:mm')
                                .format(DateTime.parse(message.createdAt)),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                if (_selectedImage ==
                    null) // Show icon only if no image is selected
                  IconButton(
                    icon: Icon(Icons.image, color: Colors.blue),
                    onPressed: _pickImage,
                  ),
                if (_selectedImage != null)
                  Chip(
                    avatar: CircleAvatar(
                      backgroundImage: FileImage(_selectedImage!),
                    ),
                    label: Text(''),
                    onDeleted: _removeImage,
                  ),
                SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10.0),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _text = value;
                        });
                      },
                      onSubmitted: _handleKeyPress,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Colors.blue,
                  ),
                  onPressed: _handleSend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
