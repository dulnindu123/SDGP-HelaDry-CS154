import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'ble_service.dart';
import 'firebase_service.dart';
import 'api_service.dart';
import '../app/mock_data.dart';

enum ConnectionMode { none, offline, online }

class ConnectionController extends ChangeNotifier {
  final BleService ble;
  final FirebaseDeviceService fb;
  final ApiService? _api;

  ApiService? get api => _api;
  
  ConnectionMode mode = ConnectionMode.none;
  bool backendOnline = false;
  DateTime? _lastHealthCheck;

  bool get isOnline => mode == ConnectionMode.online;
  bool get isOffline => mode == ConnectionMode.offline;

  /// Fallback: treat mode==none with an active BLE connection as offline.
  /// This prevents commands from being silently dropped when the user
  /// pairs via BLE but the mode hasn't been explicitly set yet.
  bool get _resolvedIsOffline => isOffline || (mode == ConnectionMode.none && ble.isConnected);

  ConnectionController({required this.ble, required this.fb, ApiService? api}) : _api = api {
    ble.addListener(notifyListeners);
    fb.addListener(notifyListeners);
    checkBackendHealth();
  }

  Future<void> checkBackendHealth() async {
    if (_api == null) {
      backendOnline = false;
      return;
    }
    
    final now = DateTime.now();
    if (_lastHealthCheck != null && now.difference(_lastHealthCheck!).inSeconds < 10) {
      return; // Use cached value
    }
    
    _lastHealthCheck = now;
    try {
      await _api!.checkServerStatus();
      backendOnline = true;
    } catch (e) {
      backendOnline = false;
    }
    notifyListeners();
  }

  void setMode(String modeStr) {
    if (modeStr == 'online') {
      mode = ConnectionMode.online;
    } else if (modeStr == 'offline') {
      mode = ConnectionMode.offline;
    } else {
      mode = ConnectionMode.none;
    }
    notifyListeners();
  }

  /// Syncs the controller state with SessionStore (e.g. on app startup)
  void syncWithSession(dynamic session) {
    final pairedId = session.pairedDeviceId as String;
    if (pairedId.isNotEmpty) {
      fb.setDeviceId(pairedId);
      // If we have a paired device, we should be in a functional mode
      if (mode == ConnectionMode.none) {
        // Default to online if we have a paired device ID (as it usually implies cloud registration)
        // or check SessionStore's connectionMode if it's reliable
        final savedMode = session.connectionMode as String;
        if (savedMode == 'online') activateOnlineMode(pairedId);
        else if (savedMode == 'offline') mode = ConnectionMode.offline;
      }
      notifyListeners();
    }
  }

  void activateOnlineMode(String deviceId) {
    mode = ConnectionMode.online;
    fb.setDeviceId(deviceId);
    fb.startListening();
    notifyListeners();
  }

  Map<String, dynamic> get liveMetrics {
    if (isOnline && fb.liveState != null) {
      final state = fb.liveState!;
      return {
        'temperature': state.tempC,
        'humidity': state.humPct,
        'fanSpeed': state.fanSpeedPct,
        'heaterStatus': state.heaterOn,
        'battery': state.batteryV,
        'solarStatus': state.lux,
        'weight': state.weightG,
        'session': state.sessionState,
        'crop': state.sessionCrop,
        'progress': state.progressPct,
        'alertOverTemp': state.alertOverTemp,
        'alertLowBat': state.alertLowBat,
      };
    } else if (isOffline && ble.deviceState != null) {
      final state = ble.deviceState!;
      return {
        'temperature': state.temp,
        'humidity': state.hum,
        'fanSpeed': state.fan,
        'heaterStatus': state.heater,
        'battery': state.battery,
        'solarStatus': state.lux,
        'weight': state.weight,
        'session': state.session,
        'crop': state.crop,
        'progress': state.progress,
        'alertOverTemp': state.alertOverTemp,
        'alertLowBat': state.alertLowBat,
      };
    }
    
    // Default empty state with keys to prevent null-pointer crashes in UI
    return {
      'temperature': 0.0,
      'humidity': 0.0,
      'fanSpeed': 0,
      'heaterStatus': false,
      'battery': 0.0,
      'solarStatus': 0.0,
      'weight': 0.0,
      'session': 'IDLE',
      'crop': '',
      'progress': 0.0,
    };
  }

  Future<void> startSession(String crop, double targetTemp, double weight) async {
    // 1. Always prioritize backend API if available
    if (isOnline) {
      final payload = {
        'device_id': fb.deviceId, // Ensure device_id is in payload
        'crop_name': crop,
        'temperature': targetTemp,
        'weight_kg': weight,
        'duration': 12, 
        'trays': 1 
      };
      
      if (api != null && backendOnline) {
        try {
          await api!.startSession(payload);
          // Also write to Firebase directly for speed/reliability (redundancy)
          try { await fb.startSession(crop, targetTemp); } catch (_) {}
        } catch (e) {
          debugPrint("Backend Start Session Error: $e. Falling back to Firebase.");
          try { await fb.startSession(crop, targetTemp); } catch (_) {}
        }
      } else {
        try { await fb.startSession(crop, targetTemp); } catch (_) {}
      }

      // 2. Always create a session record in Firebase for tracking metadata
      try {
        await fb.createSessionRecord(
          crop: crop,
          targetTemp: targetTemp,
          weightKg: weight,
        );
      } catch (e) {
        debugPrint("Session record creation error: $e");
      }
      
    } else if (_resolvedIsOffline) {
      await ble.sendStartSession(crop, targetTemp, weight);
    }
  }


  Future<List<dynamic>> fetchMySessions() async {
    if (_api == null) return [];
    try {
      return await _api!.fetchMyRecords(); // Assuming this is the equivalent for now
    } catch (e) {
      return [];
    }
  }

  Future<void> stopSession() async {
    if (isOnline) {
      if (api != null && backendOnline) {
        try {
          await api!.stopSession(fb.deviceId ?? MockData.defaultDeviceId);
          try { await fb.stopSession(); } catch(_) {}
          return;
        } catch (e) {
          debugPrint("Backend Stop Session Error: $e");
        }
      }
      await fb.stopSession();
    } else if (_resolvedIsOffline) {
      await ble.sendStopSession();
    }
  }

  Future<void> pauseSession() async {
    if (isOnline) {
      await fb.pauseSession();
    } else if (_resolvedIsOffline) {
      await ble.sendPauseSession();
    }
  }

  Future<void> resumeSession() async {
    if (isOnline) {
      await fb.resumeSession();
    } else if (_resolvedIsOffline) {
      await ble.sendResumeSession();
    }
  }

  Future<void> setFanSpeed(int pct) async {
    if (isOnline) {
      if (api != null && backendOnline) {
        try {
          await api!.updateFanSpeed(fb.deviceId ?? MockData.defaultDeviceId, pct);
          try { await fb.setFanSpeed(pct); } catch(_) {}
          return;
        } catch (e) {
          debugPrint("Backend Fan Sync Error: $e");
        }
      }
      await fb.setFanSpeed(pct);
    } else if (_resolvedIsOffline) {
      await ble.sendManualOutputs(fanSpeed: pct);
    }
  }

  Future<void> setHeater(bool on) async {
    if (isOnline) {
      if (api != null && backendOnline) {
        try {
          await api!.toggleHeater(fb.deviceId ?? MockData.defaultDeviceId, on);
          try {
            if (on) { await fb.setHeaterManualOn(true); } 
            else { await fb.setHeaterForceOff(); }
          } catch(_) {}
          return;
        } catch (e) {
          debugPrint("Backend Heater Sync Error: $e");
        }
      }
      if (on) {
        await fb.setHeaterManualOn(true);
      } else {
        await fb.setHeaterForceOff();
      }
    } else if (_resolvedIsOffline) {
      await ble.sendManualOutputs(heater: on);
    }
  }

  Future<void> setTargetTemp(double temp) async {
    if (isOnline) {
      if (api != null && backendOnline) {
        try {
          await api!.updateTemperature(fb.deviceId ?? MockData.defaultDeviceId, temp);
          try { await fb.setConfig(targetTempC: temp); } catch(_) {}
          return;
        } catch (e) {
          debugPrint("Backend Temp Sync Error: $e");
        }
      }
      await fb.setConfig(targetTempC: temp);
    } else if (_resolvedIsOffline) {
      await ble.sendManualOutputs(targetTemp: temp);
    }
  }

  Future<void> tare() async {
    if (isOnline) {
      try { await fb.tare(); } catch(e) { debugPrint("Firebase Tare Error: $e"); }
    } else if (_resolvedIsOffline) {
      await ble.sendTare();
    }
  }

  Future<void> emergencyStop() async {
    if (isOnline) {
      if (api != null && backendOnline) {
        try {
          await api!.emergencyStop(fb.deviceId ?? MockData.defaultDeviceId);
          try { await fb.emergencyStop(); } catch(_) {}
          return;
        } catch (e) {
          debugPrint("Backend E-Stop Error: $e");
        }
      }
      await fb.emergencyStop();
    } else if (_resolvedIsOffline) {
      await ble.sendEmergencyStop();
    }
  }

  Future<bool> sendWifiCredentials(String ssid, String password) async {
    // Always try BLE first if connected
    bool sent = false;
    if (ble.isConnected) {
      sent = await ble.sendWifiCredentials(ssid, password);
    }
    // Also write to Firebase if online (firmware can pick it up via WiFi)
    if (isOnline) {
      try {
        await fb.sendWifiCredentials(ssid, password);
        sent = true;
      } catch (e) {
        debugPrint("Firebase WiFi Creds Sync Error: $e");
      }
    }
    return sent;
  }
}
