import 'package:flutter/material.dart';

class SessionStore extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _connectionMode = ''; // 'online' or 'offline'
  String _pairedDeviceId = '';
  String _pairedDeviceName = '';
  String _selectedWifiSsid = '';
  bool _wifiConfigured = false;
  List<Map<String, String>> _savedNetworks = [];
  String _userName = '';
  String _userEmail = '';

  // Device state
  double _fanSpeed = 50;
  bool _heaterOn = false;
  double _targetTemp = 55;
  bool _useCelsius = true;

  // Calibration
  double _tempOffset = 0.0;
  double _humidityOffset = 0.0;

  // Notifications
  bool _overTempAlert = true;
  bool _lowBatteryAlert = true;
  bool _sensorFaultAlert = true;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get connectionMode => _connectionMode;
  String get pairedDeviceId => _pairedDeviceId;
  String get pairedDeviceName => _pairedDeviceName;
  String get selectedWifiSsid => _selectedWifiSsid;
  bool get wifiConfigured => _wifiConfigured;
  List<Map<String, String>> get savedNetworks => _savedNetworks;
  String get userName => _userName;
  String get userEmail => _userEmail;
  double get fanSpeed => _fanSpeed;
  bool get heaterOn => _heaterOn;
  double get targetTemp => _targetTemp;
  bool get useCelsius => _useCelsius;
  double get tempOffset => _tempOffset;
  double get humidityOffset => _humidityOffset;
  bool get overTempAlert => _overTempAlert;
  bool get lowBatteryAlert => _lowBatteryAlert;
  bool get sensorFaultAlert => _sensorFaultAlert;

  // Auth
  void login({String name = '', String email = ''}) {
    _isLoggedIn = true;
    _userName = name.isNotEmpty ? name : 'User';
    _userEmail = email.isNotEmpty ? email : 'user@example.com';
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _connectionMode = '';
    _pairedDeviceId = '';
    _pairedDeviceName = '';
    _selectedWifiSsid = '';
    _wifiConfigured = false;
    _savedNetworks = [];
    _userName = '';
    _userEmail = '';
    _fanSpeed = 50;
    _heaterOn = false;
    _targetTemp = 55;
    notifyListeners();
  }

  // Connection
  void setConnectionMode(String mode) {
    _connectionMode = mode;
    notifyListeners();
  }

  void setPairedDevice(String id, String name) {
    _pairedDeviceId = id;
    _pairedDeviceName = name;
    notifyListeners();
  }

  // WiFi
  void setSelectedWifi(String ssid) {
    _selectedWifiSsid = ssid;
    notifyListeners();
  }

  void markWifiConfigured() {
    _wifiConfigured = true;
    notifyListeners();
  }

  void saveNetwork(String ssid) {
    final masked = ssid.length > 4
        ? '${ssid.substring(0, 4)}${'*' * (ssid.length - 4)}'
        : ssid;
    _savedNetworks.add({'ssid': ssid, 'masked': masked});
    notifyListeners();
  }

  // Device controls
  void setFanSpeed(double speed) {
    _fanSpeed = speed;
    notifyListeners();
  }

  void setHeaterOn(bool on) {
    _heaterOn = on;
    notifyListeners();
  }

  void setTargetTemp(double temp) {
    _targetTemp = temp;
    notifyListeners();
  }

  void emergencyStop() {
    _fanSpeed = 0;
    _heaterOn = false;
    notifyListeners();
  }

  // Settings
  void setUseCelsius(bool celsius) {
    _useCelsius = celsius;
    notifyListeners();
  }

  void setTempOffset(double offset) {
    _tempOffset = offset;
    notifyListeners();
  }

  void setHumidityOffset(double offset) {
    _humidityOffset = offset;
    notifyListeners();
  }

  void setOverTempAlert(bool val) {
    _overTempAlert = val;
    notifyListeners();
  }

  void setLowBatteryAlert(bool val) {
    _lowBatteryAlert = val;
    notifyListeners();
  }

  void setSensorFaultAlert(bool val) {
    _sensorFaultAlert = val;
    notifyListeners();
  }

  // Profile
  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  void setUserEmail(String email) {
    _userEmail = email;
    notifyListeners();
  }
}
