import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/session_store.dart';
import '../../../services/connection_controller.dart';
import '../../../services/firebase_service.dart';
import '../../../services/ble_service.dart';
import '../../../services/device_setup_service.dart';
import 'dart:convert';
import 'dart:async';
import '../../../app/routes.dart';
import '../../../services/api_service.dart';
import '../../../widgets/stepper_header.dart';
import '../../../widgets/primary_button.dart';
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

    final ble = context.watch<BleService>();
    if (ble.deviceState != null && ble.deviceState!.wifiConnected) {
       final ip = ble.deviceState!.ip;
       final deviceId = ble.deviceState!.deviceId.isNotEmpty 
           ? ble.deviceState!.deviceId 
           : context.read<SessionStore>().pairedDeviceId;

       if (ip.isNotEmpty && _selectedSsid.isEmpty) {
         context.read<ApiService>().setBaseUrl(ip);
         
         // Auto-redirect ONLY if we don't have a specific SSID to connect to
         WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              if (deviceId.isNotEmpty) {
                context.read<ConnectionController>().activateOnlineMode(deviceId);
              }
              Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
            }
         });
       }
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
    // Check SSID from SessionStore.fullSavedNetworks or any other source if needed.
    // For now, if we got it from Step 2, it's "known".
    // [FIX] Don't check BLE scan results for WiFi SSID.
    return ssid.isNotEmpty && ssid != 'Hidden Network';
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

    final bleService = context.read<BleService>();
    final controller = context.read<ConnectionController>();

    if (!bleService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device not connected. Please go back and reconnect.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isConnecting = true);

    // Subscribe to ACK BEFORE sending
    StreamSubscription<String>? ackSubscription;
    bool handled = false;

    // 1. Start Timeout fallback (20s) - wrap EVERYTHING
    final timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (!handled && mounted) {
        handled = true;
        ackSubscription?.cancel();
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WiFi connection timed out. Check device distance.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    ackSubscription = bleService.ackStream.listen((ackJson) async {
      if (handled) return;
      try {
        final data = jsonDecode(ackJson);
        
        // Immediate feedback: credentials received by device
        if (data['cmd'] == 'SET_WIFI_CREDS' && data['status'] == 'received') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 12),
                    Text('Credentials received! Device is connecting...'),
                  ],
                ),
                duration: Duration(seconds: 4),
              ),
            );
          }
        }

        if (data['cmd'] == 'WIFI_CONNECT_RESULT') {
          handled = true;
          timeoutTimer.cancel();
          ackSubscription?.cancel();
          
          final status = data['status'];
          if (status == 'connected') {
            if (!mounted) return;
            final ip = data['ip'] ?? '';
            
            // [FIX] Update ApiService with the real IP reported by the device
            if (ip.isNotEmpty) {
              final api = context.read<ApiService>();
              api.setBaseUrl(ip);
            }

            final session = context.read<SessionStore>();
            session.setSelectedWifi(effectiveSsid);
            session.markWifiConfigured();
            
            final deviceId = session.pairedDeviceId;
            final userId = FirebaseAuth.instance.currentUser?.uid;
            
            if (userId != null && deviceId.isNotEmpty) {
              
              if (_rememberNetwork) {
                try {
                  await session.saveNetwork(effectiveSsid, deviceId, userId: userId);
                } catch (e) {
                  developer.log("Error saving network: $e");
                }
              }
              
              try {
                if (!mounted) return;
                final fbDeviceService = context.read<FirebaseDeviceService>();
                await fbDeviceService.writeWifiConfig(effectiveSsid, ip);
              } catch (e) {
                developer.log("Error writing WiFi config to Firebase: $e");
              }
              
              // [NEW] Verify registration with backend one more time just in case
              try {
                await DeviceSetupService.registerDeviceWithBackend(deviceId);
              } catch (e) {
                developer.log("Backend registration refresh error: $e");
              }
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Connected! IP: $ip'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }

            if (!mounted) return;
            setState(() => _isConnecting = false);
            
            // [FIX A11] Automatically switch to Online Mode now that device is on WiFi
            final controller = context.read<ConnectionController>();
            controller.activateOnlineMode(deviceId);
            
            Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
            
          } else {
            // failed
            final reason = data['reason'] ?? 'Unknown error';
            if (!mounted) return;
            setState(() => _isConnecting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('WiFi Connection Failed: $reason'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      } catch (e) {
        // ignore JSON parse errors
      }
    });

    final sent = await controller.sendWifiCredentials(effectiveSsid, _passwordController.text);
    if (!sent) {
      if (handled) return;
      handled = true;
      timeoutTimer.cancel();
      ackSubscription.cancel();
      if (mounted) {
         setState(() => _isConnecting = false);
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Failed to send credentials. Check connection.'),
             backgroundColor: Colors.redAccent,
           ),
         );
      }
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
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.wifiStep2);
                  },
                ),
                const SizedBox(width: 8),
                const Icon(Icons.wifi, color: Colors.white),
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
                        'Enter password to connect your device',
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

                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  PrimaryButton(
                    label: 'Send to Device  ›',
                    isLoading: _isConnecting,
                    onPressed: _handleSendToDevice,
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
