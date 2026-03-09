import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/session_store.dart';
import '../../../services/mock_device_service.dart';
import '../../../app/routes.dart';
import '../../../app/mock_data.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/mode_toggle_button.dart';

class PairDevicePage extends StatefulWidget {
  const PairDevicePage({super.key});

  @override
  State<PairDevicePage> createState() => _PairDevicePageState();
}

class _PairDevicePageState extends State<PairDevicePage> {
  // idle, scanning, results
  String _state = 'idle';
  List<MockDevice> _devices = [];
  bool _isConnecting = false;
  bool _troubleshootExpanded = false;

  void _startScan() async {
    setState(() => _state = 'scanning');
    final devices = await MockDeviceService.scanForDevices();
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _state = 'results';
    });
  }

  void _connectToDevice(MockDevice device) async {
    setState(() => _isConnecting = true);
    await MockDeviceService.connectToDevice(device.name);
    if (!mounted) return;
    final session = context.read<SessionStore>();
    session.setPairedDevice(device.name, 'HelaDry');
    Navigator.of(context).pushReplacementNamed(AppRoutes.pairSuccess);
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Top-right theme toggle
              Align(
                alignment: Alignment.topRight,
                child: const ModeToggleButton(),
              ),
              const SizedBox(height: 24),

              // Bluetooth icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00838F), Color(0xFF006064)],
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

              // Scan card
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Scan button
                    PrimaryButton(
                      label: _state == 'scanning'
                          ? 'Scanning for devices...'
                          : 'Scan for HelaDry Devices',
                      icon: _state == 'scanning'
                          ? null
                          : Icons.bluetooth_searching,
                      isLoading: _state == 'scanning',
                      onPressed: _state == 'scanning' ? null : _startScan,
                    ),
                    const SizedBox(height: 16),

                    // State-specific content
                    if (_state == 'idle') ...[
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

                    if (_state == 'results') ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Found ${_devices.length} device(s) nearby',
                          style: TextStyle(
                            fontSize: 14,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._devices.map(
                        (device) => _buildDeviceItem(device, isDark),
                      ),
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

  Widget _buildDeviceItem(MockDevice device, bool isDark) {
    final accentColor = isDark
        ? const Color(0xFF00D4AA)
        : const Color(0xFF1976D2);

    Color qualityColor;
    switch (device.quality) {
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
        qualityColor = const Color(0xFF8892B0);
    }

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
                  device.name,
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
                      '${device.quality}  •  ${device.rssi} dBm',
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
              onPressed: () => _connectToDevice(device),
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
