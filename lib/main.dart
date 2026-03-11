import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️ PASTE YOUR KEYS FROM NOTEPAD HERE ⚠️
  await Supabase.initialize(
    url: 'https://llhmiwocpuptnbsmyjzk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxsaG1pd29jcHVwdG5ic215anprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyMDU3NjUsImV4cCI6MjA4ODc4MTc2NX0.tmZ09B6p46twgAHwNYt_akV-VR5_MWpsQCEqhuxQWzY',
  );

  runApp(const UniLinkApp());
}

class UniLinkApp extends StatelessWidget {
  const UniLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UniLink',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
      // THE GATEKEEPER: Checks session on startup
      home: Supabase.instance.client.auth.currentSession == null
          ? const LoginPage()
          : const HomePage(),
    );
  }
}