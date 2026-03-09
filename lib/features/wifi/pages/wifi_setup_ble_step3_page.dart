import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/session_store.dart';
import '../../../services/mock_wifi_service.dart';
import '../../../app/routes.dart';
import '../../../widgets/stepper_header.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/mode_toggle_button.dart';

class WifiSetupBleStep3Page extends StatefulWidget {
  const WifiSetupBleStep3Page({super.key});

  @override
  State<WifiSetupBleStep3Page> createState() => _WifiSetupBleStep3PageState();
}

class _WifiSetupBleStep3PageState extends State<WifiSetupBleStep3Page> {
  final _passwordController = TextEditingController();
  final _ssidController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberNetwork = true;
  bool _isConnecting = false;
  String _selectedSsid = '';
  bool _isHiddenNetwork = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      _selectedSsid = args;
    }
    if (_selectedSsid.isEmpty) {
      _selectedSsid = 'Home WiFi';
    }
    // If this is a hidden/manual entry, let user edit the SSID
    _isHiddenNetwork =
        _selectedSsid == 'Hidden Network' ||
        !_isKnownScannedNetwork(_selectedSsid);
    if (_isHiddenNetwork) {
      _ssidController.text = _selectedSsid == 'Hidden Network'
          ? ''
          : _selectedSsid;
    }
  }

  bool _isKnownScannedNetwork(String ssid) {
    // Known mock network SSIDs from MockData
    final known = ['Home WiFi', 'Office_5G', 'TP-Link_8842', 'Guest_Free'];
    return known.contains(ssid);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _ssidController.dispose();
    super.dispose();
  }

  void _handleSendToDevice() async {
    final effectiveSsid = _isHiddenNetwork
        ? _ssidController.text.trim()
        : _selectedSsid;

    if (_passwordController.text.isEmpty) return;
    if (_isHiddenNetwork && effectiveSsid.isEmpty) return;

    setState(() => _isConnecting = true);

    await MockWifiService.connectToNetwork(
      effectiveSsid,
      _passwordController.text,
    );

    if (!mounted) return;
    final session = context.read<SessionStore>();
    session.setSelectedWifi(effectiveSsid);
    session.markWifiConfigured();
    if (_rememberNetwork) {
      session.saveNetwork(effectiveSsid);
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
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
          const StepperHeader(currentStep: 3),

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
                          'Enter WiFi Credentials',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Network display
                        if (_isHiddenNetwork) ...[
                          // Editable SSID for hidden/manual networks
                          AppTextField(
                            label: 'Network Name (SSID)',
                            hint: 'Enter the network name',
                            controller: _ssidController,
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          // Read-only display for scanned network
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? accentColor.withValues(alpha: 0.1)
                                  : accentColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.wifi, color: accentColor, size: 20),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedSsid,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Secured network',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subtextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        AppTextField(
                          label: 'Password',
                          hint: 'Enter WiFi password',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          showToggle: true,
                          onToggleObscure: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Remember network
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberNetwork,
                                onChanged: (v) =>
                                    setState(() => _rememberNetwork = v!),
                                activeColor: accentColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Remember this network'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        PrimaryButton(
                          label: 'Send to Device  ›',
                          isLoading: _isConnecting,
                          onPressed: _handleSendToDevice,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SecondaryButton(
                    label: 'Back to Network Selection',
                    onPressed: () {
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
