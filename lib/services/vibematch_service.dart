import 'package:supabase_flutter/supabase_flutter.dart';

class VibeMatchService {
  final supabase = Supabase.instance.client;

  // Store the last error so the UI can display it for debugging
  String? lastFetchError;

  // ==========================================
  // 1. FETCH POTENTIAL MATCHES
  // ==========================================
  Future<List<dynamic>> fetchPotentialRoommates({
    String? yearFilter,
    String? branchFilter,
  }) async {
    lastFetchError = null;
    try {
      final myId = supabase.auth.currentUser!.id;
      print("🔍 DEBUG VIBEMATCH: Starting fetch for user $myId");

      // --- Step 1: Fetch the user's swipe history (direction per swiped_id) ---
      final swipedResponse = await supabase
          .from('swipes')
          .select('swiped_id, direction')
          .eq('swiper_id', myId);

      final Map<String, String> swipeMap = {};
      for (final row in (swipedResponse as List)) {
        swipeMap[row['swiped_id'].toString()] = row['direction'].toString();
      }

      print("🛑 DEBUG VIBEMATCH: Found ${swipeMap.length} previous swipes.");

      // --- Step 2: Fetch ALL profiles (no exclusions) ---
      var query = supabase
          .from('profiles')
          .select()
          .neq('id', myId);

      if (yearFilter != null && yearFilter != 'All') {
        query = query.eq('academic_year', yearFilter);
      }

      if (branchFilter != null && branchFilter.isNotEmpty) {
        query = query.ilike('branch', '%$branchFilter%');
      }

      final List<dynamic> profiles = await query;
      print("✅ DEBUG VIBEMATCH: Fetched ${profiles.length} profiles.");

      if (profiles.isEmpty) return [];

      // --- Step 3: Attach swipe status to each profile ---
      for (final profile in profiles) {
        final id = profile['id'].toString();
        // 'RIGHT', 'LEFT', or null (never swiped)
        profile['swipe_status'] = swipeMap[id];
      }

      // --- Step 4: Fetch all vibe_quizzes separately and merge ---
      try {
        final profileIds = profiles.map((p) => p['id'].toString()).toList();
        final vibeResponse = await supabase
            .from('vibe_quizzes')
            .select()
            .inFilter('user_id', profileIds);

        final Map<String, dynamic> vibeMap = {};
        for (final vibe in (vibeResponse as List)) {
          vibeMap[vibe['user_id'].toString()] = vibe;
        }

        for (final profile in profiles) {
          final id = profile['id'].toString();
          profile['vibe_quizzes'] = vibeMap.containsKey(id) ? vibeMap[id] : null;
        }

        print("✅ DEBUG VIBEMATCH: Merged vibe data for ${vibeMap.length} users.");
      } catch (vibeError) {
        print("⚠️ DEBUG VIBEMATCH: Could not fetch vibe_quizzes (non-fatal): $vibeError");
        for (final profile in profiles) {
          profile['vibe_quizzes'] = null;
        }
      }

      return profiles;

    } catch (e) {
      lastFetchError = e.toString();
      print("❌ DEBUG VIBEMATCH FETCH ERROR: $e");
      return [];
    }
  }

  // ==========================================
  // 2. RECORD A SWIPE + SEND NOTIFICATION
  // ==========================================
  Future<void> recordSwipe({
    required String targetUserId,
    required bool isRightSwipe,
  }) async {
    try {
      final myId = supabase.auth.currentUser!.id;

      await supabase.from('swipes').upsert({
        'swiper_id': myId,
        'swiped_id': targetUserId,
        'direction': isRightSwipe ? 'RIGHT' : 'LEFT',
      }, onConflict: 'swiper_id, swiped_id');

      print("👉 Swiped ${isRightSwipe ? 'RIGHT' : 'LEFT'} on user: $targetUserId");

      // Send a notification to the target user on RIGHT swipe
      if (isRightSwipe) {
        try {
          await supabase.from('notifications').upsert({
            'user_id': targetUserId,
            'sender_id': myId,
            'type': 'vibe_check',
            'quiz_result': 'Vibe Checked ✨',
            'is_read': false,
          }, onConflict: 'user_id, sender_id');

          print("🔔 Notification sent to $targetUserId");
        } catch (notifError) {
          try {
            await supabase.from('notifications').insert({
              'user_id': targetUserId,
              'sender_id': myId,
              'type': 'vibe_check',
              'quiz_result': 'Vibe Checked ✨',
              'is_read': false,
            });
            print("🔔 Notification inserted for $targetUserId");
          } catch (insertError) {
            print("⚠️ Could not send notification: $insertError");
          }
        }
      }
    } catch (e) {
      print("❌ Error recording swipe: $e");
    }
  }

  // ==========================================
  // 3. SAVE VIBE PROFILE
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

      if (imageFile != null) {
        final fileExt = imageFile.path.split('.').last;
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        await supabase.storage.from('avatars').upload(fileName, imageFile);
        uploadedImageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      final profileUpdates = {
        'academic_year': academicYear,
        'branch': branch.trim(),
        'division': division.trim(),
      };

      if (uploadedImageUrl != null) {
        profileUpdates['avatar_url'] = uploadedImageUrl;
      }

      await supabase.from('profiles').update(profileUpdates).eq('id', userId);

      await supabase.from('vibe_quizzes').upsert({
        'user_id': userId,
        'bio': bio.trim(),
        'looking_for': lookingFor,
        'red_flags': redFlags.trim(),
        'green_flags': greenFlags.trim(),
        'custom_quiz': customQuiz ?? [],
      }, onConflict: 'user_id');

      return null;
    } catch (e) {
      return "Error saving profile: $e";
    }
  }
}