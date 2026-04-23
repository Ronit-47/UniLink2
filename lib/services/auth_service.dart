import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // The strict list of allowed domains based on your project spec
  final List<String> allowedDomains = [
    'vit.edu',
    'mitwpu.edu.in',
    'coep.ac.in',
    'pict.edu',
    'bvucoep.edu.in'
  ];

  // ==========================================
  // SIGN UP FLOW (Password + OTP Verification)
  // ==========================================

  /// SIGNUP STEP 1: Register email/password, bundle profile data, and trigger the OTP email
  Future<String?> signUpWithOTP({
    required String email,
    required String password,
    required String fullName,
    required String year,
    required String branch,
  }) async {
    try {
      final domain = email.trim().split('@').last;

      // Zero-Trust Domain Check
      if (!allowedDomains.contains(domain)) {
        return "Access Denied: Please use a verified college email address.";
      }

      // This creates the user, sends the 6-digit code, AND bundles the data
      // so your SQL trigger can instantly build the profile row!
      await supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'academic_year': year,
          'branch': branch.trim(),
        },
      );

      return null; // Success! OTP sent.
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Signup failed: ${e.toString()}";
    }
  }

  /// SIGNUP STEP 2: Verify the code and classify their college
  Future<String?> verifySignupOTP({
    required String email,
    required String code,
  }) async {
    try {
      final response = await supabase.auth.verifyOTP(
        type: OtpType.signup, // Specific type for new account verification
        email: email.trim(),
        token: code.trim(),
      );

      if (response.user != null) {
        // Automatically classify the user into their college based on domain
        await _classifyAndSetupUser(response.user!.id, email.trim());
        return null; // Success! Fully verified and profiled.
      }
      return "Invalid verification code.";
    } catch (e) {
      return "Verification failed: ${e.toString()}";
    }
  }

  // ==========================================
  // LOGIN FLOWS
  // ==========================================

  /// LOGIN WAY 1: Standard Password Login (For returning users who already signed up)
  Future<String?> loginWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return null; // Success!
    } on AuthException catch (e) {
      return e.message; // E.g., "Invalid login credentials"
    } catch (e) {
      return "Login failed: ${e.toString()}";
    }
  }

  /// LOGIN WAY 2: Passwordless OTP Login (If they forgot their password)
  Future<String?> sendOTP(String email) async {
    try {
      final domain = email.trim().split('@').last;

      if (!allowedDomains.contains(domain)) {
        return "Access Denied: Please use a verified college email address.";
      }

      await supabase.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: false, // Set to false so it ONLY logs in existing users
      );

      return null;
    } catch (e) {
      return "Failed to send code: ${e.toString()}";
    }
  }

  /// LOGIN WAY 2 STEP 2: Verify passwordless login code
  Future<String?> verifyOTP(String email, String code) async {
    try {
      final response = await supabase.auth.verifyOTP(
        type: OtpType.magiclink, // Standard login type
        email: email.trim(),
        token: code.trim(),
      );

      if (response.user != null) {
        return null; // Success!
      }
      return "Invalid verification code.";
    } catch (e) {
      return "Verification failed: ${e.toString()}";
    }
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Automatically classify the user by their email domain and save to DB
  Future<void> _classifyAndSetupUser(String userId, String email) async {
    try {
      final domain = email.split('@').last;

      // Fetch the college_id from our master colleges table
      final collegeData = await supabase
          .from('colleges')
          .select('id')
          .eq('email_domain', domain)
          .maybeSingle();

      if (collegeData != null) {
        final int collegeId = collegeData['id'];

        // Because the SQL Trigger already created the profile row with their
        // Name, Year, and Branch, we just UPDATE the row with their mapped college_id.
        await supabase.from('profiles').update({
          'college_id': collegeId,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      }
    } catch (e) {
      print("Classification error: $e");
    }
  }

  /// Logout function
  Future<void> logout() async {
    await supabase.auth.signOut();
  }
}