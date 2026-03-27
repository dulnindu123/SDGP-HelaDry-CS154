import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class SavedNetwork {
  final String ssid;
  final String deviceId;
  final DateTime lastUsed;
  final int timesUsed;

  SavedNetwork({
    required this.ssid,
    required this.deviceId,
    required this.lastUsed,
    required this.timesUsed,
  });

  Map<String, dynamic> toJson() => {
        'ssid': ssid,
        'deviceId': deviceId,
        'lastUsed': lastUsed.millisecondsSinceEpoch,
        'timesUsed': timesUsed,
      };

  factory SavedNetwork.fromJson(Map<String, dynamic> json) {
    return SavedNetwork(
      ssid: json['ssid'] ?? '',
      deviceId: json['deviceId'] ?? '',
      lastUsed: DateTime.fromMillisecondsSinceEpoch(json['lastUsed'] ?? 0),
      timesUsed: json['timesUsed'] ?? 0,
    );
  }
}

class WifiCredentialService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  
  // Save network locally and to Firebase (WITHOUT PASSWORD)
  Future<void> saveNetwork(String ssid, String deviceId, String userId) async {
    final newNetwork = SavedNetwork(
      ssid: ssid,
      deviceId: deviceId,
      lastUsed: DateTime.now(),
      timesUsed: 1,
    );
    
    // 1. Save locally
    List<SavedNetwork> networks = await _getLocalNetworks();
    final index = networks.indexWhere((n) => n.ssid == ssid && n.deviceId == deviceId);
    if (index >= 0) {
      final oldNetwork = networks[index];
      networks[index] = SavedNetwork(
        ssid: ssid,
        deviceId: deviceId,
        lastUsed: DateTime.now(),
        timesUsed: oldNetwork.timesUsed + 1,
      );
    } else {
      networks.add(newNetwork);
    }
    
    await _saveLocalNetworks(networks);
    
    // 2. Save to Firebase
    final sanitizedSsid = _sanitizePath(ssid);
    await _db.child('users').child(userId).child('networks').child(sanitizedSsid).update({
      'ssid': ssid,
      'deviceId': deviceId,
      'lastUsed': ServerValue.timestamp,
      'timesUsed': ServerValue.increment(1),
    });
    // Set addedAt only if not exists (using a separate call or just letting it be omitted for updates)
    // A simpler way: just let it update. We'll add 'addedAt' logic here roughly:
    final snapshot = await _db.child('users').child(userId).child('networks').child(sanitizedSsid).child('addedAt').get();
    if (!snapshot.exists) {
      await _db.child('users').child(userId).child('networks').child(sanitizedSsid).update({
        'addedAt': ServerValue.timestamp,
      });
    }
    
    // 3. Update device pairing info
    await _db.child('users').child(userId).child('devices').child(deviceId).update({
      'deviceId': deviceId,
      'bleName': 'HELADRY-$deviceId', 
      'lastSsid': ssid,
      'lastSeen': ServerValue.timestamp,
    });
    
    final devicePairingSnapshot = await _db.child('users').child(userId).child('devices').child(deviceId).child('pairedAt').get();
    if (!devicePairingSnapshot.exists) {
        await _db.child('users').child(userId).child('devices').child(deviceId).update({
            'pairedAt': ServerValue.timestamp,
        });
    }
  }
  
  // Get all saved networks for a device
  Future<List<SavedNetwork>> getSavedNetworks(String deviceId) async {
    final networks = await _getLocalNetworks();
    final filtered = networks.where((n) => n.deviceId == deviceId).toList();
    filtered.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    return filtered;
  }
  
  // Get all saved networks from Firebase for this user
  Future<List<SavedNetwork>> fetchNetworksFromFirebase(String userId) async {
    try {
      final snapshot = await _db.child('users').child(userId).child('networks').get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        List<SavedNetwork> list = [];
        data.forEach((key, value) {
          list.add(SavedNetwork.fromJson(Map<String, dynamic>.from(value)));
        });
        
        // Sync locally
        final prefs = await SharedPreferences.getInstance();
        final jsonList = list.map((n) => jsonEncode(n.toJson())).toList();
        await prefs.setStringList('saved_networks', jsonList);
        
        list.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
        return list;
      }
    } catch (e) {
      debugPrint("Error fetching from Firebase: $e");
    }
    
    final locals = await _getLocalNetworks();
    locals.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    return locals;
  }
  
  // Delete a saved network
  Future<void> forgetNetwork(String ssid, String deviceId, String userId) async {
    final networks = await _getLocalNetworks();
    networks.removeWhere((n) => n.ssid == ssid && n.deviceId == deviceId);
    await _saveLocalNetworks(networks);
    
    final sanitizedSsid = _sanitizePath(ssid);
    await _db.child('users').child(userId).child('networks').child(sanitizedSsid).remove();
    
    // Also tell the firmware to clear stored WiFi credentials via Firebase
    await _db.child('devices').child(deviceId).child('commands').update({
      'clear_wifi_creds': true,
    });
  }
  
  // Clear all saved networks
  Future<void> clearAll(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_networks');
    
    await _db.child('users').child(userId).child('networks').remove();
  }
  
  // Check if a network is already saved
  Future<bool> isNetworkSaved(String ssid, String deviceId) async {
    final networks = await _getLocalNetworks();
    return networks.any((n) => n.ssid == ssid && n.deviceId == deviceId);
  }
  
  // Update last used timestamp
  Future<void> updateLastUsed(String ssid, String deviceId, String userId) async {
    List<SavedNetwork> networks = await _getLocalNetworks();
    final index = networks.indexWhere((n) => n.ssid == ssid && n.deviceId == deviceId);
    if (index >= 0) {
      final old = networks[index];
      networks[index] = SavedNetwork(
        ssid: old.ssid,
        deviceId: old.deviceId,
        lastUsed: DateTime.now(),
        timesUsed: old.timesUsed + 1,
      );
      await _saveLocalNetworks(networks);
    }
    
    final sanitizedSsid = _sanitizePath(ssid);
    await _db.child('users').child(userId).child('networks').child(sanitizedSsid).update({
      'lastUsed': ServerValue.timestamp,
      'timesUsed': ServerValue.increment(1),
    });
  }
  
  // Helpers
  Future<List<SavedNetwork>> _getLocalNetworks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_networks') ?? [];
    return list.map((e) => SavedNetwork.fromJson(jsonDecode(e))).toList();
  }
  
  Future<void> _saveLocalNetworks(List<SavedNetwork> networks) async {
    final prefs = await SharedPreferences.getInstance();
    final list = networks.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('saved_networks', list);
  }
  
  String _sanitizePath(String path) {
    return path.replaceAll(RegExp(r'[.#$\[\]]'), '_');
  }
}
