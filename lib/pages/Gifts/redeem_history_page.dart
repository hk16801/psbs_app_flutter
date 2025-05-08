import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:psbs_app_flutter/models/redeem_history.dart';
import 'package:psbs_app_flutter/services/redeem_service.dart';
import 'package:psbs_app_flutter/utils/dialog_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RedeemHistoryPage extends StatefulWidget {
  @override
  _RedeemHistoryState createState() => _RedeemHistoryState();
}

class _RedeemHistoryState extends State<RedeemHistoryPage> {
  late Future<List<RedeemHistory>> _giftsFuture;
  late String userId;

  @override
  void initState() {
    super.initState();
    _initData(); // Call an async init method
  }

  Future<void> _initData() async {
    await _loadAccountId(); // Wait for userId to be loaded
    _giftsFuture = RedeemService.fetchRedeemHistories(userId);
    setState(() {}); // Trigger a rebuild to reflect the loaded data
  }

  Future<void> _loadAccountId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('accountId') ?? "";
  }

  Color _getStatusColor(String redeemStatusId) {
    if (redeemStatusId == "1509e4e6-e1ec-42a4-9301-05131dd498e4") {
      return const Color.fromARGB(255, 248, 209, 54); // Just Redeemed
    } else if (redeemStatusId == "33b84495-c2a6-4b3e-98ca-f13d9c150946") {
      return Colors.green; // Picked up at Store
    } else if (redeemStatusId == "6a565faf-d31e-4ec7-ad20-433f34e3d7a9") {
      return Colors.red; // Canceled Redeem
    } else {
      return Colors.grey; // Default color
    }
  }

  String _getStatusText(String redeemStatusId) {
    print("status hien tai ne: $redeemStatusId");
    if (redeemStatusId == "1509e4e6-e1ec-42a4-9301-05131dd498e4") {
      return "Redeemed";
    } else if (redeemStatusId == "33b84495-c2a6-4b3e-98ca-f13d9c150946") {
      return "Picked up";
    } else if (redeemStatusId == "6a565faf-d31e-4ec7-ad20-433f34e3d7a9") {
      return "Canceled";
    } else {
      return "Unknown";
    }
  }

  Future<void> _cancelRedemption(String redeemHistoryId, int point) async {
    try {
      final responseCancel =
          await RedeemService.cancelRedemption(userId, redeemHistoryId, point);

      if (responseCancel) {
        showSuccessDialog(context, "Your redemption has been cancelled.");
        _initData();
      } else {
        showErrorDialog(context, "Failed to cancel redemption.");
      }
    } catch (e) {
      showErrorDialog(context, "An error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redeem History'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(198, 128, 173, 251), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<RedeemHistory>>(
          future: _giftsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No gifts available"));
            }

            List<RedeemHistory> gifts = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: gifts.length,
              itemBuilder: (context, index) {
                var gift = gifts[index];
                return GestureDetector(
                  onTap: () {
                    // Navigator.push(
                    //   context,
                    //   PageRouteBuilder(
                    //     pageBuilder: (_, __, ___) =>
                    //         GiftDetailPage(giftId: gift.giftId),
                    //     transitionsBuilder:
                    //         (context, animation, secondaryAnimation, child) {
                    //       return FadeTransition(
                    //         opacity: animation,
                    //         child: child,
                    //       );
                    //     },
                    //   ),
                    // );
                  },
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(
                          12), // Padding around the card content
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment
                            .center, // Align items vertically to the center
                        children: [
                          Hero(
                            tag: 'giftImage-${gift.redeemHistoryId}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                "http://10.0.2.2:5022${gift.giftImage}",
                                width: 75,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 60),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  gift.giftName,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('yyyy-MM-dd HH:mm').format(gift
                                      .redeemDate), // Adjust format as needed
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),

                                // Row with no padding around it
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        gift.giftCode != null &&
                                                    gift.giftCode!.isNotEmpty ||
                                                gift.giftCode == "null"
                                            ? gift.giftCode!
                                            : "No Code",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            TextStyle(color: Colors.grey[700]),
                                      ),
                                    ),
                                    if (gift.giftCode != null &&
                                            gift.giftCode!.isNotEmpty ||
                                        gift.giftCode == "null")
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 16),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                              text: gift.giftCode!));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Code copied to clipboard')),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              if (gift.redeemStatusId ==
                                  "1509e4e6-e1ec-42a4-9301-05131dd498e4")
                                IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.red),
                                  onPressed: () {
                                    if (gift.redeemHistoryId != null &&
                                        gift.giftPoint != null) {
                                      showConfirmationDialog(
                                        context,
                                        "Confirm Cancellation",
                                        "Are you sure you want to cancel this redemption?",
                                        () {
                                          _cancelRedemption(
                                              gift.redeemHistoryId!,
                                              gift.giftPoint!);
                                        },
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "Cannot cancel: Missing redeem history ID or points."),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              const SizedBox(width: 12),
                              Text(
                                "⭐ ${gift.giftPoint}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(gift.redeemStatusId),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getStatusText(gift.redeemStatusId),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
