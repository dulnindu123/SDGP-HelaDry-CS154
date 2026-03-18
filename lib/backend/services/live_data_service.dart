import 'package:firebase_database/firebase_database.dart';

// Ensure that the Firebase core package is initialized before using FirebaseDatabase.
// Updated with the correct project name.

class LiveDataService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Stream<Map<String, dynamic>> listenToLiveData(String deviceId) {
    final ref = _db.ref('devices/$deviceId/live');

    return ref.onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null || data is! Map) {
        return {
          'temperature': 0.0,
          'humidity': 0.0,
          'airflow': 0,
          'updatedAt': 0,
        };
      }

      final map = Map<String, dynamic>.from(data);

      return {
        'temperature': (map['temperature'] ?? 0).toDouble(),
        'humidity': (map['humidity'] ?? 0).toDouble(),
        'airflow': (map['airflow'] ?? 0),
        'updatedAt': (map['updatedAt'] ?? 0),
      };
    });
  }
}
