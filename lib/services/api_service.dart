import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // 10.0.2.2 is a special alias for your computer's 'localhost' inside the Android Emulator.
  // If using a real device, replace this with your computer's IP (e.g., 192.168.1.5).
  final String baseUrl = "http://192.168.1.4:5000";

  Future<void> checkServerStatus() async {
  try {
    // Using the IP address from your Flask terminal
    final response = await http.get(Uri.parse("http://192.168.1.4:5000/"));

    if (response.statusCode == 200) {
      print("✅ Success: ${response.body}");
    } else {
      print("⚠️ Server reached, but returned error: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Connection failed: $e");
    print("Check if your phone/emulator is on the same WiFi as 192.168.1.4");
  }
}

  Future<Map<String, String>> _getAuthHeaders() async {
    // This pulls the unique ID Token from the user who logged in on your Login Page
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Example: Registering a device via your device_bp
  Future<void> registerDevice(String macId, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/device/register'),
      headers: await _getAuthHeaders(),
      body: jsonEncode({'device_id': macId, 'name': name}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to connect to backend: ${response.body}");
    }
  }
}


