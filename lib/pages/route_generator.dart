import 'package:flutter/material.dart';
import 'package:psbs_app_flutter/main.dart';
import 'package:psbs_app_flutter/models/voucher.dart';
import 'package:psbs_app_flutter/pages/Account/changepassword_page.dart';
import 'package:psbs_app_flutter/pages/Booking/add_booking.dart';
import 'package:psbs_app_flutter/pages/Booking/booking_list_page.dart';
import 'package:psbs_app_flutter/pages/Gifts/redeem_history_page.dart';
import 'package:psbs_app_flutter/pages/chat/chat_page.dart';
import 'package:psbs_app_flutter/pages/home_page.dart';
import 'package:psbs_app_flutter/pages/notification/notification_page.dart';
import 'package:psbs_app_flutter/pages/pet/pet_page.dart';
import 'package:psbs_app_flutter/pages/booking_page.dart';
import 'package:psbs_app_flutter/pages/Account/profile_page.dart';
import 'package:psbs_app_flutter/pages/Account/login_page.dart';
import 'package:psbs_app_flutter/pages/Services/service_page.dart';
import 'package:psbs_app_flutter/pages/Account/register_page.dart';
import 'package:psbs_app_flutter/pages/Account/forgotpassword_page.dart';
import 'package:psbs_app_flutter/pages/Account/editprofile_page.dart';
import 'package:psbs_app_flutter/pages/room/room_page.dart';
import 'package:psbs_app_flutter/pages/vouchers/customer_voucher_list.dart';
import 'package:psbs_app_flutter/pages/vouchers/voucher_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psbs_app_flutter/pages/Gifts/gift_list_page.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/home':
        return MaterialPageRoute(
            builder: (_) => const MyHomePage(
                  title: '',
                  accountId: '',
                ));
      case '/pet':
        return MaterialPageRoute(builder: (_) => const PetPage());
      case '/booking':
        return MaterialPageRoute(builder: (_) => AddBookingPage());
      case '/voucher':
        return MaterialPageRoute(builder: (_) => CustomerVoucherList());
      case '/profile':
        return MaterialPageRoute(
            builder: (_) => const ProfilePage(
                  accountId: '',
                  title: '',
                ));
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginPage());
      case '/register':
        return MaterialPageRoute(builder: (_) => RegisterPage());
      case '/forgotpassword':
        return MaterialPageRoute(builder: (_) => ForgotPasswordPage());
      case '/editprofile':
        return MaterialPageRoute(
            builder: (_) => const EditProfilePage(
                  accountId: '',
                  title: '',
                ));
      case '/changepassword':
        return MaterialPageRoute(
            builder: (_) => ChangePasswordPage(
                  title: '',
                  accountId: '',
                ));
      case '/customer/vouchers/detail':
        if (args is Voucher) {
          return MaterialPageRoute(
            builder: (_) => VoucherDetailScreen(voucher: args),
          );
        }
        return _errorRoute();
      case '/chat':
        return MaterialPageRoute(builder: (_) => const ChatPage());
      case '/room':
        return MaterialPageRoute(builder: (_) => const RoomPage());
      case '/gifts':
        return MaterialPageRoute(builder: (_) => GiftListScreen());
      case '/services':
        return MaterialPageRoute(builder: (_) => const ServicePage());
      case '/redeem':
        return MaterialPageRoute(builder: (_) => RedeemHistoryPage());
      case '/notification':
        return MaterialPageRoute(builder: (_) => NotificationsPage());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Page not found')),
      ),
    );
  }
}
