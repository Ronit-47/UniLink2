import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  // Controllers to grab what the user types
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  Future<void> _submitItem() async {
    // 1. Basic validation
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Price are required!")),
      );
      return;
    }

    try {
      // 2. Get the ID of the user who is currently logged in
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // 3. Insert the data into our new table
      await Supabase.instance.client.from('brolx_items').insert({
        'seller_id': userId,
        'item_name': nameController.text.trim(),
        'price': priceController.text.trim(),
        'description': descController.text.trim(),
      });

      // 4. Show success and go back to the previous screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item added to marketplace!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Closes the "Add Item" page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sell an Item"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Keeps it simple and left-aligned
          children: [
            const Text("Item Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Item Name (e.g. induction)"),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: priceController,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Price (e.g. 150 or 50/hr)"),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: descController,
              maxLines: 3, // Makes the box bigger for a description
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Description (Condition, about etc.)"),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitItem,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: const Text("Post to BroLX"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}