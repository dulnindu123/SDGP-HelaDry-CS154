import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class FirebaseLiveState {
  String fw = "";
  String deviceId = "";
  String bleName = "";
  double weightG = 0;
  int fanSpeedPct = 0;
  bool heaterOn = false;
  double tempC = 0.0;
  double humPct = 0.0;
  double presHpa = 0.0;
  double lux = 0.0;
  double batteryV = 0.0;
  bool autoHeatEnabled = false;
  double targetTempC = 0.0;
  double initialWeightG = 0.0;
  double progressPct = 0.0;
  String sessionState = "IDLE";
  String sessionCrop = "";
  bool alertOverTemp = false;
  bool alertLowBat = false;
  bool alertSensor = false;
  int tsMs = 0;

  FirebaseLiveState.fromJson(Map<dynamic, dynamic> json) {
    fw = json['fw'] ?? "";
    deviceId = json['device_id'] ?? "";
    bleName = json['ble_name'] ?? "";
    weightG = (json['weight_g'] ?? 0.0).toDouble();
    fanSpeedPct = json['fan_speed_pct'] ?? 0;
    heaterOn = json['heater_on'] ?? false;
    tempC = (json['temp_c'] ?? 0.0).toDouble();
    humPct = (json['hum_pct'] ?? 0.0).toDouble();
    presHpa = (json['pres_hpa'] ?? 0.0).toDouble();
    lux = (json['lux'] ?? 0.0).toDouble();
    batteryV = (json['battery_v'] ?? 0.0).toDouble();
    autoHeatEnabled = json['auto_heat_enabled'] ?? false;
    targetTempC = (json['target_temp_c'] ?? 0.0).toDouble();
    initialWeightG = (json['initial_weight_g'] ?? 0.0).toDouble();
    progressPct = (json['progress_pct'] ?? 0.0).toDouble();
    sessionState = json['session_state'] ?? "IDLE";
    sessionCrop = json['session_crop'] ?? "";
    alertOverTemp = json['alert_over_temp'] ?? false;
    alertLowBat = json['alert_low_bat'] ?? false;
    alertSensor = json['alert_sensor'] ?? false;
    tsMs = json['ts_ms'] ?? 0;
  }
}

class BatchHistoryEntry {
  String key;
  double weightG;
  int fanPct;
  bool heaterOn;
  double tempC;
  double humPct;
  double lux;
  double batteryV;
  double progressPct;
  int tsMs;

  BatchHistoryEntry({
    required this.key,
    required this.weightG,
    required this.fanPct,
    required this.heaterOn,
    required this.tempC,
    required this.humPct,
    required this.lux,
    required this.batteryV,
    required this.progressPct,
    required this.tsMs,
  });

  factory BatchHistoryEntry.fromJson(String key, Map<dynamic, dynamic> json) {
    return BatchHistoryEntry(
      key: key,
      weightG: (json['weight_g'] ?? 0.0).toDouble(),
      fanPct: json['fan_pct'] ?? 0,
      heaterOn: json['heater_on'] ?? false,
      tempC: (json['temp_c'] ?? 0.0).toDouble(),
      humPct: (json['hum_pct'] ?? 0.0).toDouble(),
      lux: (json['lux'] ?? 0.0).toDouble(),
      batteryV: (json['battery_v'] ?? 0.0).toDouble(),
      progressPct: (json['progress_pct'] ?? 0.0).toDouble(),
      tsMs: json['ts_ms'] ?? 0,
    );
  }
}

class FirebaseDeviceService extends ChangeNotifier {
  FirebaseLiveState? liveState;
  List<BatchHistoryEntry> history = [];
  StreamSubscription? _liveSubscription;
  String? _deviceId;
  bool isListening = false;
  
  String? get deviceId => _deviceId;

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  void setDeviceId(String id) {
    if (_deviceId == id) return;
    stopListening();
    _deviceId = id;
    notifyListeners();
  }

  void startListening() {
    if (_deviceId == null || isListening) return;
    isListening = true;
    _liveSubscription = _db.child('devices').child(_deviceId!).child('live').onValue.listen((event) {
      if (!isListening) return; 
      if (event.snapshot.value != null) {
        liveState = FirebaseLiveState.fromJson(event.snapshot.value as Map<dynamic, dynamic>);
        notifyListeners();
      }
    });
  }

  void stopListening() {
    isListening = false;
    _liveSubscription?.cancel();
    _liveSubscription = null;
  }

  Future<void> setInitialWeight() async {
    if (_deviceId == null) return;
    await _db.child('devices').child(_deviceId!).child('commands').update({'set_initial_weight': true});
  }

  Future<void> fetchHistory({int limit = 50}) async {
    if (_deviceId == null) return;
    try {
      final snapshot = await _db
          .child('devices')
          .child(_deviceId!)
          .child('history')
          .orderByChild('ts_ms')
          .limitToLast(limit)
          .get();
          
      history.clear();
      if (snapshot.value != null) {
        final Map<dynamic, dynamic> map = snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          history.add(BatchHistoryEntry.fromJson(key.toString(), value as Map<dynamic, dynamic>));
        });
        history.sort((a, b) => b.tsMs.compareTo(a.tsMs)); // descending
      }
      notifyListeners();
    } catch(e) {}
  }

  Future<void> setFanSpeed(int pct) async {
    if (_deviceId == null) return;
    await _db.child('devices').child(_deviceId!).child('commands').update({'fan_speed_pct': pct});
  }

  Future<void> setHeaterManualOn(bool on) async {
    if (_deviceId == null) return;
    await _db.child('devices').child(_deviceId!).child('commands').update({
      'heater_manual_on': on,
      'heater_force_off': !on
    });
  }

  Future<void> setHeaterForceOff() async {
    if (_deviceId == null) return;
    await _db.child('devices').child(_deviceId!).child('commands').update({'heater_force_off': true});
  }

  Future<void> tare() async {
    if (_deviceId == null) return;
    await _db.child('devices').child(_deviceId!).child('commands').update({'tare': true});
  }

  Future<void> emergencyStop() async {
    if (_deviceId == null) return;
    await _db.child('devices').child(_deviceId!).child('commands').update({'emergency_stop': true});
  }

  Future<void> startSession(String crop, double targetTemp) async {
    if (_deviceId == null) return;
    await _db.child('devices').child(_deviceId!).child('commands').update({
      'session_cmd': 'START',
      'session_crop': crop,
      'session_target_temp': targetTemp
    });
  }

  /// Creates a full session record in Firebase under 'sessions/' node.
  /// This ensures session data is visible in the database for tracking.
  Future<String?> createSessionRecord({
    required String crop,
    required double targetTemp,
    required double weightKg,
    int trays = 1,
    int durationHours = 12,
    String? batchName,
  }) async {
    if (_deviceId == null) return null;
    try {
      final ownerSnapshot = await _db.child('devices').child(_deviceId!).child('owner').get();
      final ownerId = ownerSnapshot.value?.toString() ?? '';

      final sessionRef = _db.child('sessions').push();
      final String sessionKey = sessionRef.key!;
      
      await sessionRef.set({
        'session_id': sessionKey,
        'device_id': _deviceId,
        'user_id': ownerId,
        'crop_name': crop,
        'batch_name': batchName ?? crop,
        'crop_emoji': '🌾', // Default emoji if not provided
        'temperature': targetTemp,
        'weight_kg': weightKg,
        'trays': trays,
        'duration': durationHours,
        'status': 'active',
        'start_date': DateTime.now().toUtc().toIso8601String(),
        'end_date': null,
      });
      return sessionKey;
    } catch (e) {
      debugPrint("Firebase Create Session Error: $e");
      return null;
    }
  }

  /// Fetches all sessions for the current device from the 'sessions/' node.
  Future<List<Map<String, dynamic>>> fetchSessions() async {
    if (_deviceId == null) return [];
    try {
      final snapshot = await _db.child('sessions')
          .orderByChild('device_id')
          .equalTo(_deviceId)
          .get();
          
      if (snapshot.value != null) {
        final Map<dynamic, dynamic> map = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> results = [];
        map.forEach((key, value) {
          final data = Map<String, dynamic>.from(value as Map);
          data['id'] = key.toString();
          results.add(data);
        });
        // Sort by start_date descending
        results.sort((a, b) {
          final dateA = DateTime.tryParse(a['start_date'] ?? '') ?? DateTime(2000);
          final dateB = DateTime.tryParse(b['start_date'] ?? '') ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });
        return results;
      }
    } catch (e) {
      debugPrint("Firebase Fetch Sessions Error: $e");
    }
    return [];
  }


  Future<void> stopSession() async {
    if (_deviceId == null) return;
    await _db.child('devices').child(_deviceId!).child('commands').update({'session_cmd': 'STOP'});
  }

  Future<void> pauseSession() async {
    if (_deviceId == null) return;
    await _db.child('devices').child(_deviceId!).child('commands').update({'session_cmd': 'PAUSE'});
  }

  Future<void> resumeSession() async {
    if (_deviceId == null) return;
    await _db.child('devices').child(_deviceId!).child('commands').update({'session_cmd': 'RESUME'});
  }

  Future<void> setConfig({bool? autoHeat, double? targetTempC, double? calibrationFactor}) async {
    if (_deviceId == null) return;
    Map<String, dynamic> updates = {};
    if (autoHeat != null) updates['auto_heat_enabled'] = autoHeat;
    if (targetTempC != null) updates['target_temp_c'] = targetTempC;
    if (calibrationFactor != null) updates['calibration_factor'] = calibrationFactor;
    if (updates.isNotEmpty) {
      await _db.child('devices').child(_deviceId!).child('config').update(updates);
    }
  }

  Future<void> writeWifiConfig(String ssid, String ip) async {
    if (_deviceId == null) return;
    await _db.child('devices').child(_deviceId!).child('config').update({
      'last_wifi_ssid': ssid,
      'wifi_connected_at': DateTime.now().toIso8601String(),
      'wifi_ip': ip,
    });
  }

  /// Send WiFi credentials via Firebase RTDB so the firmware can read them.
  /// The password is auto-cleared after 30 seconds for security.
  Future<void> sendWifiCredentials(String ssid, String password) async {
    if (_deviceId == null) return;
    await _db.child('devices').child(_deviceId!).child('commands').update({
      'wifi_ssid': ssid,
      'wifi_pass': password,
    });
    // Auto-clear password after 30 seconds for security
    Future.delayed(const Duration(seconds: 30), () {
      _db.child('devices').child(_deviceId!).child('commands').child('wifi_pass').remove();
    });
  }
}
