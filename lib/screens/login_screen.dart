import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  // --- STANDARD PASSWORD LOGIN ---
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter both email and password.", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final error = await _authService.loginWithPassword(
      email: email,
      password: password,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        _showError(error, Colors.redAccent);
      }
      // If successful, the Gatekeeper in main.dart takes over and routes to HomeScreen!
    }
  }

  // --- FORGOT PASSWORD / OTP LOGIN ---
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError("Please enter your college email first to receive a login code.", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final error = await _authService.sendOTP(email);

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        _showError(error, Colors.redAccent);
      } else {
        _showOTPDialog(email);
      }
    }
  }

  // Pops up when they request a login code
  void _showOTPDialog(String email) {
    final otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Enter Login Code 🔐", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF2E3192), fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("We sent a 6-digit code to $email", textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isVerifying ? null : () async {
                    if (otpController.text.length != 6) return;

                    setDialogState(() => isVerifying = true);
                    final error = await _authService.verifyOTP(email, otpController.text);

                    if (mounted) {
                      if (error != null) {
                        setDialogState(() => isVerifying = false);
                        _showError(error, Colors.redAccent);
                      } else {
                        Navigator.pop(context); // Close dialog, Gatekeeper routes to Home!
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3192), foregroundColor: Colors.white),
                  child: isVerifying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Verify & Login"),
                ),
              ],
            );
          }
      ),
    );
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
      body: SafeArea(
        child: Center( // Center helps on larger screens
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "UniLink",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Color(0xFF2E3192), letterSpacing: -1),
                ),
                const SizedBox(height: 8),
                const Text(
                  "The Zero-Trust Campus Network",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 50),

                // EMAIL FIELD
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "College Email Address",
                    hintText: "e.g. student@vit.edu",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.school_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // PASSWORD FIELD
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),

                // FORGOT PASSWORD BUTTON
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleForgotPassword,
                    child: const Text("Forgot Password? Login with Code", style: TextStyle(color: Color(0xFF2E3192), fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),

                // LOGIN BUTTON
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E3192),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 32),

                // SIGN UP NAVIGATION
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?", style: TextStyle(color: Colors.grey, fontSize: 15)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupScreen()),
                        );
                      },
                      child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E3192))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}