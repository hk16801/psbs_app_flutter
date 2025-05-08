import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:psbs_app_flutter/models/user.dart';

// Define the chat store
class UseChatStore extends Store {
  String chatId = "";
  User? user;
  bool isSupportChat = false;

  UseChatStore() : super(0);

  void changeChat(String newChatId, User? newUser, bool isSupport) {
    set({
      chatId: newChatId,
      user: newUser,
      isSupportChat: isSupport,
    });
  }
}

UseChatStore useChatStore() => create(() => UseChatStore());
