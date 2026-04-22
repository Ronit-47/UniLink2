import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _otpSent = false; // Toggles the UI between Email phase and OTP phase

  Future<void> _handleSendOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError("Please enter a valid email address.");
      return;
    }

    setState(() => _isLoading = true);

    final error = await _authService.sendOTP(email);

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        _showError(error);
      } else {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("6-digit code sent to your email!"), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _handleVerifyOTP() async {
    final email = _emailController.text.trim();
    final code = _otpController.text.trim();

    if (code.length != 6) {
      _showError("Please enter the 6-digit code.");
      return;
    }

    setState(() => _isLoading = true);

    final error = await _authService.verifyOTP(email, code);

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        _showError(error);
      }
      // If error is null, successful login!
      // Your main.dart Auth Stream will automatically redirect the user to the HomeScreen.
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "UniLink",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF2E3192)),
              ),
              const SizedBox(height: 10),
              const Text(
                "The Zero-Trust Campus Network",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 50),

              // UI PHASE 1: Enter Email
              if (!_otpSent) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "College Email Address",
                    hintText: "e.g. student@vit.edu",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.school),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendOTP,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2E3192),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Send Verification Code", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],

              // UI PHASE 2: Enter OTP
              if (_otpSent) ...[
                Text(
                  "We sent a code to ${_emailController.text}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: "6-Digit Code",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyOTP,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Verify & Login", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => setState(() { _otpSent = false; _otpController.clear(); }),
                  child: const Text("Use a different email"),
                )
              ],
            ],
          ),
        ),
      ),
    );
  }
}