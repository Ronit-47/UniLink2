import 'package:flutter/material.dart';
import '../services/brolx_service.dart';

class AddBrolxItemScreen extends StatefulWidget {
  const AddBrolxItemScreen({super.key});

  @override
  State<AddBrolxItemScreen> createState() => _AddBrolxItemScreenState();
}

class _AddBrolxItemScreenState extends State<AddBrolxItemScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedType = 'Sell'; // Default dropdown value
  bool _isLoading = false;
  final _brolxService = BrolxService();

  Future<void> _submitItem() async {
    if (_titleController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and Price are required!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Send the data to our Service file!
    final error = await _brolxService.addItem(
      title: _titleController.text,
      description: _descController.text,
      price: _priceController.text,
      listingType: _selectedType,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item Posted!"), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Go back and tell the previous screen to refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post to BroLX", style: TextStyle(color: Colors.blueAccent))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown for Rent vs Sell
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Listing Type"),
              items: ['Sell', 'Rent'].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) {
                setState(() => _selectedType = newValue!);
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Item Title (e.g. Drafter)"),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _selectedType == 'Rent' ? "Price per day/month (₹)" : "Selling Price (₹)"
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Description (Condition, etc)"),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitItem,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Post Item", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}