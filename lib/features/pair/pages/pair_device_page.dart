import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/session_store.dart';
import '../../../services/ble_service.dart';
import '../../../services/connection_controller.dart';
import '../../../services/device_claim_service.dart';
import '../../../services/device_setup_service.dart';
import '../../../services/firebase_service.dart';
import '../../../app/routes.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/mode_toggle_button.dart';

class PairDevicePage extends StatefulWidget {
  const PairDevicePage({super.key});

  @override
  State<PairDevicePage> createState() => _PairDevicePageState();
}

class _PairDevicePageState extends State<PairDevicePage> {
  bool _isConnecting = false;
  bool _troubleshootExpanded = false;

  void _startScan() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    if (statuses.values.any((status) => status.isDenied)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissions required to scan for Bluetooth devices.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;
    context.read<BleService>().startScan();
  }

  void _connectToDevice(final device) async {
    setState(() => _isConnecting = true);

    try {
      final ble = context.read<BleService>();
      final success = await ble.connect(device);
      
      if (!mounted) return;

      if (success) {
        // [FIX A3] Wait up to 10 seconds (50 * 200ms) for the first state update for safety
        String realDeviceId = "";
        for (int i = 0; i < 50; i++) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (ble.deviceState != null && ble.deviceState!.deviceId.isNotEmpty) {
            realDeviceId = ble.deviceState!.deviceId;
            developer.log("BLE: Captured deviceId: $realDeviceId");
            break;
          }
        }

        final session = context.read<SessionStore>();
        // Use the real device ID from the firmware if available, otherwise fallback to platform name
        final finalId = realDeviceId.isNotEmpty ? realDeviceId : device.platformName;
        
        // 2. REGISTER with Backend: This links the Device ID to your Firebase UID
        // This is what prevents the "Device not found" error on the Start Batch page
        try {
          await DeviceSetupService.registerDeviceWithBackend(finalId);
        } catch (e) {
          developer.log("Backend registration error (non-fatal): $e");
        }

        // 3. Update local session store so the app knows which device is currently active
        // Only if it's not already set correctly
        if (session.deviceId != finalId) {
          session.setPairedDevice(finalId, device.platformName);
        }

        // Claim device in Firebase (sets owner = current user)
        try {
          await DeviceClaimService().claimDevice(finalId);
        } catch (e) {
          developer.log("Device claim error (non-fatal): $e");
        }

        // Initialize Firebase listener with the device ID
        try {
          final fbService = context.read<FirebaseDeviceService>();
          fbService.setDeviceId(finalId);
        } catch (e) {
          developer.log("Firebase init error (non-fatal): $e");
        }

        // Preserve the user's chosen connection mode from the connection mode page
        // Only default to 'offline' if no mode was explicitly selected
        final modeToSet = session.connectionMode.isNotEmpty ? session.connectionMode : 'offline';
        session.setConnectionMode(modeToSet);
        context.read<ConnectionController>().setMode(modeToSet);
        
        Navigator.of(context).pushReplacementNamed(AppRoutes.pairSuccess);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not connect. Try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark
        ? const Color(0xFF00D4AA)
        : const Color(0xFF1976D2);
    final subtextColor = isDark
        ? const Color(0xFF8892B0)
        : const Color(0xFF64748B);

    final ble = context.watch<BleService>();
    final isScanning = ble.status == BleConnectionStatus.scanning;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.topRight,
                child: ModeToggleButton(),
              ),
              const SizedBox(height: 24),

              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark 
                        ? [const Color(0xFF00D4AA), const Color(0xFF00838F)]
                        : [const Color(0xFF00838F), const Color(0xFF006064)],
                  ),
                ),
                child: const Icon(
                  Icons.bluetooth,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Pair Your Device',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connect via Bluetooth to get started',
                style: TextStyle(color: subtextColor, fontSize: 16),
              ),
              const SizedBox(height: 32),

              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: isScanning
                          ? 'Scanning for devices...'
                          : 'Scan for HelaDry Devices',
                      icon: isScanning
                          ? null
                          : Icons.bluetooth_searching,
                      isLoading: isScanning,
                      onPressed: isScanning ? null : _startScan,
                    ),
                    const SizedBox(height: 16),

                    if (!isScanning && ble.scanResults.isEmpty) ...[
                      Icon(
                        Icons.bluetooth,
                        size: 40,
                        color: subtextColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No devices found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: subtextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Make sure your device is powered on and nearby',
                        style: TextStyle(
                          fontSize: 13,
                          color: subtextColor.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    if (ble.scanResults.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Found ${ble.scanResults.length} device(s) nearby',
                          style: TextStyle(
                            fontSize: 14,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...ble.scanResults.map(
                        (result) => _buildDeviceItem(result, isDark),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              AppCard(
                onTap: () {
                  setState(
                    () => _troubleshootExpanded = !_troubleshootExpanded,
                  );
                },
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _troubleshootExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: subtextColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Having trouble?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFE6F1FF)
                                : const Color(0xFF1A2D4D),
                          ),
                        ),
                      ],
                    ),
                    if (_troubleshootExpanded) ...[
                      const SizedBox(height: 12),
                      _buildTroubleshootItem(
                        '1. Make sure your HelaDry device is powered on',
                      ),
                      _buildTroubleshootItem(
                        '2. Ensure Bluetooth is enabled on your phone',
                      ),
                      _buildTroubleshootItem(
                        '3. Stay within 10 meters of the device',
                      ),
                      _buildTroubleshootItem(
                        '4. Try restarting the device if not found',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceItem(final result, bool isDark) {
    final accentColor = isDark
        ? const Color(0xFF00D4AA)
        : const Color(0xFF1976D2);

    Color qualityColor = const Color(0xFF4CAF50);
    if (result.rssi < -80) qualityColor = const Color(0xFFEF5350);
    else if (result.rssi < -60) qualityColor = const Color(0xFFFFA726);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0E6ED),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.bluetooth, color: accentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.device.platformName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.signal_cellular_alt,
                      size: 12,
                      color: qualityColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${result.rssi} dBm',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF8892B0)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isConnecting) ...[
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.link, color: accentColor),
              onPressed: () => _connectToDevice(result.device),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTroubleshootItem(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? const Color(0xFF8892B0) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}