import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DeviceClaimService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<bool> claimDevice(String deviceId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final snapshot = await _db.child('devices').child(deviceId).child('owner').get().timeout(const Duration(seconds: 10));
      if (!snapshot.exists || snapshot.value == null || snapshot.value == "") {
        await _db.child('devices').child(deviceId).child('owner').set(user.uid).timeout(const Duration(seconds: 10));
        return true;
      }
      return snapshot.value == user.uid;
    } catch (e) {
      return false;
    }
  }
}
