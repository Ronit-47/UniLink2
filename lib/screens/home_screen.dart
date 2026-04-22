import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

// Import your 4 feature screens!
import 'vibematch_screen.dart';
import 'brolx_feed_screen.dart';
import 'vault_feed_screen.dart';
import 'circles_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();

  String _userName = "Student";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          // Grab just the first name for a friendlier greeting
          _userName = data['full_name'].toString().split(' ')[0];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    // main.dart Gatekeeper handles the redirect
  }

  @override
  Widget build(BuildContext context) {
    // Make the top status bar icons white to contrast with our dark gradient
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // A very premium, soft off-white
      body: Column(
        children: [
          // 1. THE IMMERSIVE HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)], // Deep Indigo to Cyan
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "UniLink",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1.2),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                      onPressed: _handleLogout,
                      tooltip: "Log Out",
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  "Welcome back,",
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                ),
                const SizedBox(height: 4),
                _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                  _userName,
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
              ],
            ),
          ),

          // 2. THE BENTO-BOX DASHBOARD
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 40),
              physics: const BouncingScrollPhysics(), // Adds an Apple-like bounce effect
              children: [
                const Text(
                  "Your Campus",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true, // Required to use GridView inside a ListView
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85, // Makes the cards slightly taller than they are wide
                  children: [
                    _buildPremiumCard(
                      context,
                      title: "VibeMatch",
                      subtitle: "Find your flatmate",
                      icon: Icons.favorite_rounded,
                      accentColor: const Color(0xFFFF4B8C), // Vibrant Pink
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VibeMatchScreen())),
                    ),
                    _buildPremiumCard(
                      context,
                      title: "BroLX",
                      subtitle: "Campus marketplace",
                      icon: Icons.shopping_bag_rounded,
                      accentColor: const Color(0xFF4A89FE), // Bright Blue
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BrolxFeedScreen())),
                    ),
                    _buildPremiumCard(
                      context,
                      title: "The Vault",
                      subtitle: "Academic resources",
                      icon: Icons.folder_copy_rounded,
                      accentColor: const Color(0xFF00C9A7), // Teal/Green
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VaultFeedScreen())),
                    ),
                    _buildPremiumCard(
                      context,
                      title: "Circles", // Updated from Roster!
                      subtitle: "Your network",
                      icon: Icons.forum_rounded,
                      accentColor: const Color(0xFF8A2BE2), // Deep Purple
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CirclesScreen())),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. THE CUSTOM CARD WIDGET
  Widget _buildPremiumCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          // This creates a glowing, colored shadow instead of a dull grey one
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          splashColor: accentColor.withOpacity(0.1),
          highlightColor: accentColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Icon Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 32, color: accentColor),
                ),

                // Bottom Text Area
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // Ensures text doesn't break the layout if it's too long
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}