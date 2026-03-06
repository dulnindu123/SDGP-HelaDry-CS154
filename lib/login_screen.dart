import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;

  // Finalized Logic for Firebase
  Future<void> _processAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Basic human-written validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        // checks the boolean for true, if false user need to Signup
        await _authService.signIn(
          // since talking to databse takes time,
          email, // await tells wait for response.
          password, // trim to remove accidental spaces.
        );
      } else {
        await _authService.signUp(email, password);
      }

      if (!mounted) return;

      // Navigate to Dashboard on success removing the previous screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (exception) {
      // Show user-friendly error
      ScaffoldMessenger.of(
        context, // the map tells flutter, where widget sits in app tree.
      ).showSnackBar(
        SnackBar(
          content: Text("Auth Error: ${exception.toString()}"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The Scaffold provides the basic visual structure for this screen,
      backgroundColor: const Color(0xFFF7FFF9), // Very light mint green
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Updated Branding for HelaDry
              const Icon(Icons.wb_sunny, size: 70, color: Colors.green),
              const SizedBox(height: 10),
              const Text(
                "HelaDry",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Loading Spinner or Button
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.green)
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors
                              .green
                              .shade600, // Slightly lighter than 700
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _processAuth,
                        child: Text(_isLoginMode ? "Login" : "Create Account"),
                      ),
                    ),

              TextButton(
                onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                child: Text(
                  _isLoginMode ? "New here? Join us" : "Back to Login",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
