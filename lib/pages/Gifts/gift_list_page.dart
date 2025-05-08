import 'package:flutter/material.dart';
import 'package:psbs_app_flutter/pages/Gifts/redeem_history_page.dart';
import '../../models/gift.dart';
import '../../services/gift_service.dart';
import 'gift_detail_page.dart';

class GiftListScreen extends StatefulWidget {
  @override
  _GiftListScreenState createState() => _GiftListScreenState();
}

class _GiftListScreenState extends State<GiftListScreen> {
  late Future<List<Gift>> _giftsFuture;
  List<Gift> _allGifts = [];
  List<Gift> _filteredGifts = [];
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGifts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _allGifts = await GiftService.fetchGifts();
      _filteredGifts = List.from(_allGifts);
    } catch (e) {
      // Error handling will be managed in the FutureBuilder
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterGifts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGifts = List.from(_allGifts);
      } else {
        _filteredGifts = _allGifts
            .where((gift) =>
                gift.giftName.toLowerCase().contains(query.toLowerCase()) ||
                gift.giftDescription.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gift List"),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(198, 128, 173, 251), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search gifts...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: _filterGifts,
                  ),
                ),
                
                // Gift List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredGifts.isEmpty
                          ? const Center(child: Text("No gifts found"))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _filteredGifts.length,
                              itemBuilder: (context, index) {
                                var gift = _filteredGifts[index];
                                bool isVoucher = gift.giftCode != null && gift.giftCode!.isNotEmpty;
                                
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>
                                            GiftDetailPage(giftId: gift.giftId),
                                        transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Card(
                                    elevation: 4,
                                    margin: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    // Add a gradient background for vouchers
                                    color: isVoucher ? null : Colors.white,
                                    child: Container(
                                      decoration: isVoucher
                                          ? BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.amber.shade100, Colors.white],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(15),
                                            )
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Stack(
                                              children: [
                                                Hero(
                                                  tag: 'giftImage-${gift.giftId}',
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Image.network(
                                                      "http://10.0.2.2:5050${gift.giftImage}",
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          const Icon(Icons.broken_image, size: 60),
                                                    ),
                                                  ),
                                                ),
                                                if (isVoucher)
                                                  Positioned(
                                                    right: 0,
                                                    top: 0,
                                                    child: Container(
                                                      padding: EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.amber,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Icon(
                                                        Icons.card_giftcard,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          gift.giftName,
                                                          style: const TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                      if (isVoucher)
                                                        Container(
                                                          padding: EdgeInsets.symmetric(
                                                              horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.amber,
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Text(
                                                            "VOUCHER",
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    gift.giftDescription,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(color: Colors.grey[700]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              "⭐ ${gift.giftPoint}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orangeAccent),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RedeemHistoryPage()),
                );
              },
              child: const Icon(Icons.history),
            ),
          ),
        ],
      ),
    );
  }
}
