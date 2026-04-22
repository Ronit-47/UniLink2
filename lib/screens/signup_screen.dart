import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  final _authService = AuthService();

  bool _isLoading = false;
  bool _otpPhase = false; // Toggles between the Signup form and the OTP input

  Future<void> _handleRequestOTP() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Please fill all fields", Colors.orange);
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError("Password must be at least 6 characters", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    // Call the AuthService to create the account and send the OTP
    final error = await _authService.signUpWithOTP(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        _showError(error, Colors.red);
      } else {
        // Success! Switch the UI to ask for the code
        setState(() => _otpPhase = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Code sent! Check your student email."), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _handleVerifyOTP() async {
    if (_otpController.text.length != 6) {
      _showError("Please enter the 6-digit code", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    // Verify the OTP and save their profile data
    final error = await _authService.verifySignupOTP(
      email: _emailController.text,
      code: _otpController.text,
      fullName: _nameController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        _showError(error, Colors.red);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Welcome to UniLink! \u2728"), backgroundColor: Colors.indigo),
        );
        // The Gatekeeper in main.dart will automatically detect the login and route to HomeScreen!
        Navigator.pop(context);
      }
    }
  }

  void _showError(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.indigo),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Join UniLink",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 8),
              const Text("The Zero-Trust Campus Network.", style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 32),

              // UI PHASE 1: DETAILS & PASSWORD
              if (!_otpPhase) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "College Email",
                    hintText: "e.g. @vit.edu, @coep.ac.in",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password (Min 6 chars)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRequestOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Continue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],

              // UI PHASE 2: ENTER OTP
              if (_otpPhase) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    "We sent a 6-digit code to ${_emailController.text}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: "", // Hides the '0/6' character counter
                    labelText: "Enter 6-Digit Code",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Verify & Create Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() { _otpPhase = false; _otpController.clear(); }),
                  child: const Text("Go back & edit details"),
                )
              ],
            ],
          ),
        ),
      ),
    );
  }
}