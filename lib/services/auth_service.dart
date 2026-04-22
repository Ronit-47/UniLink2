import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // 1. SIGN UP & DOMAIN RESTRICTION
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // THE BOUNCER: Reject non-college emails instantly
    if (!email.trim().toLowerCase().endsWith('@vit.edu')) {
      return "Access Denied: You must use a @vit.edu college email to join UniLink.";
    }

    try {
      // Create the user in the hidden Auth system
      final AuthResponse res = await supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );

      final user = res.user;
      if (user != null) {
        // If successful, insert their details into our new 'profiles' table
        await supabase.from('profiles').insert({
          'id': user.id, // This is the Foreign Key link!
          'full_name': fullName.trim(),
          'college_email': email.trim(),
        });
        return null; // Returning null means "No Errors / Success"
      }
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
    return "Unknown error";
  }

  // 2. LOG IN
  Future<String?> login({required String email, required String password}) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // Success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred.";
    }
  }

  // 3. LOG OUT
  Future<void> logout() async {
    await supabase.auth.signOut();
  }
}