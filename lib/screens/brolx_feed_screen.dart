import 'package:flutter/material.dart';
import '../services/brolx_service.dart';
import 'add_brolx_item_screen.dart';

class BrolxFeedScreen extends StatefulWidget {
  const BrolxFeedScreen({super.key});

  @override
  State<BrolxFeedScreen> createState() => _BrolxFeedScreenState();
}

class _BrolxFeedScreenState extends State<BrolxFeedScreen> {
  final _brolxService = BrolxService();
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final data = await _brolxService.fetchMarketplaceItems();
    if (mounted) {
      setState(() {
        _items = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("BroLX Marketplace", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.blueAccent),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadItems),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text("No items listed yet. Be the first!"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final sellerProfile = item['profiles'] ?? {};

          // Identify if it's for rent or sale to color-code it
          final isRent = item['listing_type'] == 'Rent';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] ?? 'No Title',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isRent ? Colors.orange.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isRent ? "FOR RENT" : "FOR SALE",
                          style: TextStyle(
                            color: isRent ? Colors.orange[800] : Colors.green[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹${item['price']}",
                    style: const TextStyle(fontSize: 22, color: Colors.blueAccent, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  if (item['description'] != null && item['description'].toString().isNotEmpty)
                    Text(item['description'], style: TextStyle(color: Colors.grey[700])),
                  const Divider(height: 30),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: Colors.blueAccent),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sellerProfile['full_name'] ?? 'Unknown Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(sellerProfile['course'] ?? 'VIT Student', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat opening soon!")));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                        child: const Text("Contact"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // If the user adds an item and comes back, refresh the list automatically!
          final shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBrolxItemScreen()),
          );
          if (shouldRefresh == true) {
            _loadItems();
          }
        },
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Sell/Rent"),
      ),
    );
  }
}