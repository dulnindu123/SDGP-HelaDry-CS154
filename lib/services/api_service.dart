import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  String _baseUrl = "http://172.30.161.140:5000";
  String get baseUrl => _baseUrl;

  void setBaseUrl(String ip) {
    if (ip.isEmpty) return;
    String cleanIp = ip.trim();
    if (!cleanIp.startsWith("http")) {
      cleanIp = "http://$cleanIp";
    }
    if (!cleanIp.contains(":5000")) {
      cleanIp = "$cleanIp:5000";
    }
    _baseUrl = cleanIp;
    print("ApiService: Base URL updated to $_baseUrl");
  }

  Future<void> checkServerStatus() async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/"));
      if (response.statusCode == 200) {
        print("✅ Success: ${response.body}");
      } else {
        print("⚠️ Server reached, but returned error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Connection failed: $e");
      print("Check if your phone/emulator is on the same WiFi as $_baseUrl");
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> registerDevice(String macId, String name) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/device/register'),
      headers: await _getAuthHeaders(),
      body: jsonEncode({'device_id': macId, 'name': name}),
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
      print("API Start Session Error: $e");
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
      print("API Stop Session Error: $e");
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
      print("API Update Temp Error: $e");
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
      print("API Update Fan Error: $e");
    }
  }

  Future<void> toggleHeater(String deviceId, bool state) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/device/toggle-heater'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({'device_id': deviceId, 'heater_state': state ? 'ON' : 'OFF'}),
      );
    } catch (e) {
      print("API Toggle Heater Error: $e");
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
      print("API Emergency Stop Error: $e");
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
      print("API Fetch Records Error: $e");
    }
    return [];
  }
}
