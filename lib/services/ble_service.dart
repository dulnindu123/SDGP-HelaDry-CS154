import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:permission_handler/permission_handler.dart';

enum BleConnectionStatus { disconnected, scanning, connecting, connected }

class DeviceState {
  String fw = "";
  String deviceId = "";
  String bleName = "";
  double temp = 0.0;
  double hum = 0.0;
  double weight = 0.0;
  int fan = 0;
  bool heater = false;
  double battery = 0.0;
  double lux = 0.0;
  String session = "IDLE";
  String crop = "";
  double targetTemp = 0.0;
  double progress = 0.0;
  bool wifiConnected = false;
  bool alertOverTemp = false;
  bool alertLowBat = false;
  bool alertSensorFault = false;
  String ip = "10.0.2.2"; // Fallback

  DeviceState.fromJson(Map<String, dynamic> json) {
    fw = json['fw'] ?? "";
    deviceId = json['device_id'] ?? "";
    bleName = json['ble_name'] ?? "";
    temp = (json['temp'] ?? 0.0).toDouble();
    hum = (json['hum'] ?? 0.0).toDouble();
    weight = (json['weight'] ?? 0.0).toDouble();
    fan = json['fan'] ?? 0;
    heater = json['heater'] ?? false;
    battery = (json['bat'] ?? 0.0).toDouble();
    lux = (json['lux'] ?? 0.0).toDouble();
    session = json['session'] ?? "IDLE";
    crop = json['crop'] ?? "";
    targetTemp = (json['tgt_temp'] ?? 0.0).toDouble();
    progress = (json['progress'] ?? 0.0).toDouble();
    wifiConnected = json['wifi'] ?? false;
    ip = json['ip'] ?? "10.0.2.2";
    if (json['alerts'] != null) {
      alertOverTemp = json['alerts']['ot'] ?? false;
      alertLowBat = json['alerts']['lb'] ?? false;
      alertSensorFault = json['alerts']['sf'] ?? false;
    }
  }
}

class BleService extends ChangeNotifier {
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String charStateUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String charCmdUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a9";
  static const String charAckUuid = "beb5483e-36e1-4688-b7f5-ea07361b26aa";

  BleConnectionStatus status = BleConnectionStatus.disconnected;
  List<ScanResult> scanResults = [];
  DeviceState? deviceState;
  String? lastAck;
  String _ackBuffer = ""; // Buffer for fragmented JSON packets
  final StreamController<String> _ackStreamController = StreamController<String>.broadcast();
  Stream<String> get ackStream => _ackStreamController.stream;

  final StreamController<Map<String, dynamic>> _wifiResultStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get wifiResultStream => _wifiResultStreamController.stream;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _cmdChar;
  
  DateTime _lastScanNotify = DateTime.now();
  DateTime _lastStateNotify = DateTime.now();

  BluetoothDevice? get connectedDevice => _device;
  String get connectedDeviceName => _device?.platformName ?? "";
  String get connectedDeviceId => _device?.remoteId.str ?? "";
  bool get isConnected => status == BleConnectionStatus.connected;

  BleService() {
    // Listen for scan results
    FlutterBluePlus.scanResults.listen((results) {
      final now = DateTime.now();
      if (now.difference(_lastScanNotify).inMilliseconds > 200) {
        // More resilient filtering: check platformName and localName
        scanResults = results.where((r) {
          final name = (r.device.platformName.isNotEmpty 
              ? r.device.platformName 
              : r.advertisementData.advName).toUpperCase();
          return name.startsWith("HELADRY") || 
                 r.advertisementData.serviceUuids.contains(Guid(serviceUuid));
        }).toList();
        _lastScanNotify = now;
        notifyListeners();
      }
    });

    // Listen for scan state to update status automatically
    FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning && status == BleConnectionStatus.scanning) {
        status = _device != null ? BleConnectionStatus.connected : BleConnectionStatus.disconnected;
        notifyListeners();
      }
    });
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    // 1. Request permissions before starting
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();

    if (statuses.values.any((status) => status.isDenied)) {
      developer.log("Scan error: BLE Permissions denied");
      status = BleConnectionStatus.disconnected;
      notifyListeners();
      return;
    }

    status = BleConnectionStatus.scanning;
    scanResults.clear();
    notifyListeners();
    try {
      await FlutterBluePlus.startScan(
        timeout: timeout,
      );
    } catch (e) {
      developer.log("Scan error: $e");
      status = BleConnectionStatus.disconnected;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    if (status == BleConnectionStatus.scanning) {
      status = BleConnectionStatus.disconnected;
      notifyListeners();
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    status = BleConnectionStatus.connecting;
    notifyListeners();
    
    try {
      // 15-second overall timeout for the connection sequence
      return await _connectSequence(device).timeout(const Duration(seconds: 15));
    } catch (e) {
      developer.log("Connect error or timeout: $e");
      await disconnect();
      return false;
    }
  }

  Future<bool> _connectSequence(BluetoothDevice device) async {
    await stopScan();
    await Future.delayed(const Duration(milliseconds: 200));
    
    await device.connect(autoConnect: false);
    _device = device;

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      await device.requestMtu(256).timeout(const Duration(seconds: 3));
      developer.log("BLE: Requested 256 MTU");
    } catch (e) {
      developer.log("MTU request failed or timed out: $e");
    }

    try {
      if (Platform.isAndroid) {
          await device.requestConnectionPriority(connectionPriorityRequest: ConnectionPriority.high).timeout(const Duration(seconds: 2));
          developer.log("BLE: Requested High Priority Connection");
      }
    } catch (e) {
      developer.log("Priority request error: $e");
    }

    List<BluetoothService> services = await device.discoverServices().timeout(const Duration(seconds: 5));
    BluetoothService? targetService;
    for (var s in services) {
      if (s.uuid.toString() == serviceUuid) {
        targetService = s;
        break;
      }
    }

    if (targetService == null) throw Exception("Service not found");

    for (var char in targetService.characteristics) {
      if (char.uuid.toString() == charStateUuid) {
        await char.setNotifyValue(true).timeout(const Duration(seconds: 2));
        char.lastValueStream.listen((value) {
          if (value.isNotEmpty) {
            try {
              final jsonStr = utf8.decode(value);
              final map = jsonDecode(jsonStr);
              deviceState = DeviceState.fromJson(map);
              
              final now = DateTime.now();
              if (now.difference(_lastStateNotify).inMilliseconds > 200 || 
                  deviceState!.wifiConnected || 
                  deviceState!.session != "DRYING") {
                _lastStateNotify = now;
                notifyListeners();
              }
            } catch (e) {
              developer.log("Parse state error: $e");
            }
          }
        });
      } else if (char.uuid.toString() == charAckUuid) {
        await char.setNotifyValue(true).timeout(const Duration(seconds: 2));
        char.onValueReceived.listen((value) {
          if (value.isNotEmpty) {
            try {
              final fragment = utf8.decode(value);
              _ackBuffer += fragment;
              developer.log("BLE Fragment [${value.length} bytes]: $fragment");
              
              // Try to decode the accumulated buffer
              // We check if it looks like a complete JSON (starts with { and ends with })
              // to avoid unnecessary jsonDecode calls which might be expensive if buffer is large
              final trimmed = _ackBuffer.trim();
              if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
                try {
                  final Map<String, dynamic> map = jsonDecode(trimmed);
                  lastAck = trimmed;
                  developer.log("BLE Complete JSON decoded: ${lastAck!.length} bytes");
                  _ackStreamController.add(lastAck!);
                  
                  if (map.containsKey('cmd') && 
                      (map['cmd'] == 'WIFI_CONNECT_RESULT' || map['cmd'] == 'WIFI_SCAN_RESULT')) {
                    _wifiResultStreamController.add(map);
                  }
                  
                  _ackBuffer = ""; // Clear on success
                  notifyListeners();
                } catch (e) {
                  // Not a complete/valid JSON yet despite the braces, wait for more
                }
              }
            } catch (e) {
              developer.log("Error handling BLE fragment: $e");
              // If we get an encoding error, the buffer might be corrupted. 
              // However, we don't clear it immediately to allow for possible recovery
              // if it was just a partial multi-byte character at the end.
            }
          }
        });
      } else if (char.uuid.toString() == charCmdUuid) {
        _cmdChar = char;
      }
    }

    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        status = BleConnectionStatus.disconnected;
        _device = null;
        _cmdChar = null;
        deviceState = null;
        notifyListeners();
      }
    });

    status = BleConnectionStatus.connected;
    notifyListeners();
    return true;
  }

  Future<void> requestMtu(int mtu) async {
    if (_device != null) {
      try {
        await _device!.requestMtu(mtu);
      } catch (e) {
        developer.log("MTU request error: $e");
      }
    }
  }

  Future<void> disconnect() async {
    if (_device != null) {
      await _device!.disconnect();
    }
    status = BleConnectionStatus.disconnected;
    _device = null;
    _cmdChar = null;
    deviceState = null;
    notifyListeners();
  }

  Future<bool> sendCommand(Map<String, dynamic> cmd, {Duration timeout = const Duration(seconds: 5)}) async {
    if (_cmdChar == null) {
      developer.log("Cmd error: No command characteristic found.");
      return false;
    }
    
    // Safety check connection status
    if (status != BleConnectionStatus.connected) {
      developer.log("Cmd error: Device not connected.");
      return false;
    }

    // Clear buffer before sending new command to avoid stale data interference
    _ackBuffer = "";

    try {
      final jsonStr = jsonEncode(cmd);
      await _cmdChar!.write(
        utf8.encode(jsonStr),
        timeout: timeout.inSeconds,
      ).timeout(timeout);
      
      developer.log("Sent BLE command: $jsonStr");
      return true;
    } catch (e) {
      developer.log("Cmd error sending $cmd: $e");
      return false;
    }
  }

  Future<bool> sendStartSession(String crop, double targetTemp, double weight) =>
      sendCommand({"cmd": "START_SESSION", "crop": crop, "target_temp": targetTemp, "weight": weight});

  Future<bool> sendStopSession() => sendCommand({"cmd": "STOP_SESSION"});
  Future<bool> sendPauseSession() => sendCommand({"cmd": "PAUSE_SESSION"});
  Future<bool> sendResumeSession() => sendCommand({"cmd": "RESUME_SESSION"});
  Future<bool> sendTare() => sendCommand({"cmd": "TARE"});
  Future<bool> sendEmergencyStop() => sendCommand({"cmd": "EMERGENCY_STOP"});

  Future<bool> sendManualOutputs({int? fanSpeed, bool? heater, double? targetTemp}) {
    Map<String, dynamic> cmd = {"cmd": "SET_MANUAL_OUTPUTS"};
    if (fanSpeed != null) cmd["fan_speed"] = fanSpeed;
    if (heater != null) cmd["heater"] = heater;
    if (targetTemp != null) cmd["target_temp"] = targetTemp;
    return sendCommand(cmd);
  }

  Future<bool> sendWifiCredentials(String ssid, String password) =>
      sendCommand({"cmd": "SET_WIFI_CREDS", "ssid": ssid, "pass": password});

  Future<bool> sendScanWifi() async {
    if (Platform.isAndroid && _device != null) {
      try {
        await _device!.requestConnectionPriority(connectionPriorityRequest: ConnectionPriority.high);
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        developer.log("Priority request error before scan: $e");
      }
    }
    return sendCommand({"cmd": "SCAN_WIFI"});
  }

  Future<bool> sendClearWifiCreds() => sendCommand({"cmd": "CLEAR_WIFI_CREDS"});
}
