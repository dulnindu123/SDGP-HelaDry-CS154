import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'device_transport.dart';

class BleDeviceService {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  static final Uuid serviceUuid = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  static final Uuid stateCharUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  static final Uuid commandCharUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a9");
  static final Uuid ackCharUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26aa");

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _stateSub;
  StreamSubscription<List<int>>? _ackSub;

  final _stateController = StreamController<DeviceState>.broadcast();
  Stream<DeviceState> get stateStream => _stateController.stream;

  final _ackController = StreamController<String>.broadcast();
  Stream<String> get ackStream => _ackController.stream;

  final _deviceListController = StreamController<List<DiscoveredDevice>>.broadcast();
  Stream<List<DiscoveredDevice>> get deviceListStream => _deviceListController.stream;

  final List<DiscoveredDevice> _discoveredDevices = [];
  String? _connectedDeviceId;

  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((status) => status.isGranted);
  }

  void startScan() async {
    bool hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      _deviceListController.addError("Permissions not granted");
      return;
    }

    _discoveredDevices.clear();
    _scanSub?.cancel();
    
    _scanSub = _ble.scanForDevices(withServices: [serviceUuid]).listen((device) {
      if (device.name.startsWith("HELADRY")) {
        final existing = _discoveredDevices.indexWhere((d) => d.id == device.id);
        if (existing >= 0) {
          _discoveredDevices[existing] = device;
        } else {
          _discoveredDevices.add(device);
        }
        _deviceListController.add(List.from(_discoveredDevices));
      }
    }, onError: (err) {
      _deviceListController.addError(err);
    });
  }

  void stopScan() {
    _scanSub?.cancel();
  }

  Future<void> connect(String deviceId) async {
    _connSub?.cancel();
    _connectedDeviceId = deviceId;
    
    _connSub = _ble.connectToDevice(
      id: deviceId, 
      servicesWithCharacteristicsToDiscover: {serviceUuid: [stateCharUuid, commandCharUuid, ackCharUuid]},
    ).listen((connState) {
      if (connState.connectionState == DeviceConnectionState.connected) {
        _subscribeToCharacteristics();
      } else if (connState.connectionState == DeviceConnectionState.disconnected) {
        _stateSub?.cancel();
        _ackSub?.cancel();
      }
    }, onError: (Object error) {
      // Handle error
    });
  }

  Future<void> disconnect() async {
    _stateSub?.cancel();
    _ackSub?.cancel();
    _connSub?.cancel();
    _connectedDeviceId = null;
  }

  void _subscribeToCharacteristics() {
    if (_connectedDeviceId == null) return;

    final stateChar = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: stateCharUuid,
      deviceId: _connectedDeviceId!,
    );

    final ackChar = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: ackCharUuid,
      deviceId: _connectedDeviceId!,
    );

    _stateSub = _ble.subscribeToCharacteristic(stateChar).listen((data) {
      try {
        final payload = utf8.decode(data);
        final map = jsonDecode(payload);
        final state = DeviceState.fromJson(map, isOnline: false);
        _stateController.add(state);
      } catch (e) {
        // ignore incomplete/bad JSON frames
      }
    });

    _ackSub = _ble.subscribeToCharacteristic(ackChar).listen((data) {
      try {
        final payload = utf8.decode(data);
        _ackController.add(payload);
      } catch (e) {}
    });
  }

  Future<void> writeCommand(String jsonCommand) async {
    if (_connectedDeviceId == null) return;
    
    final cmdChar = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: commandCharUuid,
      deviceId: _connectedDeviceId!,
    );
    
    final bytes = utf8.encode(jsonCommand);
    // writeWithoutResponse for faster execution, or write()
    await _ble.writeCharacteristicWithResponse(cmdChar, value: bytes);
  }
}
