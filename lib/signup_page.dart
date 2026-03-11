import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController branchController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _signUpUser() async {
    // 1. Check if any fields are empty first
    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in the required fields"), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      // 2. Create the user in the secure Auth system
      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final User? user = res.user;

      if (user != null) {
        // 3. Insert the extra data into your custom 'profiles' table
        await Supabase.instance.client.from('profiles').insert({
          'id': user.id,
          'full_name': nameController.text.trim(),
          'branch': branchController.text.trim(),
          'college_year': yearController.text.trim(),
          'email': emailController.text.trim(), // Adding the email column we created in Step 2.5
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created! Please log in."), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Go back to the login screen
        }
      }
    } on AuthException catch (e) {
      // THIS catches specific Supabase errors so it doesn't fail silently
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup Failed: ${e.message}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unexpected Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Create an Account", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Full Name *"),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: branchController,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Branch (e.g. Computer Engineering)"),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: yearController,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Year (e.g. Second Year)"),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Email *"),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Password (min 6 chars) *"),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _signUpUser,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("Sign Up"),
              ),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}