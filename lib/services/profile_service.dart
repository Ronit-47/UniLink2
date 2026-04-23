
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final supabase = Supabase.instance.client;

  // 1. Fetch current user profile data
  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      print("Error fetching profile: $e");
      return null;
    }
  }

  // 2. Update profile (including image upload)
  Future<String?> updateProfile({
    required String fullName,
    required String branch,
    required String academicYear,
    required String division,
    File? imageFile,
  }) async {
    try {
      final user = supabase.auth.currentUser!; // Get the logged-in user
      final userId = user.id;
      final userEmail = user.email; // <--- GRAB THE EMAIL HERE

      String? avatarUrl;

      if (imageFile != null) {
        final fileExt = imageFile.path.split('.').last;
        final fileName = '$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        await supabase.storage.from('avatars').upload(fileName, imageFile);
        avatarUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      final updates = {
        'id': userId,
        'full_name': fullName,
        'branch': branch,
        'academic_year': academicYear,
        'division': division,
        'college_email': userEmail, // <--- ADD THIS LINE TO FIX THE ERROR
      };

      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await supabase.from('profiles').upsert(updates);
      return null;
    } catch (e) {
      return e.toString();
    }
  }}