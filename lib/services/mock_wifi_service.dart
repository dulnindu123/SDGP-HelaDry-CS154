import '../app/mock_data.dart';

class MockWifiService {
  /// Simulates WiFi network scanning
  static Future<List<MockWifiNetwork>> scanNetworks() async {
    await Future.delayed(const Duration(seconds: 2));
    return MockData.wifiNetworks;
  }

  /// Simulates connecting to a WiFi network
  static Future<bool> connectToNetwork(String ssid, String password) async {
    // Simulate progress: Saving... Connecting...
    await Future.delayed(const Duration(seconds: 3));
    return true; // always succeeds in mock
  }
}
