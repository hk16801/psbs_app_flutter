import 'package:flutter/material.dart';
import 'package:psbs_app_flutter/models/chat_room.dart';
import 'package:psbs_app_flutter/models/user.dart';
import 'package:psbs_app_flutter/pages/chat/add_user_widget.dart';
import 'package:psbs_app_flutter/pages/chat/chat_box.dart';
import 'package:psbs_app_flutter/services/signal_r_service.dart';
import 'package:psbs_app_flutter/services/user_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psbs_app_flutter/utils/dialog_utils.dart';
import 'package:psbs_app_flutter/services/user_service.dart';

class ChatListWidget extends StatefulWidget {
  final User currentUser;

  ChatListWidget({required this.currentUser});

  @override
  _ChatListWidgetState createState() => _ChatListWidgetState();
}

class _ChatListWidgetState extends State<ChatListWidget> {
  bool _addMode = false;
  List<ChatRoom> _chats = [];
  String? _currentChatId;

  @override
  void initState() {
    super.initState();
    _startSignalR();
  }

  void _navigateToChat(BuildContext context, String chatId, User currentUser,
      User? chatUser, bool isSupportChat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatBoxWidget(
          currentUser: currentUser,
          chatUser: chatUser,
          chatId: chatId,
          isSupportChat: isSupportChat,
        ),
      ),
    );
  }

  Future<void> _startSignalR() async {
    final hubUrl = 'http://10.0.2.2:5050/chatHub';

    signalRService.setHubUrl(hubUrl);
    await signalRService.startConnection(hubUrl, widget.currentUser.accountId);

    signalRService.on('getList', (arguments) {
      print('SignalR: Received getList event');
      if (arguments != null && arguments.isNotEmpty) {
        final chatRooms = (arguments[0] as List)
            .map((item) => ChatRoom.fromJson(item))
            .toList();
        _updateChatList(chatRooms);
      }
    });

    signalRService.on('updateaftercreate', (arguments) {
      print('SignalR: Received updateaftercreate event');
      if (arguments != null && arguments.isNotEmpty) {
        final chatRooms = (arguments[0] as List)
            .map((item) => ChatRoom.fromJson(item))
            .toList();
        _updateChatList(chatRooms);
      }
    });

    signalRService.on('staffremoved', (arguments) {
      print('SignalR: Received staffremoved event');
      showSuccessDialog(context, "Leave room successfully");
    });
    signalRService.on('SupportChatRoomCreated', (arguments) {
      showSuccessDialog(context, "Support chat room created!");
    });
    signalRService.on('SupportChatRoomCreationFailed', (arguments) {
      showErrorDialog(context, arguments.toString());
    });

    try {
      await signalRService
          .invoke('ChatRoomList', [widget.currentUser.accountId]);
      print(
          'SignalR: ChatRoomList invoked with userId: ${widget.currentUser.accountId}');
    } catch (e) {
      print('SignalR Connection Failed: $e');
      print('SignalR Connection Failed: ${e.toString()}');
    }
  }

  Future<void> _updateChatList(List<ChatRoom> chatRooms) async {
    List<ChatRoom> updatedChats = [];

    for (var chatRoom in chatRooms) {
      User? userDetails = await UserService.fetchUser(chatRoom.serveFor);

      if (userDetails != null) {
        updatedChats.add(chatRoom.copyWith(user: userDetails));
        print("haha: " + userDetails.accountImage.toString());
      } else {
        updatedChats.add(chatRoom.copyWith(
            user: User(
                accountId: '',
                accountName: 'Unknown',
                avatar: 'assets/default-avatar.png',
                roleId: '')));
      }
    }

    if (mounted) {
      setState(() {
        _chats = updatedChats;
      });
    } else {
      print("ChatListWidget is not mounted, skipping setState.");
    }
  }

  @override
  void dispose() {
    signalRService.stopConnection();
    super.dispose();
  }

  void _initiateSupportChat() async {
    if (widget.currentUser.roleId == 'user') {
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Start Support Conversation?"),
            content: Text("Are you sure you want to initiate a support chat?"),
            actions: <Widget>[
              TextButton(
                child: Text("No, cancel"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text("Yes, start chat!"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        try {
          await signalRService
              .invoke("CreateSupportChatRoom", [widget.currentUser.accountId]);
        } catch (error) {
          print("Error invoking CreateSupportChatRoom: $error");
          showErrorDialog(context, "Failed to initiate chat room creation.");
        }
      }
    }
  }

  void _showAddUserWidget(BuildContext context) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        // Use Stack to layer widgets
        children: [
          ModalBarrier(
            // Add ModalBarrier for dimmed background
            color: Colors.black
                .withAlpha((255 * 0.5).toInt()), // Adjust opacity as needed
            dismissible: false, // Prevent dismissing by tapping outside
          ),
          Center(
            child: Material(
              child: AddUserWidget(
                signalRService: signalRService,
                currentUser: widget.currentUser,
                currentList: _chats,
                onClose: () {
                  overlayEntry?.remove();
                  setState(() {
                    _addMode = false;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(17, 25, 40, 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child:
                              Icon(Icons.search, color: Colors.white, size: 24),
                        ),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search',
                              hintStyle: TextStyle(color: Colors.white),
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _addMode = !_addMode;
                    });
                    if (_addMode) {
                      _showAddUserWidget(context); // Call the overlay function
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(17, 25, 40, 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_addMode ? Icons.remove : Icons.add,
                        color: Colors.white),
                  ),
                ),
                SizedBox(width: 20),
                GestureDetector(
                  onTap: _initiateSupportChat,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(17, 25, 40, 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_addMode ? Icons.remove : Icons.support_agent,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: useUserStore().currentUser == null
                ? Center(
                    child: CircularProgressIndicator()) // Show loading spinner
                : ListView.builder(
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chatRoom = _chats[index];
                      return GestureDetector(
                        onTap: () {
                          _navigateToChat(
                            context,
                            chatRoom.chatRoomId,
                            useUserStore().currentUser!,
                            chatRoom.user,
                            chatRoom.isSupportRoom,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Color(0xDDDDDD35))),
                            color: chatRoom.isSupportRoom
                                ? Color.fromRGBO(0, 123, 255, 0.1)
                                : null,
                          ),
                          child: Stack(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: chatRoom
                                                .user?.accountImage !=
                                            null
                                        ? NetworkImage(
                                            "http://10.0.2.2:5050/account-service/images/${chatRoom.user?.accountImage}")
                                        : AssetImage(
                                                "assets/default-avatar.png")
                                            as ImageProvider,
                                    radius: 25,
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          chatRoom.isSupportRoom &&
                                                  widget.currentUser.roleId ==
                                                      'user'
                                              ? 'Support Agent'
                                              : chatRoom.user?.accountName ??
                                                  'Unknown',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          chatRoom.lastMessage ?? 'null',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w300),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (chatRoom.isSeen != true)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              if (chatRoom.isSupportRoom)
                                Positioned(
                                  right: 10,
                                  top: 0,
                                  bottom: 0,
                                  child: Icon(Icons.support_agent,
                                      size: 40,
                                      color: Color.fromRGBO(0, 123, 255, 0.4)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
