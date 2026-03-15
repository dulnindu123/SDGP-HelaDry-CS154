import '../app/mock_data.dart';

class MockDeviceService {
  /// Simulates BLE scanning with a delay
  static Future<List<MockDevice>> scanForDevices() async {
    await Future.delayed(const Duration(seconds: 2));
    return MockData.devices;
  }

  /// Simulates connecting to a device
  static Future<bool> connectToDevice(String deviceName) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return true; // always succeeds in mock
  }

  /// Returns mock live metrics
  static Map<String, dynamic> getLiveMetrics() {
    return Map<String, dynamic>.from(MockData.liveMetrics);
  }
}
