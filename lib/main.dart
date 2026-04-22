import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to your specific database
  await Supabase.initialize(
    url: 'https://nmahirxmkbkktinjkdxa.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5tYWhpcnhta2Jra3RpbmprZHhhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2Nzc4NDgsImV4cCI6MjA4ODI1Mzg0OH0.kN8jxCO0Csfc6-jYi1sBUpefr1d-a3MIdtJR5rd40as',
  );

  runApp(const UniLinkApp());
}

class UniLinkApp extends StatelessWidget {
  const UniLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // We will use Google Fonts to make the app look premium instantly
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AuthGatekeeper(),
    );
  }
}

// The Gatekeeper: Checks if a user is logged in
class AuthGatekeeper extends StatelessWidget {
  const AuthGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session;

        if (session != null) {
          // User is logged in! Go to the main dashboard.
          return const HomeScreen();
        } else {
          // User is NOT logged in. Go to Login Screen.
          // User is NOT logged in. Go to Login Screen.
          return const LoginScreen();
        }
      },
    );
  }
}