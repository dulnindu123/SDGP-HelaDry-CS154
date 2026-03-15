import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/session_store.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/primary_button.dart';

class ManualControlsPage extends StatefulWidget {
  const ManualControlsPage({super.key});

  @override
  State<ManualControlsPage> createState() => _ManualControlsPageState();
}

class _ManualControlsPageState extends State<ManualControlsPage> {
  double _fanSpeed = 50;
  bool _heaterOn = false;
  double _targetTemp = 55;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionStore>();
    _fanSpeed = session.fanSpeed;
    _heaterOn = session.heaterOn;
    _targetTemp = session.targetTemp;
  }

  void _applyFanSpeed() {
    final session = context.read<SessionStore>();
    session.setFanSpeed(_fanSpeed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fan speed set to ${_fanSpeed.toStringAsFixed(0)}%'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _applyTemperature() {
    final session = context.read<SessionStore>();
    session.setTargetTemp(_targetTemp);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Target temperature set to ${_targetTemp.toStringAsFixed(0)}°C',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _emergencyStop() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency Stop'),
        content: const Text(
          'Are you sure you want to stop all operations immediately?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final session = context.read<SessionStore>();
              session.emergencyStop();
              setState(() {
                _fanSpeed = 0;
                _heaterOn = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency stop activated!'),
                  backgroundColor: Color(0xFFEF5350),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
            ),
            child: const Text(
              'Stop All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manual Controls',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Direct device control',
              style: TextStyle(fontSize: 13, color: subtextColor),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Warning banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3E2723)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFFFA726)
                      : const Color(0xFFFFB74D),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Color(0xFFFFA726),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Manual controls override automatic settings. Use with caution.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFFFFA726)
                            : const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Fan Speed Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.15),
                        ),
                        child: Icon(Icons.toys, color: accentColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fan Speed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Adjust airflow',
                            style: TextStyle(fontSize: 13, color: subtextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0%',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                      Text(
                        '${_fanSpeed.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        '100%',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                    ],
                  ),
                  Slider(
                    value: _fanSpeed,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: accentColor,
                    onChanged: (v) => setState(() => _fanSpeed = v),
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: 'Apply Fan Speed',
                    onPressed: _applyFanSpeed,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Heater Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  (_heaterOn
                                          ? const Color(0xFFEF5350)
                                          : subtextColor)
                                      .withValues(alpha: 0.15),
                            ),
                            child: Icon(
                              Icons.local_fire_department,
                              color: _heaterOn
                                  ? const Color(0xFFEF5350)
                                  : subtextColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Heater',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Auxiliary heating',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _heaterOn,
                        onChanged: (v) {
                          setState(() => _heaterOn = v);
                          final session = context.read<SessionStore>();
                          session.setHeaterOn(v);
                        },
                      ),
                    ],
                  ),
                  if (_heaterOn) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Target Temperature',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '35°C',
                          style: TextStyle(fontSize: 12, color: subtextColor),
                        ),
                        Text(
                          '${_targetTemp.toStringAsFixed(0)}°C',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEF5350),
                          ),
                        ),
                        Text(
                          '80°C',
                          style: TextStyle(fontSize: 12, color: subtextColor),
                        ),
                      ],
                    ),
                    Slider(
                      value: _targetTemp,
                      min: 35,
                      max: 80,
                      divisions: 45,
                      activeColor: const Color(0xFFEF5350),
                      onChanged: (v) => setState(() => _targetTemp = v),
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: 'Apply Temperature',
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      onPressed: _applyTemperature,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Emergency Controls
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFFEF5350,
                          ).withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.power_settings_new,
                          color: Color(0xFFEF5350),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emergency Controls',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Immediate shutdown',
                            style: TextStyle(fontSize: 13, color: subtextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _emergencyStop,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF5350),
                        side: const BorderSide(
                          color: Color(0xFFEF5350),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Emergency Stop All',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Changes will be sent to the device immediately',
              style: TextStyle(fontSize: 13, color: subtextColor),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
