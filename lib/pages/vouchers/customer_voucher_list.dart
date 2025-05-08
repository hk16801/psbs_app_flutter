import 'package:flutter/material.dart';
import '../../services/voucher_service.dart';
import '../../models/voucher.dart';
import '../vouchers/voucher_card.dart';

class CustomerVoucherList extends StatefulWidget {
  @override
  _CustomerVoucherListState createState() => _CustomerVoucherListState();
}

class _CustomerVoucherListState extends State<CustomerVoucherList> {
  List<Voucher> vouchers = [];
  List<Voucher> filteredVouchers = [];
  bool isLoading = true;
  final String basePath = "/customer/vouchers";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchVouchers();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredVouchers = vouchers.where((voucher) {
        return voucher.voucherName.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _fetchVouchers() async {
    try {
      List<Voucher> data = await VoucherService.fetchVouchers();
      setState(() {
        vouchers = data;
        filteredVouchers = data;
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching vouchers: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Vouchers'),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      backgroundColor: Colors.blue[50],
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search vouchers...',
                      prefixIcon: Icon(Icons.search, color: Colors.blue[500]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredVouchers.isEmpty
                      ? Center(
                          child: Container(
                            padding: EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Text(
                              _searchController.text.isEmpty
                                  ? "No vouchers available"
                                  : "No vouchers match your search",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: filteredVouchers.map((voucher) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: VoucherCard(
                                  voucher: voucher,
                                  basePath: basePath,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}