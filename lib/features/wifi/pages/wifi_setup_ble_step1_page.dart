import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../widgets/stepper_header.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/mode_toggle_button.dart';

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
    _simulateBleConnect();
  }

  Future<void> _simulateBleConnect() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isScanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark
        ? const Color(0xFF8892B0)
        : const Color(0xFF64748B);

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
                          label: 'Scanning for devices...',
                          isLoading: _isScanning,
                          onPressed: null,
                        ),
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
