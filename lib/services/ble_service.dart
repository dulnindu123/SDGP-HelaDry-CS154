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
  String ip = "172.30.161.140"; // Fallback

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
    ip = json['ip'] ?? "172.30.161.140";
    if (json['alerts'] != null) {
      alertOverTemp = json['alerts']['ot'] ?? false;
      alertLowBat = json['alerts']['lb'] ?? false;
      alertSensorFault = json['alerts']['sf'] ?? false;
    }
  }
}

class BleService extends ChangeNotifier {
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHAR_STATE_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String CHAR_CMD_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a9";
  static const String CHAR_ACK_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26aa";

  BleConnectionStatus status = BleConnectionStatus.disconnected;
  List<ScanResult> scanResults = [];
  DeviceState? deviceState;
  String? lastAck;
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
              : r.advertisementData.localName).toUpperCase();
          return name.startsWith("HELADRY") || 
                 r.advertisementData.serviceUuids.contains(Guid(SERVICE_UUID));
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
      await stopScan();
      // Allow BLE stack to settle after scan stop
      await Future.delayed(const Duration(milliseconds: 200));
      
      await device.connect(autoConnect: false);
      _device = device;

      // Allow stabilization before MTU/Priority requests
      await Future.delayed(const Duration(milliseconds: 300));

      // Request larger MTU for JSON data (scans, etc)
      try {
        // 256 is safer than 512 for many Android devices
        await device.requestMtu(256);
        developer.log("BLE: Requested 256 MTU");
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        developer.log("MTU request failed: $e");
      }

      // Optimization: Request high connection priority on Android for faster throughput
      try {
        if (Platform.isAndroid) {
             await device.requestConnectionPriority(connectionPriorityRequest: ConnectionPriority.high);
             developer.log("BLE: Requested High Priority Connection");
        }
      } catch (e) {
        developer.log("Priority request error: $e");
      }

      List<BluetoothService> services = await device.discoverServices();
      BluetoothService? targetService;
      for (var s in services) {
        if (s.uuid.toString() == SERVICE_UUID) {
          targetService = s;
          break;
        }
      }

      if (targetService == null) throw Exception("Service not found");

      for (var char in targetService.characteristics) {
        if (char.uuid.toString() == CHAR_STATE_UUID) {
          await char.setNotifyValue(true);
          char.lastValueStream.listen((value) {
            if (value.isNotEmpty) {
              try {
                final jsonStr = utf8.decode(value);
                final map = jsonDecode(jsonStr);
                deviceState = DeviceState.fromJson(map);
                
                // Throttle UI updates for raw sensor data unless it's critical
                final now = DateTime.now();
                if (now.difference(_lastStateNotify).inMilliseconds > 200 || 
                    deviceState!.wifiConnected || 
                    deviceState!.session != "DRYING") {
                  _lastStateNotify = now;
                  notifyListeners();
                }
              } catch (e) {}
            }
          });
        } else if (char.uuid.toString() == CHAR_ACK_UUID) {
          await char.setNotifyValue(true);
          char.onValueReceived.listen((value) {
            if (value.isNotEmpty) {
              lastAck = utf8.decode(value);
              developer.log("BLE ACK decoded: $lastAck");
              _ackStreamController.add(lastAck!);
              
              try {
                final Map<String, dynamic> map = jsonDecode(lastAck!);
                if (map.containsKey('cmd') && 
                    (map['cmd'] == 'WIFI_CONNECT_RESULT' || map['cmd'] == 'WIFI_SCAN_RESULT')) {
                  _wifiResultStreamController.add(map);
                }
              } catch (e) {
                developer.log("Error parsing ACK JSON: $e");
              }
              notifyListeners();
            }
          });
        } else if (char.uuid.toString() == CHAR_CMD_UUID) {
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
    } catch (e) {
      developer.log("Connect error: $e");
      await disconnect();
      return false;
    }
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

  Future<bool> sendScanWifi() => sendCommand({"cmd": "SCAN_WIFI"});

  Future<bool> sendClearWifiCreds() => sendCommand({"cmd": "CLEAR_WIFI_CREDS"});
}
