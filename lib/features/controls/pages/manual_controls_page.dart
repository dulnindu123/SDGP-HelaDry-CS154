import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/session_store.dart';
import '../../../services/device_transport.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/primary_button.dart';

class ManualControlsPage extends StatefulWidget {
  const ManualControlsPage({super.key});

  @override
  State<ManualControlsPage> createState() => _ManualControlsPageState();
}

class _ManualControlsPageState extends State<ManualControlsPage> {
  bool _heaterOn = false;
  double _targetTemp = 55;
  late double _defaultTemp;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionStore>();
    _heaterOn = session.heaterOn;
    _targetTemp = session.targetTemp;
    // Store default values from active batch
    _defaultTemp = (session.activeBatch?['target_temp'] ?? session.activeBatch?['temperature'] ?? 55).toDouble();
    
    developer.log('Manual Controls Init - Default Temp=$_defaultTemp, Current Temp=$_targetTemp');
  }

  void _applyFanSpeed() {
    final session = context.read<SessionStore>();
    session.setFanSpeed(_fanSpeed);
    
    int hardwareFanSpeed = (_fanSpeed * 2.55).toInt();
    DeviceTransport().sendCommand('SET_MANUAL_OUTPUTS', {
      'fan_speed': hardwareFanSpeed
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fan speed set to ${_fanSpeed.toStringAsFixed(0)}%'),
        behavior: SnackBarBehavior.floating,
      ),
    );
>>>>>>> firmware
  }

  void _applyTemperature() {
    final session = context.read<SessionStore>();
    
    // Check if there's an active batch/device
    final deviceId = session.activeBatch?['device_id'];
    if (deviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active session. Start a batch first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    session.setTargetTemp(_targetTemp);

    // Send command to device
    DeviceTransport().sendCommand('SET_MANUAL_OUTPUTS', {
      'target_temp': _targetTemp,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Target temperature set to ${_targetTemp.toStringAsFixed(0)}°C',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  }

  Future<void> _sendTemperatureUpdate(String deviceId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      final response = await http.post(
        Uri.parse('http://192.168.1.101:5000/device/update-temperature'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "device_id": deviceId,
          "temperature": _targetTemp,
        }),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loader

      if (response.statusCode == 200) {
        // Update active batch with new temperature
        final session = context.read<SessionStore>();
        if (session.activeBatch != null) {
          final updatedBatch = Map<String, dynamic>.from(session.activeBatch!);
          updatedBatch['target_temp'] = _targetTemp;
          updatedBatch['temperature'] = _targetTemp;
          session.setActiveBatch(updatedBatch);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Temperature set to ${_targetTemp.toStringAsFixed(0)}°C - sent to device',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? "Failed to update temperature");
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _setToDefault() {
    final session = context.read<SessionStore>();
    
    developer.log('Set to Default clicked - Default Temp=$_defaultTemp');
    
    // Check if there's an active batch/device
    final deviceId = session.activeBatch?['device_id'];
    if (deviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active session. Start a batch first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    developer.log('Resetting to default temp: $_defaultTemp');
    
    // Update local UI immediately
    setState(() {
      _targetTemp = _defaultTemp;
    });
    
    // Update active batch with default temperature
    final updatedBatch = Map<String, dynamic>.from(session.activeBatch!);
    updatedBatch['target_temp'] = _defaultTemp;
    updatedBatch['temperature'] = _defaultTemp;
    session.setActiveBatch(updatedBatch);
    
    developer.log('Updated batch with default temp, now sending to backend');
    
    // Send default temperature to backend
    _sendDefaultSettings(deviceId);
  }

  Future<void> _sendDefaultSettings(String deviceId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      developer.log('Sending default temperature to backend - Token exists: ${token != null}');

      // Send temperature
      final tempResponse = await http.post(
        Uri.parse('http://192.168.1.101:5000/device/update-temperature'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "device_id": deviceId,
          "temperature": _defaultTemp,
        }),
      );

      developer.log('Temperature response: ${tempResponse.statusCode}');

      if (!mounted) return;
      Navigator.pop(context); // Close loader

      if (tempResponse.statusCode == 200) {
        developer.log('Default temperature set successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reset to default - Temp: ${_defaultTemp.toStringAsFixed(0)}°C',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        developer.log('Backend returned error - Temp: ${tempResponse.statusCode}');
        developer.log('Temp response body: ${tempResponse.body}');
        throw Exception("Failed to reset to default - Temp: ${tempResponse.statusCode}");
      }
    } catch (e) {
      developer.log('Error in _sendDefaultSettings: ${e.toString()}');
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
              
              DeviceTransport().sendCommand('EMERGENCY_STOP');

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
>>>>>>> firmware
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

  Future<void> _sendEmergencyStop() async {
    final session = context.read<SessionStore>();
    final deviceId = session.activeBatch?['device_id'];
    
    if (deviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active session to stop'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      final response = await http.post(
        Uri.parse('http://192.168.1.101:5000/device/stop'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"device_id": deviceId}),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loader

      if (response.statusCode == 200) {
        session.setActiveBatch(null);
        setState(() {
          _heaterOn = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drying session stopped'),
            backgroundColor: Color(0xFFEF5350),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception("Failed to stop device");
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stop Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                          DeviceTransport().sendCommand('SET_MANUAL_OUTPUTS', {
                             'heater_on': v
                          });
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
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: 'Apply Temperature',
                            backgroundColor: const Color(0xFFFF6B35),
                            foregroundColor: Colors.white,
                            onPressed: _applyTemperature,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _setToDefault,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFFF6B35),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                          ),
                        ),
                      ],
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
