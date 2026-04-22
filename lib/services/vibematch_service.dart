import 'package:supabase_flutter/supabase_flutter.dart';

class VibeMatchService {
  // THIS is the line that was missing! It connects the service to your DB.
  final supabase = Supabase.instance.client;

  // 1. FETCH POTENTIAL MATCHES
  Future<List<dynamic>> fetchPotentialRoommates() async {
    try {
      final myId = supabase.auth.currentUser!.id;

      // Get everyone from the profiles table WHERE their ID is NOT equal to my ID
      final response = await supabase
          .from('profiles')
          .select('*')
          .neq('id', myId);

      return response as List<dynamic>;
    } catch (e) {
      print("Fetch error: $e");
      return [];
    }
  }

  // 2. RECORD A SWIPE (Placeholder for the matching algorithm)
  Future<void> recordSwipe({required String targetUserId, required bool isRightSwipe}) async {
    print("Swiped ${isRightSwipe ? 'RIGHT' : 'LEFT'} on user: $targetUserId");
  }

  // 3. SAVE OR UPDATE VIBE PROFILE (NOW WITH IMAGE & ACADEMIC INFO)
  Future<String?> saveVibeProfile({
    required String bio,
    required String lookingFor,
    required String redFlags,
    required String greenFlags,
    required String academicYear,
    required String branch,
    required String division,
    required dynamic imageFile, // We pass the image file here
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      String? uploadedImageUrl;

      // STEP A: If they selected an image, upload it to Storage
      if (imageFile != null) {
        final fileExt = imageFile.path.split('.').last;
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        await supabase.storage.from('avatars').upload(fileName, imageFile);
        uploadedImageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      // STEP B: Update their main profile with the new info & photo URL
      final profileUpdates = {
        'bio': bio.trim(),
        'academic_year': academicYear,
        'branch': branch.trim(),
        'division': division.trim(),
      };

      // Only update the avatar URL if they actually uploaded a new picture
      if (uploadedImageUrl != null) {
        profileUpdates['avatar_url'] = uploadedImageUrl;
      }

      await supabase.from('profiles').update(profileUpdates).eq('id', userId);

      // STEP C: Upsert their roommate preferences
      await supabase.from('vibe_quizzes').upsert({
        'user_id': userId,
        'looking_for': lookingFor,
        'red_flags': redFlags.trim(),
        'green_flags': greenFlags.trim(),
      },onConflict: 'user_id');

      return null; // Success!
    } catch (e) {
      return "Error saving profile: $e";
    }
  }
}