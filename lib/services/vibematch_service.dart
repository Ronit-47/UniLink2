import 'package:supabase_flutter/supabase_flutter.dart';

class VibeMatchService {
  final supabase = Supabase.instance.client;

  // ==========================================
  // 1. FETCH POTENTIAL MATCHES (WITH ADVANCED FILTERS)
  // ==========================================
  Future<List<dynamic>> fetchPotentialRoommates({
    String? yearFilter,
    String? branchFilter,
  }) async {
    try {
      final myId = supabase.auth.currentUser!.id;

      // Start the base query: Fetch everyone EXCEPT the logged-in user
      // We also use a join to fetch their quiz data at the same time!
      var query = supabase
          .from('profiles')
          .select('*, vibe_quizzes(*)')
          .neq('id', myId);

      // Apply Year Filter (if they selected something other than 'All')
      if (yearFilter != null && yearFilter != 'All') {
        query = query.eq('academic_year', yearFilter);
      }

      // Apply Branch Filter (if they typed something in the search box)
      if (branchFilter != null && branchFilter.isNotEmpty) {
        // .ilike makes the search case-insensitive (e.g. 'cse' matches 'CSE')
        query = query.ilike('branch', '%$branchFilter%');
      }

      final response = await query;
      return response as List<dynamic>;
    } catch (e) {
      print("Fetch error: $e");
      return [];
    }
  }

  // ==========================================
  // 2. RECORD A SWIPE
  // ==========================================
  Future<void> recordSwipe(
      {required String targetUserId, required bool isRightSwipe}) async {
    try {
      final myId = supabase.auth.currentUser!.id;

      await supabase.from('swipes').insert({
        'swiper_id': myId,
        'swiped_id': targetUserId,
        'direction': isRightSwipe ? 'RIGHT' : 'LEFT',
      });

      print("Swiped ${isRightSwipe ? 'RIGHT' : 'LEFT'} on user: $targetUserId");
    } catch (e) {
      print("Error recording swipe: $e");
    }
  }

  // ==========================================
  // 3. SAVE VIBE PROFILE (NOW WITH CUSTOM QUIZ & UPSERT FIX!)
  // ==========================================
  Future<String?> saveVibeProfile({
    required String bio,
    required String lookingFor,
    required String redFlags,
    required String greenFlags,
    required String academicYear,
    required String branch,
    required String division,
    required dynamic imageFile,
    List<Map<String, dynamic>>? customQuiz,
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      String? uploadedImageUrl;

      // STEP A: Upload Avatar if provided
      if (imageFile != null) {
        final fileExt = imageFile.path.split('.').last;
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        await supabase.storage.from('avatars').upload(fileName, imageFile);
        uploadedImageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      // STEP B: Update (or Create!) the main structured profile
      final profileUpdates = {
        'id': userId, // <-- CRITICAL FIX: Ensure the ID is passed so it can be created if missing
        'academic_year': academicYear,
        'branch': branch.trim(),
        'division': division.trim(),
      };

      if (uploadedImageUrl != null) {
        profileUpdates['avatar_url'] = uploadedImageUrl;
      }

      // <-- CRITICAL FIX: Changed from .update() to .upsert()
      await supabase.from('profiles').upsert(profileUpdates);

      // STEP C: Save the Vibe Quiz & Custom Quiz
      await supabase.from('vibe_quizzes').upsert({
        'user_id': userId,
        'bio': bio.trim(),
        'looking_for': lookingFor,
        'red_flags': redFlags.trim(),
        'green_flags': greenFlags.trim(),
        'custom_quiz': customQuiz ?? [],
      }, onConflict: 'user_id');

      return null; // Success!
    } catch (e) {
      return "Error saving profile: $e";
    }
  }
}