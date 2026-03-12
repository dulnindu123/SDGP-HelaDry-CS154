import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../app/routes.dart';
import '../../../services/device_transport.dart';
import 'dart:convert';
import 'dart:async';
import '../../../widgets/stepper_header.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/mode_toggle_button.dart';

class WifiSetupBleStep2Page extends StatefulWidget {
  const WifiSetupBleStep2Page({super.key});

  @override
  State<WifiSetupBleStep2Page> createState() => _WifiSetupBleStep2PageState();
}

class BleWifiNetwork {
  final String ssid;
  final String quality;
  final int rssi;

  const BleWifiNetwork({
    required this.ssid,
    required this.quality,
    required this.rssi,
  });
}

class _WifiSetupBleStep2PageState extends State<WifiSetupBleStep2Page> {
  String _state = 'idle'; // idle, scanning, results
  List<BleWifiNetwork> _networks = [];
  String? _selectedSsid;
  bool _showHiddenEntry = false;
  final _hiddenSsidController = TextEditingController();
  bool _showScannedNetworks = false;
  StreamSubscription? _ackSub;

  @override
  void dispose() {
    _hiddenSsidController.dispose();
    _ackSub?.cancel();
    super.dispose();
  }

  void _startScan() async {
    setState(() => _state = 'scanning');
    
    _ackSub?.cancel();
    _ackSub = DeviceTransport().ble.ackStream.listen((jsonStr) {
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded['cmd'] == 'SCAN_WIFI' && decoded['status'] == 'done') {
          final nets = (decoded['networks'] as List).map((n) {
             final rssi = n['rssi'] as int;
             String qual = 'Weak';
             if (rssi > -60) qual = 'Excellent';
             else if (rssi > -70) qual = 'Good';
             else if (rssi > -85) qual = 'Fair';
             return BleWifiNetwork(ssid: n['ssid'], rssi: rssi, quality: qual);
          }).toList();
          
          if (!mounted) return;
          setState(() {
            _networks = nets;
            _state = 'results';
            _showScannedNetworks = true;
          });
        } else if (decoded['cmd'] == 'SCAN_WIFI') {
           if (!mounted) return;
           setState(() => _state = 'idle');
        }
      } catch(e) {}
    });

    DeviceTransport().sendCommand("SCAN_WIFI");
    
    Future.delayed(const Duration(seconds: 15), () {
      if (!mounted) return;
      if (_state == 'scanning') {
         setState(() {
           _state = _networks.isNotEmpty ? 'results' : 'idle';
         });
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
                        if (_state == 'results' && _showScannedNetworks) ...[
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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

  Widget _buildNetworkItem(BleWifiNetwork network, bool isDark) {
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
}
