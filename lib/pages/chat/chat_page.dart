// chat_page.dart
import 'package:flutter/material.dart';
import 'package:psbs_app_flutter/pages/chat/chat_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psbs_app_flutter/models/user.dart';
import 'package:psbs_app_flutter/services/user_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accountId = prefs.getString('accountId');

    if (accountId != null) {
      try {
        User? user = await UserService.fetchUser(accountId);
        if (user != null) {
          setState(() {
            _currentUser = user;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _currentUser = null;
          });
        }
      } catch (e) {
        print('Error fetching user: $e');
        setState(() {
          _isLoading = false;
          _currentUser = null;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentUser == null) {
      return const Center(
          child: Text('User not logged in or user data not found.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: true,
      ),
      body: Column(
        // Wrap ChatListWidget in a Column
        children: [
          Expanded(
            // Use Expanded to fill available space
            child: ChatListWidget(currentUser: _currentUser!),
          ),
        ],
      ),
    );
  }
}
