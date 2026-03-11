import 'package:flutter/material.dart';

class BrolxPage extends StatelessWidget {
  const BrolxPage({super.key});

  final List<Map<String, String>> items = const [
    {"name": "Used Drafter", "price": "150", "seller": "Rahul (Mech)"},
    {"name": "Engineering Kit", "price": "300", "seller": "Amit (Civil)"},
    {"name": "HP Calculator", "price": "500", "seller": "Neha (Comp)"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BroLX Marketplace"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {

            // The absolute simplest way to show an item:
            // A colored box with a vertical column of text inside.
            return Container(
              color: Colors.grey.shade200, // Flat grey background instead of borders
              margin: const EdgeInsets.only(bottom: 15.0),
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Aligns text to the left
                children: [
                  Text(
                    "Item: " + items[index]["name"]!,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text("Price: Rs " + items[index]["price"]!, style: const TextStyle(fontSize: 16)),
                  Text("Seller: " + items[index]["seller"]!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 15),

                  // A simple button at the bottom of the column
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
    );
  }
}