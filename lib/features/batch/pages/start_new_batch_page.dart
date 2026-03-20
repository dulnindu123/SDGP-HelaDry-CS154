import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // To access SessionStore
import '../../../services/session_store.dart';
import '../../../app/mock_data.dart';
import '../../../widgets/primary_button.dart';
<<<<<<< HEAD
import '../../../services/device_transport.dart';
=======
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
>>>>>>> sensor-dashboard

class StartNewBatchPage extends StatefulWidget {
  const StartNewBatchPage({super.key});

  @override
  State<StartNewBatchPage> createState() => _StartNewBatchPageState();
}


class _StartNewBatchPageState extends State<StartNewBatchPage> {
  // State Variables
  int _selectedCropIndex = 0;
  bool _isAutoMode = true;
  double _targetTemp = 60.0;
  bool _isDrying = false; // Tracks if a batch is active

  // Controllers
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _traysController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _batchNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncAutoSettings();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _traysController.dispose();
    _durationController.dispose();
    _batchNameController.dispose();
    super.dispose();
  }

  void _syncAutoSettings() {
    if (_isAutoMode) {
      final selectedCrop = MockData.crops[_selectedCropIndex];
      setState(() {
        _targetTemp = selectedCrop.tempC;
        _durationController.text = selectedCrop.durationHours.toString();
      });
    }
  }

  void _handleStartBatch() async {
    if (_weightController.text.trim().isEmpty ||
        _traysController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
<<<<<<< HEAD
    
      final cropName = MockData.crops[_selectedCropIndex].name;
      final hours = double.tryParse(_durationController.text) ?? 12.0;

      await DeviceTransport().sendCommand('START_SESSION', {
        'crop': cropName,
        'target_temp': _targetTemp,
        'hours': hours,
      });

      if (!mounted) return;
    
      final session = context.read<SessionStore>();
      session.setActiveBatch('BATCH-${DateTime.now().millisecondsSinceEpoch}', cropName);
    
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batch started successfully!'),
=======
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No logged in user found');

      final db = FirebaseDatabase.instance;
      final sessionRef = db.ref('users/${user.uid}/sessions').push();

      final crop = MockData.crops[_selectedCropIndex];

      await sessionRef.set({
        'sessionId': sessionRef.key,
        'deviceId': 'device-001',
        'crop': crop.name,
        'variety': _varietyController.text.trim(),
        'weight': double.tryParse(_weightController.text.trim()) ?? 0.0,
        'trays': int.tryParse(_traysController.text.trim()) ?? 0,
        'moistureTarget': _moistureController.text.trim(),
        'notes': _notesController.text.trim(),
        'targetTemp': _targetTemp,
        'durationEstimate': _durationController.text.trim(),
        'maxTempCutoff':
            double.tryParse(_maxTempController.text.trim()) ?? 75.0,
        'lowBatteryCutoff':
            double.tryParse(_lowBatteryController.text.trim()) ?? 11.5,
        'mode': _isAutoMode ? 'auto' : 'manual',
        'status': 'active',
        'startTime': ServerValue.timestamp,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batch started successfully'),
>>>>>>> sensor-dashboard
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
<<<<<<< HEAD
    }
  }

  // Logic to handle the STOP command
  Future<void> _handleStopBatch() async {
    final session = context.read<SessionStore>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
=======
  void _handleStartBatch() async {
    setState(() => _isLoading = true);
    
    final cropName = MockData.crops[_selectedCropIndex].name;
    final hours = double.tryParse(_durationController.text) ?? 12.0;

    await DeviceTransport().sendCommand('START_SESSION', {
      'crop': cropName,
      'target_temp': _targetTemp,
      'hours': hours,
    });

    if (!mounted) return;
    
    final session = context.read<SessionStore>();
    session.setActiveBatch('BATCH-${DateTime.now().millisecondsSinceEpoch}', cropName);
    
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Batch started successfully!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF4CAF50),
      ),
>>>>>>> firmware
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      final response = await http.post(
        Uri.parse('http://172.30.161.140:5000/device/stop'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"device_id": session.deviceId}),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loader

      if (response.statusCode == 200) {
        setState(() => _isDrying = false);
        session.setActiveBatch(null); // Clear active batch so dashboard updates
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency Stop Sent!'), 
            backgroundColor: Colors.redAccent
          ),
        );
      } else {
        throw Exception("Failed to stop device");
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stop Error: ${e.toString()}')),
      );
    }
  }

  /// Communicates with Flask Blueprint: /device/start
  Future<void> _handleStartBatch() async {
    final selectedCrop = MockData.crops[_selectedCropIndex];
    final session = context.read<SessionStore>();
    final registeredDeviceId = session.deviceId; 

    if (registeredDeviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No device paired. Please pair your device first.')),
      );
      return;
    }

    final batchData = {
      "device_id": registeredDeviceId,
      "temperature": _targetTemp, 
      "crop_name": selectedCrop.name,
      "crop_emoji": selectedCrop.emoji,
      "weight_kg": double.tryParse(_weightController.text) ?? 0.0,
      "trays": int.tryParse(_traysController.text) ?? 1,
      "duration": int.tryParse(_durationController.text) ?? selectedCrop.durationHours,
      "start_date": DateTime.now().toIso8601String(),
      "status": "active",
      if (_batchNameController.text.trim().isNotEmpty)
        "batch_name": _batchNameController.text.trim(),
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please log in again.");
      
      String? firebaseToken = await user.getIdToken(true); 

      final url = Uri.parse('http://172.30.161.140:5000/device/start'); 
      
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $firebaseToken", 
        },
        body: jsonEncode(batchData),
      );

      if (!mounted) return;
      Navigator.pop(context); 

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _isDrying = true);
        // Set active batch in SessionStore using backend response if available
        final backendBatch = responseData['batch'] ?? batchData;
        session.setActiveBatch(backendBatch);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Success: ${responseData['message']}')),
        );
      } else {
        throw Exception(responseData['message'] ?? "Server rejected request");
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
=======
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start batch: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
>>>>>>> sensor-dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFF00D4AA) : const Color(0xFF1976D2);
    final bgColor = isDark ? const Color(0xFF0A192F) : const Color(0xFFF5F7FA);
    final cardColor = isDark ? const Color(0xFF112240) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('New Drying Batch', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Crop *', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(MockData.crops.length, (i) {
                final crop = MockData.crops[i];
                final isSelected = _selectedCropIndex == i;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCropIndex = i);
                    _syncAutoSettings();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor.withOpacity(0.15) : cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected ? accentColor : (isDark ? const Color(0xFF1E3A5F) : Colors.grey[300]!),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(crop.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(crop.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            Text('Drying Mode', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF112240) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
<<<<<<< HEAD
                  _buildModeTab('Auto', _isAutoMode, isDark, accentColor, () {
                    setState(() => _isAutoMode = true);
                    _syncAutoSettings();
                  }),
                  _buildModeTab('Manual', !_isAutoMode, isDark, accentColor, () {
                    setState(() => _isAutoMode = false);
                  }),
=======
                  // Batch Information
                  Text(
                    'Batch Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFE6F1FF)
                          : const Color(0xFF1A2D4D),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Crop selection
                  Text(
                    'Select Crop *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFE6F1FF)
                          : const Color(0xFF1A2D4D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(MockData.crops.length, (i) {
                      final crop = MockData.crops[i];
                      final isSelected = _selectedCropIndex == i;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCropIndex = i;
                            _targetTemp = crop.tempC;
                          });
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentColor.withOpacity(0.15)
                                : (isDark
                                      ? const Color(0xFF112240)
                                      : const Color(0xFFF5F7FA)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? accentColor
                                  : (isDark
                                        ? const Color(0xFF1E3A5F)
                                        : const Color(0xFFE0E6ED)),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                crop.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                crop.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Text fields
                  _buildField(
                    'Variety (Optional)',
                    'e.g. Alphonso, Cavendish',
                    _varietyController,
                    isDark,
                  ),
                  _buildField(
                    'Starting Weight (kg) *',
                    '0.0',
                    _weightController,
                    isDark,
                    keyboard: TextInputType.number,
                  ),
                  _buildField(
                    'Number of Trays *',
                    '0',
                    _traysController,
                    isDark,
                    keyboard: TextInputType.number,
                  ),
                  _buildField(
                    'Moisture Target (%) (Optional)',
                    'Desired final moisture',
                    _moistureController,
                    isDark,
                    keyboard: TextInputType.number,
                  ),
                  _buildField(
                    'Notes (Optional)',
                    'Add any notes about this batch',
                    _notesController,
                    isDark,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Drying Settings
                  Text(
                    'Drying Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFE6F1FF)
                          : const Color(0xFF1A2D4D),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mode toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mode',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _isAutoMode ? 'Auto (Recommended)' : 'Manual',
                            style: TextStyle(fontSize: 12, color: subtextColor),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildModeTab('Auto', _isAutoMode, isDark, () {
                            setState(() => _isAutoMode = true);
                          }),
                          const SizedBox(width: 4),
                          _buildModeTab('Manual', !_isAutoMode, isDark, () {
                            setState(() => _isAutoMode = false);
                          }),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Target Temperature
                  Text(
                    'Target Temperature *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFE6F1FF)
                          : const Color(0xFF1A2D4D),
                    ),
                  ),
                  const SizedBox(height: 4),
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
                          color: accentColor,
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
                    activeColor: accentColor,
                    onChanged: (v) => setState(() => _targetTemp = v),
                  ),

                  _buildField(
                    'Duration Estimate (hours)',
                    'Estimated drying time',
                    _durationController,
                    isDark,
                  ),

                  // Auto recommendation
                  if (_isAutoMode) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0D2818)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fan Auto (Recommended)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4CAF50),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fan speed will be adjusted automatically based on temperature',
                            style: TextStyle(fontSize: 12, color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Safety Settings
                  Text(
                    'Safety Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFE6F1FF)
                          : const Color(0xFF1A2D4D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    'Max Temp Cutoff (°C)',
                    '75',
                    _maxTempController,
                    isDark,
                    keyboard: TextInputType.number,
                  ),
                  _buildField(
                    'Low Battery Cutoff (V)',
                    '11.5',
                    _lowBatteryController,
                    isDark,
                    keyboard: TextInputType.number,
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  PrimaryButton(
                    label: 'Start Batch',
                    isLoading: _isLoading,
                    onPressed: _handleStartBatch,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Preset saved!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save as Preset'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: subtextColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
>>>>>>> sensor-dashboard
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: _buildField('Weight (kg)', '0.0', _weightController, isDark, cardColor, keyboard: TextInputType.number)),
                const SizedBox(width: 15),
                Expanded(child: _buildField('Trays Used', '1', _traysController, isDark, cardColor, keyboard: TextInputType.number)),
              ],
            ),
            if (!_isAutoMode) ...[
              const SizedBox(height: 20),
              _buildField('Batch Name', 'Enter batch name', _batchNameController, isDark, cardColor),
            ],
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.watch<SessionStore>().useCelsius 
                      ? 'Target Temp: ${_targetTemp.toInt()}°C'
                      : 'Target Temp: ${((_targetTemp * 9 / 5) + 32).round()}°F',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_isAutoMode) Text('Auto-Optimized', style: TextStyle(color: accentColor, fontSize: 12)),
              ],
            ),
            Slider(
              value: _targetTemp,
              min: 30,
              max: 80,
              activeColor: accentColor,
              onChanged: _isAutoMode ? null : (v) => setState(() => _targetTemp = v),
            ),
            const SizedBox(height: 15),
            _buildField('Duration (Hours)', 'Time', _durationController, isDark, cardColor, enabled: !_isAutoMode, keyboard: TextInputType.number),
            const SizedBox(height: 20),
            _buildField('Batch Name (Optional)', 'Leave blank to use crop name', _batchNameController, isDark, cardColor),
            const SizedBox(height: 40),
            
            // SIDE-BY-SIDE BUTTONS: Always visible
            Row(
              children: [
                // START BUTTON
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isDrying ? null : _handleStartBatch, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        disabledBackgroundColor: accentColor.withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('START', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),

                // STOP BUTTON
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _handleStopBatch, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('STOP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, bool isActive, bool isDark, Color accentColor, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? (isDark ? const Color(0xFF1E3A5F) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? accentColor : Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController controller, bool isDark, Color cardColor, {bool enabled = true, TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}