import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- NEW: Added Firebase Auth
import '../../../services/session_store.dart';
import '../../../theme/theme_controller.dart';
import '../../../app/routes.dart';
import '../../../app/mock_data.dart';
import '../../../widgets/app_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeController = context.watch<ThemeController>();
    final session = context.watch<SessionStore>();
    final accentColor = isDark
        ? const Color(0xFF00D4AA)
        : const Color(0xFF1976D2);
    final subtextColor = isDark
        ? const Color(0xFF8892B0)
        : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile ──
            _sectionTitle('Profile', isDark),
            const SizedBox(height: 8),
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00695C),
                    ),
                    child: Center(
                      child: Text(
                        session.userName.isNotEmpty
                            ? session.userName[0].toUpperCase()
                            : 'D',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.userName.isNotEmpty
                              ? session.userName
                              : 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          session.userEmail.isNotEmpty ? session.userEmail : '',
                          style: TextStyle(fontSize: 13, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.editProfile);
                },
                icon: Icon(Icons.edit, size: 16, color: accentColor),
                label: Text(
                  'Edit Profile',
                  style: TextStyle(color: accentColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // ── Appearance ──
            _sectionTitle('Appearance', isDark),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          size: 18,
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDark ? 'Dark Mode' : 'Light Mode',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      'Switch between light and dark themes',
                      style: TextStyle(fontSize: 12, color: subtextColor),
                    ),
                  ],
                ),
                Switch(
                  value: isDark,
                  onChanged: (_) => themeController.toggleTheme(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // ── Connection Mode ──
            _sectionTitle('Connection Mode', isDark),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Mode'),
                Text(
                  session.connectionMode.isNotEmpty
                      ? session.connectionMode[0].toUpperCase() +
                            session.connectionMode.substring(1)
                      : 'Offline',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.connectionMode);
                },
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Change Connection Mode'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // ── Device ──
            _sectionTitle('Device', isDark),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDeviceInfoRow(
                        'Device ID:',
                        session.pairedDeviceId.isNotEmpty ? session.pairedDeviceId : 'No Device',
                        subtextColor,
                      ),
                      _buildDeviceInfoRow(
                        'Name:',
                        session.pairedDeviceName.isNotEmpty ? session.pairedDeviceName : 'Unknown',
                        subtextColor,
                      ),
                      _buildDeviceInfoRow(
                        'Status:',
                        'Online',
                        subtextColor,
                        valueColor: accentColor,
                      ),
                      _buildDeviceInfoRow(
                        'Last Sync:',
                        'Just now',
                        subtextColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDeviceButton(Icons.swap_horiz, 'Change Device', context, onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.pairDevice);
                }),
                _buildDeviceButton(Icons.settings, 'Configure WiFi', context, onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.wifiStep1);
                }),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),


            // ── Notifications ──
            _sectionTitle('Notifications', isDark),
            const SizedBox(height: 8),
            _buildNotificationRow(
              Icons.warning,
              'Over Temperature',
              'Alert when temp exceeds limit',
              session.overTempAlert,
              const Color(0xFFEF5350),
              (v) => session.setOverTempAlert(v),
            ),
            _buildNotificationRow(
              Icons.battery_alert,
              'Low Battery',
              'Alert when battery is low',
              session.lowBatteryAlert,
              const Color(0xFFFFA726),
              (v) => session.setLowBatteryAlert(v),
            ),
            _buildNotificationRow(
              Icons.error,
              'Sensor Fault',
              'Alert on sensor errors',
              session.sensorFaultAlert,
              accentColor,
              (v) => session.setSensorFaultAlert(v),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),


            // ── About ──
            _sectionTitle('About', isDark),
            const SizedBox(height: 8),
            _buildAboutRow('App Version:', MockData.appVersion, subtextColor),
            _buildAboutRow(
              'Firmware Version:',
              MockData.firmwareVersion,
              subtextColor,
            ),
            const SizedBox(height: 12),
            _buildTextButton(
              Icons.privacy_tip,
              'Privacy & Security',
              context,
              accentColor,
            ),
            _buildTextButton(
              Icons.help,
              'Help & Support',
              context,
              accentColor,
            ),
            const SizedBox(height: 24),

            // ── Logout ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () async {
                  // NEW: Added Firebase Sign Out logic
                  await FirebaseAuth.instance.signOut(); 
                  session.logout();
                  if (mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF5350),
                  side: const BorderSide(color: Color(0xFFEF5350)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ... (All other helper methods like _sectionTitle, _buildDeviceInfoRow, etc. remain exactly as you provided)
  
  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? const Color(0xFFE6F1FF) : const Color(0xFF1A2D4D),
      ),
    );
  }

  Widget _buildDeviceInfoRow(
    String label,
    String value,
    Color subtextColor, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: subtextColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceButton(IconData icon, String label, BuildContext context, {VoidCallback? onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap ?? () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label not implemented')));
      },
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildNotificationRow(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Color iconColor,
    ValueChanged<bool> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
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
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value, Color subtextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: subtextColor)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTextButton(
    IconData icon,
    String label,
    BuildContext context,
    Color color,
  ) {
    return TextButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label not implemented')));
      },
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color)),
    );
  }
}