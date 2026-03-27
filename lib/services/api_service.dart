import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../app/app_config.dart';

class ApiService {
  String _baseUrl = AppConfig.baseUrl;
  String get baseUrl => _baseUrl;

  void setBaseUrl(String ip) {
    if (ip.isEmpty) return;
    String cleanIp = ip.trim();
    // Strip trailing slashes to avoid double slashes in API calls
    while (cleanIp.endsWith('/')) {
      cleanIp = cleanIp.substring(0, cleanIp.length - 1);
    }
    
    if (!cleanIp.startsWith("http")) {
      // Default to http for local/private IPs, otherwise https
      if (cleanIp.startsWith("192.168.") || 
          cleanIp.startsWith("10.") || 
          cleanIp.startsWith("172.") || 
          cleanIp.startsWith("localhost")) {
        cleanIp = "http://$cleanIp";
      } else {
        cleanIp = "https://$cleanIp";
      }
    }
    
    // Append :5000 if no port is specified and it's not a production (Render) URL
    if (!cleanIp.contains(".onrender.com") && !RegExp(r':\d+').hasMatch(cleanIp)) {
      cleanIp = "$cleanIp:5000";
    }
    
    _baseUrl = cleanIp;
    debugPrint("ApiService: Base URL updated to $_baseUrl");
  }

  Future<void> checkServerStatus() async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/"));
      if (response.statusCode == 200) {
        debugPrint("✅ Success: ${response.body}");
      } else {
        debugPrint(
            "⚠️ Server reached, but returned error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Connection failed: $e");
      debugPrint(
          "Please check your internet connection and verify the backend URL: $_baseUrl");
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    // This pulls the unique ID Token from the user who logged in on your Login Page
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken(true);

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> registerDevice(String macId, String name) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/device/register'),
      headers: await _getAuthHeaders(),
      body: jsonEncode({'device_id': macId, 'device_name': name}),
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to connect to backend: ${response.body}");
    }
  }

  Future<void> startSession(Map<String, dynamic> payload) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/device/start'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(payload),
      );
    } catch (e) {
      debugPrint("API Start Session Error: $e");
    }
  }

  Future<void> stopSession(String deviceId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/device/stop'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({'device_id': deviceId}),
      );
    } catch (e) {
      debugPrint("API Stop Session Error: $e");
    }
  }

  Future<void> updateTemperature(String deviceId, double temp) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/device/update-temperature'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({'device_id': deviceId, 'temperature': temp}),
      );
    } catch (e) {
      debugPrint("API Update Temp Error: $e");
    }
  }

  Future<void> updateFanSpeed(String deviceId, int speed) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/device/update-fan-speed'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({'device_id': deviceId, 'fan_speed': speed}),
      );
    } catch (e) {
      debugPrint("API Update Fan Error: $e");
    }
  }

  Future<void> toggleHeater(String deviceId, bool state) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/device/toggle-heater'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(
            {'device_id': deviceId, 'heater_state': state ? 'ON' : 'OFF'}),
      );
    } catch (e) {
      debugPrint("API Toggle Heater Error: $e");
    }
  }

  Future<void> emergencyStop(String deviceId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/device/emergency-stop'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({'device_id': deviceId}),
      );
    } catch (e) {
      debugPrint("API Emergency Stop Error: $e");
    }
  }

  Future<List<dynamic>> fetchMyRecords() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/session/my-sessions'),
        headers: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      debugPrint("API Fetch Records Error: $e");
    }
    return [];
  }
}
