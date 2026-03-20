import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/routes.dart';
import '../../../services/session_store.dart';
import '../../../services/wifi_credential_service.dart';
import '../../../widgets/stepper_header.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/mode_toggle_button.dart';
import '../../../services/ble_service.dart';

class WifiSetupBleStep2Page extends StatefulWidget {
  const WifiSetupBleStep2Page({super.key});

  @override
  State<WifiSetupBleStep2Page> createState() => _WifiSetupBleStep2PageState();
}

class ScannedNetwork {
  final String ssid;
  final String quality;
  final bool isSecured;
  final int rssi;

  ScannedNetwork({
    required this.ssid,
    required this.quality,
    required this.isSecured,
    required this.rssi,
  });
}

class _WifiSetupBleStep2PageState extends State<WifiSetupBleStep2Page> {
  String _state = 'idle'; // idle, scanning, results, connecting_saved
  List<ScannedNetwork> _networks = [];
  String? _selectedSsid;
  bool _showHiddenEntry = false;
  final _hiddenSsidController = TextEditingController();
  bool _showScannedNetworks = false;
  bool _isLoadingNetworks = true;
  StreamSubscription<Map<String, dynamic>>? _wifiSubscription;

  @override
  void initState() {
    super.initState();
    _loadSavedNetworks();
    
    // Subscribe to WiFi result stream
    final bleService = context.read<BleService>();
    _wifiSubscription = bleService.wifiResultStream.listen((data) {
      if (!mounted) return;
      if (data['cmd'] == 'WIFI_SCAN_RESULT') {
        final List<dynamic> nets = data['networks'] ?? [];
        final results = nets.map((n) {
          String q = "Weak";
          int rssi = n['r'] ?? -100;
          if (rssi > -60) q = "Excellent";
          else if (rssi > -70) q = "Good";
          else if (rssi > -80) q = "Fair";
          
          return ScannedNetwork(
            ssid: n['s'] ?? 'Unknown',
            quality: q,
            isSecured: n['o'] ?? true, 
            rssi: rssi,
          );
        }).toList();
        
        setState(() {
           _networks = results;
           _state = 'results';
           _showScannedNetworks = true;
        });
      }
    });
  }

  Future<void> _loadSavedNetworks() async {
    if (!mounted) return;
    
    // Add a race condition safety: don't let this hang the whole UI
    
    try {
      final session = context.read<SessionStore>();
      final deviceId = session.pairedDeviceId;
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (deviceId.isNotEmpty) {
         if (userId != null) {
            final wifiService = WifiCredentialService();
            // Don't await this forever
            wifiService.fetchNetworksFromFirebase(userId).timeout(const Duration(seconds: 2)).catchError((_) => <SavedNetwork>[]);
         }
         await session.loadSavedNetworks(deviceId).timeout(const Duration(seconds: 2)).catchError((_) {});
      }
    } catch (e) {
      developer.log("Error loading networks: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNetworks = false;
        });
      }
    }
  }

  // Replaced static connection method with routing to Step 3 (password entry)

  @override
  void dispose() {
    _hiddenSsidController.dispose();
    _wifiSubscription?.cancel();
    super.dispose();
  }

  void _startScan() async {
    setState(() => _state = 'scanning');
    final bleService = context.read<BleService>();
    
    if (!bleService.isConnected) {
      setState(() => _state = 'idle');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device not connected via Bluetooth. Go back and reconnect.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final sent = await bleService.sendScanWifi();
    if (!sent) {
      if (mounted) {
        setState(() => _state = 'idle');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send scan command. Check BLE connection.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }
    
    // Timeout: firmware scan takes up to 12s, give 18s total
    Future.delayed(const Duration(seconds: 18), () {
      if (!mounted) return;
      if (_state == 'scanning') {
         setState(() {
            _state = 'results';
            _showScannedNetworks = true;
         });
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('WiFi scan timed out. Try scanning again.'),
             backgroundColor: Colors.orange,
           ),
         );
      }
    });
  }

  String? get _effectiveSsid {
    if (_showHiddenEntry && _hiddenSsidController.text.trim().isNotEmpty) {
      return _hiddenSsidController.text.trim();
    }
    return _selectedSsid;
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
          const StepperHeader(currentStep: 2),

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
                        if (_isLoadingNetworks)
                           const Center(child: CircularProgressIndicator(), heightFactor: 2)
                        else if (context.watch<SessionStore>().fullSavedNetworks.isNotEmpty) ...[
                           const Text(
                             'Saved Networks',
                             style: TextStyle(
                               fontSize: 18,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                           const SizedBox(height: 16),
                           ...context.watch<SessionStore>().fullSavedNetworks.map((net) => _buildSavedNetworkItem(net, isDark)),
                           const SizedBox(height: 24),
                        ],

                        const Text(
                          'Select WiFi Network',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Scan button
                        PrimaryButton(
                          label: _state == 'scanning'
                              ? 'Scanning...'
                              : 'Scan WiFi Networks',
                          icon: _state == 'scanning' ? null : Icons.wifi,
                          isLoading: _state == 'scanning',
                          onPressed: _state == 'scanning' ? null : _startScan,
                        ),
                        const SizedBox(height: 16),

                        // Show Scanned Networks toggle
                        if (_state == 'results') ...[
                          GestureDetector(
                            onTap: () => setState(
                              () =>
                                  _showScannedNetworks = !_showScannedNetworks,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0D1B2A)
                                    : const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Show Scanned Networks',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: accentColor,
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: _showScannedNetworks ? 0.25 : 0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      Icons.chevron_right,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Network list (collapsible)
                        if ((_state == 'results' || _state == 'scanning') && _showScannedNetworks) ...[
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_state == 'scanning' && _networks.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                else if (_state == 'results' && _networks.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: Text(
                                        'No WiFi networks found.',
                                        style: TextStyle(color: subtextColor),
                                      ),
                                    ),
                                  )
                                else ...[
                                  Text(
                                    'Found ${_networks.length} network(s)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: accentColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._networks.map(
                                    (net) => _buildNetworkItem(net, isDark),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Divider + Hidden Network section
                        const Divider(),
                        const SizedBox(height: 8),

                        // Network Name (SSID) text field — always visible
                        Text(
                          'Network Name (SSID)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFFE6F1FF)
                                : const Color(0xFF1A2D4D),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _hiddenSsidController,
                          onChanged: (v) {
                            setState(() {
                              if (v.trim().isNotEmpty) {
                                _showHiddenEntry = true;
                                _selectedSsid = null; // deselect scanned
                              } else {
                                _showHiddenEntry = false;
                              }
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter network name',
                            prefixIcon: Icon(
                              Icons.wifi,
                              color: subtextColor,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Type a network name manually or use this for hidden networks',
                          style: TextStyle(fontSize: 12, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Navigation buttons
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Back',
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.wifiStep1);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Next: Enter Password  ›',
                          onPressed: _effectiveSsid != null
                              ? () {
                                  Navigator.of(context).pushReplacementNamed(
                                    AppRoutes.wifiStep3,
                                    arguments: _effectiveSsid,
                                  );
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkItem(ScannedNetwork network, bool isDark) {
    final isSelected = _selectedSsid == network.ssid && !_showHiddenEntry;
    final accentColor = isDark
        ? const Color(0xFF00D4AA)
        : const Color(0xFF1976D2);
    final subtextColor = isDark
        ? const Color(0xFF8892B0)
        : const Color(0xFF64748B);

    Color qualityColor;
    switch (network.quality) {
      case 'Excellent':
        qualityColor = const Color(0xFF4CAF50);
        break;
      case 'Good':
        qualityColor = const Color(0xFF66BB6A);
        break;
      case 'Fair':
        qualityColor = const Color(0xFFFFA726);
        break;
      case 'Weak':
        qualityColor = const Color(0xFFEF5350);
        break;
      default:
        qualityColor = subtextColor;
    }

    return GestureDetector(
      onTap: () => setState(() {
        _selectedSsid = network.ssid;
        _showHiddenEntry = false;
        _hiddenSsidController.clear();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? accentColor.withValues(alpha: 0.1)
                    : accentColor.withValues(alpha: 0.05))
              : (isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F7FA)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0E6ED)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi, color: accentColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    network.ssid,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        network.quality,
                        style: TextStyle(fontSize: 12, color: qualityColor),
                      ),
                      Text(
                        '  •  ${_getSignalBars(network.quality)}',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: accentColor, size: 20),
          ],
        ),
      ),
    );
  }

  String _getSignalBars(String quality) {
    switch (quality) {
      case 'Excellent':
        return '▂▄▆█';
      case 'Good':
        return '▂▄▆_';
      case 'Fair':
        return '▂▄__';
      case 'Weak':
        return '▂___';
      default:
        return '____';
    }
  }

  Widget _buildSavedNetworkItem(SavedNetwork network, bool isDark) {
    final accentColor = isDark ? const Color(0xFF00D4AA) : const Color(0xFF1976D2);
    final subtextColor = isDark ? const Color(0xFF8892B0) : const Color(0xFF64748B);
    
    final daysAgo = DateTime.now().difference(network.lastUsed).inDays;
    final timeStr = daysAgo == 0 ? 'Today' : (daysAgo == 1 ? 'Yesterday' : '$daysAgo days ago');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0E6ED),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi, color: accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          network.ssid,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.lock, size: 14, color: subtextColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last used: $timeStr',
                      style: TextStyle(fontSize: 12, color: subtextColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Saved', style: TextStyle(fontSize: 10, color: accentColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Connect',
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(
                  AppRoutes.wifiStep3,
                  arguments: network.ssid,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
