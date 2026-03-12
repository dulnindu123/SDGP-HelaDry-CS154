import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'device_transport.dart';

class FirebaseDeviceService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Stream<DeviceState> streamLiveState(String deviceId) {
    if (deviceId.isEmpty) return const Stream.empty();
    
    final path = 'devices/$deviceId/live';
    return _db.ref(path).onValue.map((event) {
      if (event.snapshot.value == null) return const DeviceState(isOnline: true);
      
      try {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return DeviceState.fromJson(data, isOnline: true);
      } catch (e) {
        return const DeviceState(isOnline: true);
      }
    });
  }

  Future<void> writeNode(String deviceId, String subPath, dynamic value) async {
    if (deviceId.isEmpty) return;
    final path = 'devices/$deviceId/$subPath';
    await _db.ref(path).set(value);
  }

  Future<void> updateNode(String deviceId, String subPath, Map<String, dynamic> updates) async {
    if (deviceId.isEmpty) return;
    final path = 'devices/$deviceId/$subPath';
    await _db.ref(path).update(updates);
  }

  Future<bool> checkDeviceExists(String deviceId) async {
    if (deviceId.isEmpty) return false;
    final snapshot = await _db.ref('devices/$deviceId').get();
    return snapshot.exists;
  }
}
