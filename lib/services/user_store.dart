import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:psbs_app_flutter/models/user.dart';
import '../services/user_service.dart';

// Define your store
class UseUserStore extends Store {
  User? currentUser;
  bool isLoading = true;
  UseUserStore() : super(0);
  Future<void> loadUserDetails(String accountId) async {
    print("Debug: Running loadUserDetails in store with accountId $accountId");
    final user = await UserService.fetchUser(accountId);
    if (user != null) {
      currentUser = user;
      isLoading = false;
    }
  }
}

UseUserStore useUserStore() => create(() => UseUserStore());
