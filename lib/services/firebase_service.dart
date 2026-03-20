import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Listens to the live metrics for a specific device.
  Stream<Map<String, dynamic>> listenToLiveMetrics(String deviceId) {
    if (deviceId.isEmpty) {
      return const Stream.empty();
    }
    
    final DatabaseReference metricsRef = _database.ref('devices/$deviceId/live_metrics');
    
    return metricsRef.onValue.map((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return <String, dynamic>{};
    });
  }
}
