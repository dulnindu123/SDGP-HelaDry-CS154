import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/session_store.dart';
import '../../../app/routes.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/mode_toggle_button.dart';

class PairSuccessPage extends StatelessWidget {
  const PairSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionStore>();
    final subtextColor = isDark
        ? const Color(0xFF8892B0)
        : const Color(0xFF64748B);
    final accentColor = isDark
        ? const Color(0xFF00D4AA)
        : const Color(0xFF1976D2);
    final now = TimeOfDay.now();
    final timeString =
        '${now.hour}:${now.minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')} ${now.period == DayPeriod.am ? 'AM' : 'PM'}';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Top-right theme toggle
              Align(
                alignment: Alignment.topRight,
                child: const ModeToggleButton(),
              ),
              const Spacer(),

              // Success icon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0D2818)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.green.withValues(alpha: 0.1),
                        border: Border.all(
                          color: const Color(0xFF4CAF50),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 40,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Device Paired\nSuccessfully!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connected via Bluetooth',
                      style: TextStyle(color: subtextColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Device info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF112240) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF1E3A5F)
                        : const Color(0xFFE0E6ED),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF1A2D4D)
                                : const Color(0xFFE8EDF5),
                          ),
                          child: Icon(
                            Icons.bluetooth,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.pairedDeviceId.isNotEmpty
                                  ? session.pairedDeviceId
                                  : 'HELADRY-A1B2',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              session.pairedDeviceId.isNotEmpty
                                  ? session.pairedDeviceId
                                  : 'HELADRY-A1B2',
                              style: TextStyle(
                                fontSize: 13,
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bluetooth_connected,
                              size: 14,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'BLE Connected',
                              style: TextStyle(
                                fontSize: 13,
                                color: accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          timeString,
                          style: TextStyle(fontSize: 13, color: subtextColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Continue button
              PrimaryButton(
                label: 'Continue',
                onPressed: () {
                  if (session.connectionMode == 'online') {
                    Navigator.of(
                      context,
                    ).pushReplacementNamed(AppRoutes.wifiStep1);
                  } else {
                    Navigator.of(
                      context,
                    ).pushReplacementNamed(AppRoutes.dashboard);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
