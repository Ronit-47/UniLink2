import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Added Supabase import
import 'add_item_page.dart';

class BrolxPage extends StatefulWidget {
  const BrolxPage({super.key});

  @override
  State<BrolxPage> createState() => _BrolxPageState();
}

class _BrolxPageState extends State<BrolxPage> {
  List<dynamic> marketplaceItems = [];
  bool isLoading = true; // Shows a loading spinner while fetching

  @override
  void initState() {
    super.initState();
    _fetchMarketplaceItems();
  }

  Future<void> _fetchMarketplaceItems() async {
    try {
      // THE MAGIC QUERY: This fetches the item AND the seller's name and branch from the profiles table!
      final data = await Supabase.instance.client
          .from('brolx_items')
          .select('item_name, price, description, profiles(full_name, branch)');

      if (mounted) {
        setState(() {
          marketplaceItems = data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching items: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BroLX Marketplace"),
        // Added a refresh button so users can reload the page after adding an item
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() { isLoading = true; });
              _fetchMarketplaceItems();
            },
          )
        ],
      ),
      // If loading is true, show a spinner. If false, show the list.
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : marketplaceItems.isEmpty
          ? const Center(child: Text("No items for sale yet. Be the first!", style: TextStyle(fontSize: 18)))
          : Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView.builder(
          itemCount: marketplaceItems.length,
          itemBuilder: (context, index) {
            final item = marketplaceItems[index];

            // Safely extract the seller's info from the joined table
            final sellerName = item['profiles']?['full_name'] ?? 'Unknown Seller';
            final sellerBranch = item['profiles']?['branch'] ?? 'Unknown Branch';

            return Container(
              color: Colors.grey.shade200,
              margin: const EdgeInsets.only(bottom: 15.0),
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Item: " + (item["item_name"] ?? "Unnamed"),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),

                  // Added description display if it exists
                  if (item["description"] != null && item["description"].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text("Desc: " + item["description"], style: const TextStyle(fontStyle: FontStyle.italic)),
                    ),

                  Text("Price: Rs " + (item["price"] ?? "0"), style: const TextStyle(fontSize: 16)),
                  Text("Seller: " + sellerName + " (" + sellerBranch + ")", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Chat coming soon!")),
                      );
                    },
                    child: const Text("Buy Item"),
                  ),
                ],
              ),
            );
          },
        ),
      ),

      // I added back the FloatingActionButton so you can navigate to the Add Item page
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemPage()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}