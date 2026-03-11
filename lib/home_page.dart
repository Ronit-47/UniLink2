import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "Loading...";
  String userBranch = "";

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch the data the moment the page opens
  }

  Future<void> _fetchUserData() async {
    try {
      // 1. Ask Supabase for the ID of whoever is currently logged in
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // 2. Go to the 'profiles' table and find the row that matches this ID
      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name, branch')
          .eq('id', userId)
          .single();

      // 3. Update the screen with their real data
      if (mounted) {
        setState(() {
          userName = data['full_name'] ?? "Student";
          userBranch = data['branch'] ?? "";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = "Student"; // Fallback name if it fails
        });
      }
      print("Error fetching profile: $e");
    }
  }

  Future<void> _logout() async {
    // Kills the session in Supabase
    await Supabase.instance.client.auth.signOut();

    // Kills the Home Page and throws them back to the Login Page
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("UniLink Dashboard"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: IconButton(
              icon: const Icon(Icons.logout, size: 30, color: Colors.grey),
              onPressed: _logout, // Linked to the logout function
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Welcome back,", style: TextStyle(fontSize: 16)),
            Text(userName, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),

            // Only show the branch if we successfully fetched it
            if (userBranch.isNotEmpty)
              Text(userBranch, style: const TextStyle(fontSize: 16, color: Colors.indigo)),

            const SizedBox(height: 40),

            // Your 4 Feature Boxes
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _featureBox("Matchmaker", Icons.person, Colors.red),
                  _featureBox("The Vault", Icons.book, Colors.green),
                  _featureBox("BroLX", Icons.shopping_bag, Colors.blue),
                  _featureBox("Settings", Icons.settings, Colors.orange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // The helper widget to draw the square boxes
  Widget _featureBox(String name, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: color),
          const SizedBox(height: 15),
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    );
  }
}