import 'dart:async';
import 'dart:convert';
import 'ble_device_service.dart';
import 'firebase_device_service.dart';

class DeviceState {
  final double tempC;
  final double humPct;
  final double weightG;
  final int fanSpeedPct;
  final bool heaterOn;
  final double batteryV;
  final double lux;
  final String sessionState;
  final String cropName;
  final double progressPct;
  final double targetTempC;
  final bool alertOverTemp;
  final bool alertLowBat;
  final bool alertSensorFault;
  final bool isOnline; // Helps UI know if data is fresh from Firebase vs BLE

  const DeviceState({
    this.tempC = 0.0,
    this.humPct = 0.0,
    this.weightG = 0.0,
    this.fanSpeedPct = 0,
    this.heaterOn = false,
    this.batteryV = 0.0,
    this.lux = 0.0,
    this.sessionState = 'IDLE',
    this.cropName = '',
    this.progressPct = 0.0,
    this.targetTempC = 0.0,
    this.alertOverTemp = false,
    this.alertLowBat = false,
    this.alertSensorFault = false,
    this.isOnline = false,
  });

  factory DeviceState.fromJson(Map<String, dynamic> json, {bool isOnline = false}) {
    final alerts = json['alerts'] as Map<String, dynamic>? ?? {};
    
    // BLE json and Firebase json might have slightly different keys or matching keys.
    // Firmware Ble output matches `temp`, `hum`, `weight`, `fan` etc.
    // Firebase Live output matches `temp_c`, `hum_pct`, `weight_g`, `fan_speed_pct`.
    
    return DeviceState(
      tempC: _parseD(json['temp'] ?? json['temp_c']),
      humPct: _parseD(json['hum'] ?? json['hum_pct']),
      weightG: _parseD(json['weight'] ?? json['weight_g']),
      fanSpeedPct: _parseI(json['fan'] ?? json['fan_speed_pct']),
      heaterOn: _parseB(json['heater'] ?? json['heater_on']),
      batteryV: _parseD(json['bat'] ?? json['battery_v']),
      lux: _parseD(json['lux']),
      sessionState: (json['session'] ?? json['session_state'] ?? 'IDLE').toString(),
      cropName: (json['crop'] ?? json['session_crop'] ?? '').toString(),
      progressPct: _parseD(json['progress'] ?? json['progress_pct']),
      targetTempC: _parseD(json['tgt_temp'] ?? json['target_temp_c']),
      alertOverTemp: _parseB(alerts['ot'] ?? json['alert_over_temp']),
      alertLowBat: _parseB(alerts['lb'] ?? json['alert_low_bat']),
      alertSensorFault: _parseB(alerts['sf'] ?? json['alert_sensor']),
      isOnline: isOnline,
    );
  }

  static double _parseD(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static int _parseI(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static bool _parseB(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    if (v is num) return v > 0;
    return false;
  }
}

class DeviceTransport {
  static final DeviceTransport _instance = DeviceTransport._internal();
  factory DeviceTransport() => _instance;
  DeviceTransport._internal();

  final _stateController = StreamController<DeviceState>.broadcast();
  Stream<DeviceState> get stateStream => _stateController.stream;

  DeviceState _lastState = const DeviceState();
  DeviceState get lastState => _lastState;

  final BleDeviceService ble = BleDeviceService();
  final FirebaseDeviceService firebase = FirebaseDeviceService();

  String _currentMode = 'offline'; // 'offline' or 'online'
  String _deviceId = '';

  StreamSubscription? _bleSub;
  StreamSubscription? _fbSub;

  void init(String mode, String deviceId) {
    _currentMode = mode;
    _deviceId = deviceId;
    _reconnectTransport();
  }

  void switchMode(String mode) {
    if (_currentMode == mode) return;
    _currentMode = mode;
    _reconnectTransport();
  }

  void _reconnectTransport() {
    _bleSub?.cancel();
    _fbSub?.cancel();

    if (_currentMode == 'offline') {
      _bleSub = ble.stateStream.listen((state) {
        _lastState = state;
        _stateController.add(state);
      });
      // Assuming BLE connection is handled by the UI / Connection flow.
    } else {
      _fbSub = firebase.streamLiveState(_deviceId).listen((state) {
        _lastState = state;
        _stateController.add(state);
      });
    }
  }

  Future<void> sendCommand(String cmd, [Map<String, dynamic>? data]) async {
    if (_currentMode == 'offline') {
      final payload = {'cmd': cmd};
      if (data != null) payload.addAll(data);
      await ble.writeCommand(jsonEncode(payload));
    } else {
      final target = 'commands/${cmd.toLowerCase()}';
      if (cmd == "SET_MANUAL_OUTPUTS" && data != null) {
        // Map payload nicely
        for(var k in data.keys) {
           await firebase.writeNode(_deviceId, 'commands/$k', data[k]);
        }
      } else {
        await firebase.writeNode(_deviceId, target, true);
        if (data != null) {
           for(var k in data.keys) {
              await firebase.writeNode(_deviceId, 'commands/$k', data[k]);
           }
        }
      }
    }
  }

  void dispose() {
    _bleSub?.cancel();
    _fbSub?.cancel();
  }
}
