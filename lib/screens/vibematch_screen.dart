import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../services/vibematch_service.dart';
import 'edit_vibe_screen.dart';

class VibeMatchScreen extends StatefulWidget {
  const VibeMatchScreen({super.key});

  @override
  State<VibeMatchScreen> createState() => _VibeMatchScreenState();
}

class _VibeMatchScreenState extends State<VibeMatchScreen> {
  final _vibeService = VibeMatchService();
  final CardSwiperController _swiperController = CardSwiperController();

  List<dynamic> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    final data = await _vibeService.fetchPotentialRoommates();
    if (mounted) {
      setState(() {
        _profiles = data;
        _isLoading = false;
      });
    }
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    final targetUser = _profiles[previousIndex];

    // Determine if it was a right (like) or left (pass) swipe
    final isRightSwipe = direction == CardSwiperDirection.right;

    _vibeService.recordSwipe(
        targetUserId: targetUser['id'],
        isRightSwipe: isRightSwipe
    );

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isRightSwipe ? "Vibe Checked! \u2728" : "Passed"),
        backgroundColor: isRightSwipe ? Colors.pinkAccent : Colors.grey,
        duration: const Duration(milliseconds: 500),
      ),
    );

    return true; // Return true to allow the swipe to happen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("VibeMatch", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.pinkAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded), // Changed icon to look like "Settings/Tune"
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditVibeScreen()),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
            : _profiles.isEmpty
            ? const Center(child: Text("No new profiles in your area.", style: TextStyle(fontSize: 18)))
            : Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Find your Co-Pilot", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            Expanded(
              child: CardSwiper(
                controller: _swiperController,
                cardsCount: _profiles.length,
                onSwipe: _onSwipe,
                padding: const EdgeInsets.all(24.0),
                numberOfCardsDisplayed: _profiles.length > 2 ? 3 : _profiles.length,
                backCardOffset: const Offset(0, 40),
                cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                  final profile = _profiles[index];
                  return _buildProfileCard(profile);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0, top: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: "btn1",
                    onPressed: () => _swiperController.swipe(CardSwiperDirection.left),
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 30),
                  ),
                  FloatingActionButton(
                    heroTag: "btn2",
                    onPressed: () => _swiperController.swipe(CardSwiperDirection.right),
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 30),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // The actual UI for the Tinder-style card
// The actual UI for the Tinder-style card with REAL DB Data!
  Widget _buildProfileCard(dynamic profile) {
    // Safely extract the real data from the database payload
    final String? avatarUrl = profile['avatar_url'];
    final String fullName = profile['full_name'] ?? 'Unknown';
    final String year = profile['academic_year'] ?? 'VIT';
    final String branch = profile['branch'] ?? 'Student';
    final String div = profile['division'] ?? '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 3, blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black12, // Fallback color while image loads
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                // If they have a photo URL, display it. Otherwise, show the pink icon.
                child: avatarUrl != null
                    ? Image.network(avatarUrl, fit: BoxFit.cover)
                    : Container(
                  color: Colors.pinkAccent.withOpacity(0.1),
                  child: const Icon(Icons.person, size: 120, color: Colors.pinkAccent),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.school, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      // Dynamic Academic Info!
                      Text("$year • $branch • Div $div", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}