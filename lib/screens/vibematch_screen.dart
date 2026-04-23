import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../services/vibematch_service.dart';
import 'edit_vibe_screen.dart';
import 'take_quiz_screen.dart';

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

  // Active Filters
  String _selectedYear = 'All';
  final _branchFilterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    _branchFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);

    // Pass the active filters to the service
    final data = await _vibeService.fetchPotentialRoommates(
      yearFilter: _selectedYear,
      branchFilter: _branchFilterController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _profiles = data;
        _isLoading = false;
      });
    }
  }

  // --- THE FILTER MODAL ---
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder( // StatefulBuilder allows the modal to update its own UI
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 24, right: 24, top: 24
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Filter Matches", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 20),

                    const Text("Academic Year", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedYear,
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: ['All', 'FY', 'SY', 'TY', 'Final'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) => setModalState(() => _selectedYear = v!),
                    ),
                    const SizedBox(height: 16),

                    const Text("Branch / Major", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _branchFilterController,
                      decoration: InputDecoration(
                        hintText: "e.g., CSE, Mechanical (Leave blank for all)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close the modal
                        _loadProfiles(); // Reload the deck with the new filters!
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16)
                      ),
                      child: const Text("Apply Filters", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  // --- NEW HELPER FUNCTION ---
  void _recordAndShowSnackbar(String targetUserId, bool isRightSwipe) {
    _vibeService.recordSwipe(
        targetUserId: targetUserId,
        isRightSwipe: isRightSwipe
    );

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isRightSwipe ? "Vibe Checked! ✨" : "Passed"),
        backgroundColor: isRightSwipe ? Colors.pinkAccent : Colors.grey,
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  // --- UPDATED ONSWIPE ---
  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    try {
      final targetUser = _profiles[previousIndex];
      final isRightSwipe = direction == CardSwiperDirection.right;

      // 🛡️ BULLETPROOF DATA EXTRACTION 🛡️
      List<dynamic> customQuiz = [];
      final rawQuizData = targetUser['vibe_quizzes'];

      if (rawQuizData != null) {
        Map<String, dynamic>? quizMap;

        if (rawQuizData is List && rawQuizData.isNotEmpty) {
          quizMap = rawQuizData.first as Map<String, dynamic>;
        } else if (rawQuizData is Map<String, dynamic>) {
          quizMap = rawQuizData;
        }

        if (quizMap != null && quizMap['custom_quiz'] != null) {
          if (quizMap['custom_quiz'] is List) {
            customQuiz = quizMap['custom_quiz'];
          }
        }
      }

      // 🚨 THE DEBUGGER - CHECK YOUR FLUTTER CONSOLE 🚨
      if (isRightSwipe) {
        print("======== SWIPE DEBUGGER ========");
        print("Swiping Right on: ${targetUser['full_name']}");
        print("Does this person have a quiz?: ${customQuiz.isNotEmpty ? 'YES!' : 'NO :('}");
        print("================================");
      }

      // INTERCEPT LOGIC: If they swiped right AND there is a valid quiz
      if (isRightSwipe && customQuiz.isNotEmpty) {
        _showQuizPrompt(targetUser, customQuiz);
        return true;
      }

      // If no quiz, or if it was a left swipe, handle it normally
      _recordAndShowSnackbar(targetUser['id'], isRightSwipe);
      return true;

    } catch (e) {
      print("🚨 SWIPE ERROR PREVENTED: $e");
      return true;
    }
  }

  // --- THE NEW DIALOG FLOW YOU REQUESTED ---
  Future<void> _showQuizPrompt(dynamic targetUser, List<dynamic> customQuiz) async {
    // Add a tiny delay so the user sees the card fly off the screen first
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // Show the Dialog Box
    final wantsToTakeQuiz = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Forces them to click a button
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Vibe Check Required! 🎯", textAlign: TextAlign.center, style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        content: Text("${targetUser['full_name'] ?? 'This user'} requires you to pass their custom quiz to send a match request. Are you ready?", textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // They clicked Back/Cancel
            child: const Text("Nevermind", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // They clicked Take Quiz
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white),
            child: const Text("Take Quiz", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (wantsToTakeQuiz == true) {
      // Open the quiz screen
      if (!mounted) return;
      final passed = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TakeQuizScreen(
            targetName: targetUser['full_name'] ?? 'Student',
            targetAvatarUrl: targetUser['avatar_url'],
            quizData: customQuiz,
          ),
        ),
      );

      // Check the results of the quiz
      if (passed == true) {
        _recordAndShowSnackbar(targetUser['id'], true);
      } else {
        // They failed OR they hit the back button on the Quiz Screen
        _swiperController.undo();
      }
    } else {
      // They clicked "Nevermind" on the dialog box
      _swiperController.undo();
    }
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
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterModal,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
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
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("No new profiles match your filters.", style: TextStyle(fontSize: 18)),
                      if (_vibeService.lastFetchError != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          "Error: ${_vibeService.lastFetchError}",
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadProfiles,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
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

  // --- NEW: Helper to draw the little pill-shaped tags for Green/Red flags ---
  Widget _buildFlagChip(String text, bool isGreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isGreen ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isGreen ? Colors.greenAccent : Colors.redAccent, width: 0.5),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  // --- NEW: The upgraded Full-Bleed UI for the Tinder-style card! ---
  Widget _buildProfileCard(dynamic profile) {
    // 1. Extract Base Profile Data
    final String? avatarUrl = profile['avatar_url'];
    final bool hasValidImage = avatarUrl != null && avatarUrl.trim().isNotEmpty;

    final String fullName = profile['full_name'] ?? 'Unknown';
    final String year = profile['academic_year'] ?? 'VIT';
    final String branch = profile['branch'] ?? 'Student';
    final String div = profile['division'] ?? '-';

    // Extract swipe status: 'RIGHT', 'LEFT', or null
    final String? swipeStatus = profile['swipe_status'];

    // 2. 🛡️ SAFE DATA EXTRACTION (Handles both List and Map types)
    Map<String, dynamic>? vibeData;
    final rawVibeData = profile['vibe_quizzes'];

    if (rawVibeData != null) {
      if (rawVibeData is List && rawVibeData.isNotEmpty) {
        vibeData = rawVibeData.first as Map<String, dynamic>;
      } else if (rawVibeData is Map<String, dynamic>) {
        vibeData = rawVibeData;
      }
    }

    final String bio = vibeData?['bio'] ?? '';
    final String rawGreenFlags = vibeData?['green_flags'] ?? '';
    final String rawRedFlags = vibeData?['red_flags'] ?? '';

    List<String> greenFlags = rawGreenFlags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    List<String> redFlags = rawRedFlags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    // 3. Build the Full-Bleed Card
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 3, blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // LAYER 1: Background Color (If image is loading or broken)
            Container(color: const Color(0xFF1E1E2C)),

            // LAYER 2: The Full Bleed Image
            if (hasValidImage)
              Positioned.fill(
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF1E1E2C)),
                ),
              ),

            // Fallback icon if no image
            if (!hasValidImage)
              const Center(child: Icon(Icons.person, size: 120, color: Colors.white12)),

            // LAYER 3: Translucent Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),

            // LAYER 4: The Profile Details
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(fullName, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.school, size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text("$year • $branch • Div $div", style: const TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (bio.isNotEmpty) ...[
                    Text(
                        '"$bio"',
                        style: const TextStyle(fontSize: 15, color: Colors.white, fontStyle: FontStyle.italic),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (greenFlags.isNotEmpty || redFlags.isNotEmpty)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        ...greenFlags.map((flag) => _buildFlagChip(flag, true)),
                        ...redFlags.map((flag) => _buildFlagChip(flag, false)),
                      ],
                    ),
                ],
              ),
            ),

            // LAYER 5: Swipe Status Badge (top-right corner)
            if (swipeStatus != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: swipeStatus == 'RIGHT'
                        ? Colors.pinkAccent.withOpacity(0.85)
                        : Colors.grey[800]!.withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    swipeStatus == 'RIGHT' ? Icons.favorite_rounded : Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}