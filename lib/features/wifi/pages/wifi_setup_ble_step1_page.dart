import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../widgets/stepper_header.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/mode_toggle_button.dart';
import '../../../services/ble_service.dart';
import '../../../services/session_store.dart';

class WifiSetupBleStep1Page extends StatefulWidget {
  const WifiSetupBleStep1Page({super.key});

  @override
  State<WifiSetupBleStep1Page> createState() => _WifiSetupBleStep1PageState();
}

class _WifiSetupBleStep1PageState extends State<WifiSetupBleStep1Page> {
  bool _isScanning = true;
  bool _troubleshootExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAlreadyConnected();
      _connectToPairedDevice();
    });
  }

  void _checkAlreadyConnected() {
    final ble = context.read<BleService>();

    if (ble.isConnected) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.wifiStep2);
      }
    }
  }

  void _onBleUpdate() {
    if (!mounted) return;
    final ble = context.read<BleService>();
    final session = context.read<SessionStore>();
    final targetId = session.pairedDeviceId;

    if (targetId.isNotEmpty) {
      final results = ble.scanResults.where((r) =>
          (r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : r.advertisementData.advName) ==
              targetId ||
          r.device.remoteId.str == targetId);

      if (results.isNotEmpty) {
        final match = results.first;
        context.read<BleService>().removeListener(_onBleUpdate);
        _timeout?.cancel();
        _performConnect(match.device);
      }
    } else {
      // If no targetId, look for ANY HelaDry device to help the user
      final results = ble.scanResults;
      if (results.isNotEmpty) {
        final match = results.first;
        context.read<BleService>().removeListener(_onBleUpdate);
        _timeout?.cancel();
        _performConnect(match.device);
      }
    }
  }

  Timer? _timeout;

  Future<void> _connectToPairedDevice() async {
    final ble = context.read<BleService>();
    final session = context.read<SessionStore>();
    final targetId = session.pairedDeviceId;

    if (targetId.isEmpty) {
      if (mounted) setState(() => _isScanning = false);
      return;
    }

    // 1. If already connected to the right device, skip scan
    if (ble.isConnected &&
        (ble.connectedDeviceName == targetId ||
            ble.connectedDeviceId == targetId)) {
      if (mounted) setState(() => _isScanning = false);
      return;
    }

    // 2. Otherwise, start a scan
    setState(() => _isScanning = true);

    // The BleService.startScan now handles permission requests internally
    ble.addListener(_onBleUpdate);
    await ble.startScan();

    _timeout = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        ble.removeListener(_onBleUpdate);
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device not found. Please try again.')),
        );
      }
    });
  }

  Future<void> _performConnect(dynamic device) async {
    final ble = context.read<BleService>();
    final success = await ble.connect(device);
    if (mounted) {
      setState(() => _isScanning = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to device.')),
        );
      }
    }
  }

  @override
  void dispose() {
    context.read<BleService>().removeListener(_onBleUpdate);
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor =
        isDark ? const Color(0xFF8892B0) : const Color(0xFF64748B);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF00695C),
                        const Color(0xFF004D40),
                        const Color(0xFF0A1628),
                      ]
                    : [
                        const Color(0xFF26A69A),
                        const Color(0xFF00897B),
                        const Color(0xFF1976D2),
                      ],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bluetooth, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Wi-Fi Setup',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Connect your device to WiFi via Bluetooth',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const ModeToggleButton(),
              ],
            ),
          ),

          // Stepper
          const StepperHeader(currentStep: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connect to Device via Bluetooth',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: _isScanning
                              ? 'Scanning...'
                              : 'Scan for HelaDry Device',
                          isLoading: _isScanning,
                          icon: _isScanning ? null : Icons.bluetooth_searching,
                          onPressed:
                              _isScanning ? null : _connectToPairedDevice,
                        ),
                        if (!_isScanning &&
                            context
                                .read<BleService>()
                                .scanResults
                                .isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Found devices:',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          ...context
                              .read<BleService>()
                              .scanResults
                              .map((r) => ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.bluetooth,
                                        size: 20, color: Colors.blue),
                                    title: Text(r.device.platformName.isNotEmpty
                                        ? r.device.platformName
                                        : r.advertisementData.advName),
                                    trailing: const Icon(Icons.link, size: 20),
                                    onTap: () => _performConnect(r.device),
                                  )),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Troubleshooting
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
                            const Text(
                              'Troubleshooting',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (_troubleshootExpanded) ...[
                          const SizedBox(height: 12),
                          Text(
                            '• Make sure Bluetooth is enabled\n'
                            '• Keep your phone near the device\n'
                            '• Restart the device if needed',
                            style: TextStyle(fontSize: 13, color: subtextColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  PrimaryButton(
                    label: 'Next: Scan WiFi Networks  ›',
                    onPressed: _isScanning
                        ? null
                        : () {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.wifiStep2);
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
