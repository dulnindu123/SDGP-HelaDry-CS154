import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DeviceLinkService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Future<void> linkDeviceToCurrentUser(String deviceId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("No logged-in user found.");
    }

    final String uid = user.uid;

    final Map<String, Object?> updates = {
      'users/$uid/devices/$deviceId': true,
      'devices/$deviceId/owner': uid,
    };

    await _db.ref().update(updates);
  }

  Future<void> populateMockData() async {
    final mockUid = "mock-uid-123";
    final mockDeviceId = "device-001";

    final Map<String, Object?> mockData = {
      'users/$mockUid/devices/$mockDeviceId': true,
      'devices/$mockDeviceId/owner': mockUid,
    };

    await _db.ref().update(mockData);
  }
}
