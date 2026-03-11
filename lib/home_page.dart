import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'brolx_page.dart';
import 'settings_page.dart';// This will stop being "unused" now!

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
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name, branch')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          userName = data['full_name'] ?? "Student";
          userBranch = data['branch'] ?? "";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = "Student";
        });
      }
      // Fixed the yellow linter warning by using debugPrint instead of print
      debugPrint("Error fetching profile: $e");
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
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
              onPressed: _logout,
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
            if (userBranch.isNotEmpty)
              Text(userBranch, style: const TextStyle(fontSize: 16, color: Colors.indigo)),
            const SizedBox(height: 40),

            Expanded(
            child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
            _featureBox("Matchmaker", Icons.person, Colors.red, () {}),
            _featureBox("The Vault", Icons.book, Colors.green, () {}),
            _featureBox("BroLX", Icons.shopping_bag, Colors.blue, () {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const BrolxPage()),
    );
    }),
    // UPDATED SETTINGS BOX:
    _featureBox("Settings", Icons.settings, Colors.orange, () {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
    }),
    ],
    ),
    ),
          ],
        ),
      ),
    );
  }

  // FIX 2: Updated parameters and fixed the deprecated color warning
  Widget _featureBox(String name, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), // Fixed deprecation warning!
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
      ),
    );
  }
}