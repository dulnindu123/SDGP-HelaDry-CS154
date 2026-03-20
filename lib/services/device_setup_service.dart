import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceSetupService {
  //  Flask server IP
  static const String baseUrl = 'http://192.168.1.101:5000/';

  static Future<void> registerDeviceWithBackend(String receivedIdFromBluetooth) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await user.getIdToken(true);

      final response = await http.post(
        Uri.parse('${baseUrl}device/register'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "device_id": receivedIdFromBluetooth,
          "device_name": "My HelaDry Device", // Optional name
        }),
      );

      if (response.statusCode == 201) {
        print("Registration Successful: Device $receivedIdFromBluetooth is now linked to your account.");
      } else {
        print("Registration Failed: ${response.body}");
      }
    } catch (e) {
      print("Error registering device: $e");
    }
  }
}