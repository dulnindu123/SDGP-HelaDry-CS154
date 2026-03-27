import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app/app_config.dart';

class DeviceSetupService {
  static Future<void> registerDeviceWithBackend(
      String receivedIdFromBluetooth) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await user.getIdToken(true);
      final baseUrl = AppConfig.baseUrl;

      final response = await http.post(
        Uri.parse('$baseUrl/device/register'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "device_id": receivedIdFromBluetooth,
          "device_name": "My HelaDry Device",
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint(
            "Registration Successful: Device $receivedIdFromBluetooth is now linked.");
      } else {
        debugPrint("Registration Failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error registering device: $e");
    }
  }
}
