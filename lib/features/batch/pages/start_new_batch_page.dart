import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // To access SessionStore
import '../../../services/session_store.dart';
import '../../../app/mock_data.dart';

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

  // Logic to handle the STOP command
  Future<void> _handleStopBatch() async {
    final session = context.read<SessionStore>();
    
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

      final url = Uri.parse('http://192.168.1.101:5000/device/start'); 
      
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
                  _buildModeTab('Auto', _isAutoMode, isDark, accentColor, () {
                    setState(() => _isAutoMode = true);
                    _syncAutoSettings();
                  }),
                  _buildModeTab('Manual', !_isAutoMode, isDark, accentColor, () {
                    setState(() => _isAutoMode = false);
                  }),
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