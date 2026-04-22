import 'package:flutter/material.dart';
import '../services/circles_service.dart';
import 'chat_screen.dart';

class CirclesScreen extends StatefulWidget {
  const CirclesScreen({super.key});

  @override
  State<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends State<CirclesScreen> {
  final _circlesService = CirclesService();
  List<dynamic> _network = [];
  bool _isLoading = true;

  // The categories you requested!
  final List<String> _categories = ['All', 'Co-Pilots', 'The Squad', 'Lowkey', 'Brain Trust'];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadNetwork();
  }

  Future<void> _loadNetwork() async {
    final data = await _circlesService.fetchNetwork();
    if (mounted) {
      setState(() {
        _network = data;
        _isLoading = false;
      });
    }
  }

  // A helper function to assign a random category to database users for the demo
  String _getCategoryForUser(int index) {
    if (index % 4 == 0) return 'Co-Pilots';
    if (index % 3 == 0) return 'Lowkey';
    if (index % 2 == 0) return 'Brain Trust';
    return 'The Squad';
  }

  @override
  Widget build(BuildContext context) {
    // Filter the list based on the selected chip
    final filteredNetwork = _selectedCategory == 'All'
        ? _network
        : _network.where((user) => _getCategoryForUser(_network.indexOf(user)) == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Your Circles", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The Category Filter Chips
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: Colors.deepPurple.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.deepPurple : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // The User List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
                : filteredNetwork.isEmpty
                ? Center(child: Text("No connections in '$_selectedCategory' yet."))
                : ListView.builder(
              itemCount: filteredNetwork.length,
              itemBuilder: (context, index) {
                final user = filteredNetwork[index];
                // Look up their fake category for the demo
                final originalIndex = _network.indexOf(user);
                final userCategory = _getCategoryForUser(originalIndex);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                    child: Text(
                      user['full_name']?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  title: Text(user['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(userCategory, style: TextStyle(color: Colors.deepPurple[300], fontSize: 13)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // Open the beautiful Chat Screen!
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          friendName: user['full_name'] ?? 'Unknown',
                          categoryName: userCategory,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}