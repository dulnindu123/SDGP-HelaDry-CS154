import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/session_store.dart';
import '../../../services/wifi_credential_service.dart';
import '../../../widgets/app_card.dart';

class SavedNetworksPage extends StatelessWidget {
  const SavedNetworksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionStore>();
    final networks = session.fullSavedNetworks;

    final accentColor =
        isDark ? const Color(0xFF00D4AA) : const Color(0xFF1976D2);
    final subtextColor =
        isDark ? const Color(0xFF8892B0) : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Networks',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: networks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off,
                      size: 64, color: subtextColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No saved networks yet',
                    style: TextStyle(color: subtextColor, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: networks.length + 1, // +1 for the Clear All button
              itemBuilder: (context, index) {
                if (index == networks.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: OutlinedButton(
                      onPressed: () => _clearAllNetworks(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Clear All Saved Networks',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                }

                final net = networks[index];
                final daysAgo = DateTime.now().difference(net.lastUsed).inDays;
                final timeStr = daysAgo == 0
                    ? 'Used today'
                    : (daysAgo == 1
                        ? 'Used yesterday'
                        : 'Used $daysAgo days ago');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.wifi, color: accentColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                net.ssid,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                '$timeStr • ID: ${net.deviceId}',
                                style: TextStyle(
                                    fontSize: 12, color: subtextColor),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => _forgetNetwork(context, net),
                          tooltip: 'Forget Network',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _forgetNetwork(BuildContext context, SavedNetwork net) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final wifiService = WifiCredentialService();
      await wifiService.forgetNetwork(net.ssid, net.deviceId, userId);

      if (context.mounted) {
        final session = context.read<SessionStore>();
        if (session.pairedDeviceId.isNotEmpty) {
          await session.loadSavedNetworks(session.pairedDeviceId);
        }
      }
    }
  }

  void _clearAllNetworks(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Networks?'),
        content: const Text(
            'This will remove all saved Wi-Fi credentials from your account and device history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final wifiService = WifiCredentialService();
        await wifiService.clearAll(userId);

        if (context.mounted) {
          final session = context.read<SessionStore>();
          if (session.pairedDeviceId.isNotEmpty) {
            await session.loadSavedNetworks(session.pairedDeviceId);
          }
        }
      }
    }
  }
}
