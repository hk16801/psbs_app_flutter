import 'package:flutter/material.dart';
import 'package:psbs_app_flutter/models/user.dart';
import 'package:psbs_app_flutter/services/signal_r_service.dart';
import 'package:psbs_app_flutter/services/user_service.dart';
import 'package:psbs_app_flutter/models/chat_room.dart';
import 'package:psbs_app_flutter/utils/dialog_utils.dart';

class AddUserWidget extends StatefulWidget {
  final SignalRService signalRService;
  final User currentUser;
  final List<ChatRoom> currentList;
  final VoidCallback onClose;

  AddUserWidget({
    required this.signalRService,
    required this.currentUser,
    required this.currentList,
    required this.onClose,
  });

  @override
  _AddUserWidgetState createState() => _AddUserWidgetState();
}

class _AddUserWidgetState extends State<AddUserWidget> {
  List<User> _userList = [];
  List<User> _filteredUserList = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final data = await UserService.fetchAllUsers();
      if (data != null && data.isNotEmpty) {
        final filtered = data
            .where((user) =>
                user.accountId != widget.currentUser.accountId &&
                !widget.currentList.any((chat) =>
                    chat.serveFor == user.accountId && !chat.isSupportRoom))
            .toList();

        setState(() {
          _userList = filtered;
          _filteredUserList = filtered;
        });
      }
    } catch (err) {
      print("Error fetching user data: $err");
    }
  }

  void _handleSearch() {
    final searchTerm = _searchController.text.toLowerCase();
    final filtered = _userList
        .where((user) => user.accountName.toLowerCase().contains(searchTerm))
        .toList();
    setState(() {
      _filteredUserList = filtered;
    });
  }

  Future<void> _handleAdd(String receiverId) async {
    try {
      final senderId = widget.currentUser.accountId;
      await widget.signalRService
          .invoke("CreateChatRoom", [senderId, receiverId]);
      widget.onClose();
    } catch (err) {
      showErrorDialog(context, "Failed to create chat room. Please try again.");
      print("Error creating chat room: $err");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      // Center the widget directly
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Color.fromRGBO(17, 25, 40, 0.781),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Add User",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            SizedBox(height: 20),
            Form(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search by username",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _handleSearch,
                    child: Text("Search"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 50),
            if (_filteredUserList.isNotEmpty)
              ..._filteredUserList
                  .map(
                      (user) => // Replace the problematic Row with this improved version:
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // First child - user info with constrained width
                                Expanded(
                                  // Add Expanded here to give this section flexible width
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: user.accountImage !=
                                                null
                                            ? NetworkImage(
                                                "http://10.0.2.2:5050/account-service/images/${user.accountImage}")
                                            : AssetImage(
                                                    "assets/default-avatar.png")
                                                as ImageProvider,
                                        radius: 25,
                                      ),
                                      SizedBox(width: 20),
                                      Flexible(
                                        // Keep Flexible for the text
                                        child: Text(
                                          user.accountName,
                                          style: TextStyle(color: Colors.white),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Add some spacing between the user info and button
                                SizedBox(width: 10),
                                // Second child - button with fixed width
                                ElevatedButton(
                                  onPressed: () => _handleAdd(user.accountId),
                                  child: Text("Add User"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                  .toList()
            else
              Text(
                "No users found",
                style: TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
