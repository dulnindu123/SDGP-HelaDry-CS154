import 'package:flutter/material.dart';
import '../../../app/mock_data.dart';
import '../../../widgets/primary_button.dart';

class StartNewBatchPage extends StatefulWidget {
  const StartNewBatchPage({super.key});

  @override
  State<StartNewBatchPage> createState() => _StartNewBatchPageState();
}

class _StartNewBatchPageState extends State<StartNewBatchPage> {
  int _selectedCropIndex = 0;
  final _varietyController = TextEditingController();
  final _weightController = TextEditingController(text: '0.0');
  final _traysController = TextEditingController(text: '0');
  final _moistureController = TextEditingController();
  final _notesController = TextEditingController();
  final _durationController = TextEditingController();
  final _maxTempController = TextEditingController(text: '75');
  final _lowBatteryController = TextEditingController(text: '11.5');

  bool _isAutoMode = true;
  double _targetTemp = 55;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we have pre-selected crop from CropGuide
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      final cropName = args['cropName'] as String?;
      if (cropName != null) {
        final idx = MockData.crops.indexWhere((c) => c.name == cropName);
        if (idx >= 0) {
          _selectedCropIndex = idx;
          _targetTemp = MockData.crops[idx].tempC;
        }
      }
    }
  }

  @override
  void dispose() {
    _varietyController.dispose();
    _weightController.dispose();
    _traysController.dispose();
    _moistureController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    _maxTempController.dispose();
    _lowBatteryController.dispose();
    super.dispose();
  }

  void _handleStartBatch() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Batch started successfully!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
    Navigator.of(context).pop();
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
          // Green header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2D5016), const Color(0xFF1A3A0A)]
                    : [const Color(0xFF5B8C2E), const Color(0xFF3D7A1C)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Start New Batch',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Log a new drying batch',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                ? accentColor.withValues(alpha: 0.15)
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller,
    bool isDark, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? const Color(0xFFE6F1FF) : const Color(0xFF1A2D4D),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(
    String label,
    bool isActive,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF00D4AA) : const Color(0xFF1976D2))
              : (isDark ? const Color(0xFF112240) : const Color(0xFFF5F7FA)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive
                ? (isDark ? const Color(0xFF0A1628) : Colors.white)
                : (isDark ? const Color(0xFF8892B0) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}
