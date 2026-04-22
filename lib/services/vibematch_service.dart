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
  Future<void> recordSwipe({required String targetUserId, required bool isRightSwipe}) async {
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
  // 3. SAVE VIBE PROFILE (GOOGLE FORM QUIZ DATA)
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
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      String? uploadedImageUrl;

      // STEP A: If they selected an image, upload it to the 'avatars' Storage bucket
      if (imageFile != null) {
        final fileExt = imageFile.path.split('.').last;
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        await supabase.storage.from('avatars').upload(fileName, imageFile);
        uploadedImageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      // STEP B: Update their main structured profile
      final profileUpdates = {
        'academic_year': academicYear,
        'branch': branch.trim(),
        'division': division.trim(),
      };

      // Only overwrite the avatar URL if they actually uploaded a new picture
      if (uploadedImageUrl != null) {
        profileUpdates['avatar_url'] = uploadedImageUrl;
      }

      await supabase.from('profiles').update(profileUpdates).eq('id', userId);

      // STEP C: Upsert their roommate quiz preferences
      // Note the crucial onConflict: 'user_id' to prevent duplicate key database crashes
      await supabase.from('vibe_quizzes').upsert({
        'user_id': userId,
        'bio': bio.trim(),
        'looking_for': lookingFor,
        'red_flags': redFlags.trim(),
        'green_flags': greenFlags.trim(),
      }, onConflict: 'user_id');

      return null; // Success!
    } catch (e) {
      return "Error saving profile: $e";
    }
  }
}