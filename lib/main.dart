import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:psbs_app_flutter/pages/Booking/booking_list_page.dart';
import 'package:psbs_app_flutter/pages/home_page.dart';
import 'package:psbs_app_flutter/pages/pet/pet_page.dart';
import 'package:psbs_app_flutter/pages/route_generator.dart';
import 'package:psbs_app_flutter/pages/Services/service_page.dart';
import 'package:psbs_app_flutter/pages/vouchers/customer_voucher_list.dart';
import 'package:psbs_app_flutter/pages/Gifts/gift_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
// Additional pages from Tuan/AccountManagementFlutter
import 'pages/Account/profile_page.dart';
import 'pages/room/room_page.dart';

void main() {
  runApp(const StoreScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PetEase App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login', // Default startup page
      onGenerateRoute: RouteGenerator.generateRoute,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String accountId;
  final int initialIndex;
  final String title;

  const MyHomePage({
    super.key,
    required this.title,
    required this.accountId,
    this.initialIndex = 0,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late String accountId;
  late int index;
  final navigationKey = GlobalKey<CurvedNavigationBarState>();

  final screens = [
    HomePage(),
    ServicePage(),
    BookingListScreen(),
    RoomPage(),
    ProfilePage(accountId: '', title: ''),
  ];

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    _loadAccountId();
  }

  Future<void> _loadAccountId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      accountId = widget.accountId.isNotEmpty
          ? widget.accountId
          : (prefs.getString('accountId') ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      Icon(Icons.home, size: 30),
      //Icon(Icons.pets_rounded, size: 30),
      Icon(Icons.local_offer, size: 30),
      Icon(Icons.add, size: 30),
      Icon(Icons.local_hotel, size: 30),
      Icon(Icons.person, size: 30),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            Icon(Icons.pets, color: Colors.white, size: 30),
            const SizedBox(width: 5),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Pet',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                  TextSpan(
                    text: 'Ease',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              // Navigate to chat list
              Navigator.pushNamed(
                  context, '/notification'); // Navigate to ChatPage
            },
            icon:
                const Icon(Icons.notifications, color: Colors.white, size: 28),
            tooltip: 'Chat',
          ),
          IconButton(
            onPressed: () {
              // Navigate to chat list
              Navigator.pushNamed(context, '/chat'); // Navigate to ChatPage
            },
            icon: const Icon(Icons.messenger, color: Colors.white, size: 28),
            tooltip: 'Chat',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            onSelected: (value) {
              if (value == 'logout') {
                logout(context); // Gọi hàm logout
              } else if (value == 'voucher') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CustomerVoucherList()),
                );
                // } else if (value == 'camera') {
                //   // 👉 Điều hướng sang trang xem camera
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(builder: (context) => CameraScreen()),
                //   );
              } else if (value == 'gift') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GiftListScreen()),
                );
              } else if (value == 'pet') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PetPage()),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'voucher',
                child: ListTile(
                  leading: Icon(Icons.discount, color: Colors.blue),
                  title: Text('Voucher', style: TextStyle(color: Colors.black)),
                ),
              ),
              PopupMenuItem(
                value: 'gift',
                child: ListTile(
                  leading: Icon(Icons.card_giftcard, color: Colors.blue),
                  title: Text('Gift', style: TextStyle(color: Colors.black)),
                ),
              ),
              // PopupMenuItem(
              //   value: 'camera',
              //   child: ListTile(
              //     leading: const Icon(Icons.videocam, color: Colors.blue),
              //     title: const Text('Camera',
              //         style: TextStyle(color: Colors.black)),
              //   ),
              // ),
              PopupMenuItem(
                value: 'pet',
                child: ListTile(
                  leading: Icon(Icons.pets, color: Colors.blue),
                  title: Text('Pet', style: TextStyle(color: Colors.black)),
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          iconTheme: IconThemeData(color: Colors.white),
        ),
        child: CurvedNavigationBar(
          key: navigationKey,
          color: Colors.blue,
          buttonBackgroundColor: Colors.blue,
          items: items,
          index: index,
          onTap: (selectedIndex) {
            setState(() {
              index = selectedIndex;
            });
          },
          height: 70,
          animationCurve: Curves.easeInOut,
          backgroundColor: Colors.transparent,
        ),
      ),
      body: screens[index],
    );
  }

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('accountId');
    await prefs.remove('token');
    Navigator.pushReplacementNamed(context, "/login");
  }
}
