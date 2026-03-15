import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/session_store.dart';
import '../../../app/routes.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/mode_toggle_button.dart';

class ConnectionModePage extends StatefulWidget {
  const ConnectionModePage({super.key});

  @override
  State<ConnectionModePage> createState() => _ConnectionModePageState();
}

class _ConnectionModePageState extends State<ConnectionModePage> {
  String _selectedMode = '';

  void _handleContinue() {
    if (_selectedMode.isEmpty) return;
    final session = context.read<SessionStore>();
    session.setConnectionMode(_selectedMode);

    if (_selectedMode == 'offline') {
      Navigator.of(context).pushNamed(AppRoutes.pairDevice);
    } else {
      // Online mode: go to Pair Device first, then Wi-Fi setup
      Navigator.of(context).pushNamed(AppRoutes.pairDevice);
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
              const SizedBox(height: 8),

              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A3A4D)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.devices, size: 32, color: accentColor),
              ),
              const SizedBox(height: 16),

              Text(
                'Connection Mode',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to connect to\nyour device',
                textAlign: TextAlign.center,
                style: TextStyle(color: subtextColor),
              ),
              const SizedBox(height: 24),

              // Online Mode card
              AppCard(
                isSelected: _selectedMode == 'online',
                onTap: () => setState(() => _selectedMode = 'online'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.wifi,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Online Mode',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connect via WiFi and internet for full functionality',
                      style: TextStyle(color: subtextColor, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      Icons.cloud,
                      'Cloud Sync',
                      'Access data from anywhere',
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem(
                      Icons.wifi,
                      'WiFi Control',
                      'Monitor remotely',
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem(
                      Icons.update,
                      'Real-time Updates',
                      'Live sensor data',
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0D2137)
                            : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: accentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Requires WiFi network and internet connection',
                              style: TextStyle(
                                fontSize: 12,
                                color: subtextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Offline Mode card
              AppCard(
                isSelected: _selectedMode == 'offline',
                onTap: () => setState(() => _selectedMode = 'offline'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFA726), Color(0xFFFF8F00)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bluetooth,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Offline Mode',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Direct Bluetooth connection without internet',
                      style: TextStyle(color: subtextColor, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      Icons.bluetooth,
                      'BLE Control',
                      'Direct device connection',
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem(
                      Icons.check_circle,
                      'No WiFi Needed',
                      'Works anywhere',
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem(
                      Icons.storage,
                      'Local Storage',
                      'Data saved on device',
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0D2137)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: isDark
                                ? const Color(0xFFFFA726)
                                : const Color(0xFFE65100),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Only works within Bluetooth range (~10 meters)',
                              style: TextStyle(
                                fontSize: 12,
                                color: subtextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Continue button
              PrimaryButton(
                label: _selectedMode.isEmpty
                    ? 'Select a mode to continue'
                    : _selectedMode == 'online'
                    ? 'Continue with Online Mode'
                    : 'Continue with Offline Mode',
                onPressed: _selectedMode.isEmpty ? null : _handleContinue,
              ),
              const SizedBox(height: 12),

              // Settings note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF112240)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'You can change this mode later in Settings',
                    style: TextStyle(fontSize: 13, color: subtextColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? const Color(0xFF00D4AA) : const Color(0xFF1976D2),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Text(
              subtitle,
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
    );
  }
}
