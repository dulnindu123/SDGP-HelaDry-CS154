import 'package:flutter/material.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();

  // Controllers to grab the text from the input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Boolean to toggle between Login and Signup view
  bool _isLogin = true;

  void _submitForm() {
    // Just printing for now to make sure controllers are working
    print("User entered: ${_emailController.text}");

    // Need to add validation and loading spinner here later
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HelaDry - Auth"), centerTitle: true),
      body: SingleChildScrollView(
        // Added this to prevent keyboard overflow issues
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 50.0),
        child: Column(
          children: [
            // Placeholder for Logo
            const Icon(Icons.lock_person, size: 60),
            const SizedBox(height: 20),

            const Text(
              "Account Access",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),

            // Email Input
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "EmailId",
                hintText: "example@mail.com",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // Password Input
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // Main Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                child: Text(_isLogin ? "Login" : "Sign Up"),
              ),
            ),

            // Toggle between Login/Signup
            TextButton(
              onPressed: () {
                setState(() => _isLogin = !_isLogin);
              },
              child: Text(
                _isLogin
                    ? "Don't have an account? Register"
                    : "Already registered? Login here",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
