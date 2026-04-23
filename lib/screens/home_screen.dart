import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

// Import your feature screens!
import 'vibematch_screen.dart';
import 'brolx_feed_screen.dart';
import 'vault_feed_screen.dart';
import 'circles_screen.dart';
import 'account_screen.dart';
import 'notifications_screen.dart'; // NEW: Imported the notifications screen!

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();

  String _userName = "Student";
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted && data != null) {
        setState(() {
          final String fullName = data['full_name']?.toString() ?? "Student";
          _userName = fullName.isNotEmpty ? fullName.split(' ')[0] : "Student";
          _avatarUrl = data['avatar_url'];
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    // main.dart Gatekeeper handles the redirect back to Login
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          // 1. THE IMMERSIVE HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
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
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: 1.2
                      ),
                    ),
                    // PROFILE, NOTIFICATIONS & LOGOUT ACTIONS
                    Row(
                      children: [
                        // --- NEW: NOTIFICATION BELL ---
                        IconButton(
                          icon: const Icon(Icons.notifications_active_rounded, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 4),

                        // The Profile Logo Trigger
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AccountScreen()),
                            );
                            _fetchUserProfile();
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white24,
                            backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                            child: _avatarUrl == null
                                ? const Icon(Icons.person_rounded, color: Colors.white, size: 20)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),

                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                          onPressed: _handleLogout,
                          tooltip: "Log Out",
                        ),
                      ],
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
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : Text(
                  _userName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5
                  ),
                ),
              ],
            ),
          ),

          // 2. THE BENTO-BOX DASHBOARD
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 40),
              physics: const BouncingScrollPhysics(),
              children: [
                const Text(
                  "Your Campus",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _buildPremiumCard(
                      context,
                      title: "VibeMatch",
                      subtitle: "Find your flatmate",
                      icon: Icons.favorite_rounded,
                      accentColor: const Color(0xFFFF4B8C),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VibeMatchScreen())),
                    ),
                    _buildPremiumCard(
                      context,
                      title: "BroLX",
                      subtitle: "Campus marketplace",
                      icon: Icons.shopping_bag_rounded,
                      accentColor: const Color(0xFF4A89FE),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BrolxFeedScreen())),
                    ),
                    _buildPremiumCard(
                      context,
                      title: "The Vault",
                      subtitle: "Academic resources",
                      icon: Icons.folder_copy_rounded,
                      accentColor: const Color(0xFF00C9A7),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VaultFeedScreen())),
                    ),
                    _buildPremiumCard(
                      context,
                      title: "Circles",
                      subtitle: "Your network",
                      icon: Icons.forum_rounded,
                      accentColor: const Color(0xFF8A2BE2),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 32, color: accentColor),
                ),
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
                      overflow: TextOverflow.ellipsis,
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