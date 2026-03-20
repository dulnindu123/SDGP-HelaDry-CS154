import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../app/mock_data.dart';
import '../../../widgets/primary_button.dart';
import 'package:provider/provider.dart';
import '../../../services/session_store.dart';

class CropGuidePage extends StatefulWidget {
  const CropGuidePage({super.key});

  @override
  State<CropGuidePage> createState() => _CropGuidePageState();
}

class _CropGuidePageState extends State<CropGuidePage> {
  int _selectedCropIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark
        ? const Color(0xFF8892B0)
        : const Color(0xFF64748B);
    final accentColor = isDark
        ? const Color(0xFF00D4AA)
        : const Color(0xFF1976D2);
    final selectedCrop = MockData.crops[_selectedCropIndex];
    final session = context.watch<SessionStore>();

    return Scaffold(
      body: Column(
        children: [
          // Blue/teal header
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
                    ? [const Color(0xFF00838F), const Color(0xFF006064)]
                    : [const Color(0xFF1976D2), const Color(0xFF1565C0)],
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crop Drying Guide',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Preparation steps & drying schedules',
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
                  // Select Crop
                  const Text(
                    'Select Crop',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(MockData.crops.length, (i) {
                      final crop = MockData.crops[i];
                      final isSelected = _selectedCropIndex == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCropIndex = i),
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
                  const SizedBox(height: 24),

                  // Crop info card
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              selectedCrop.emoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedCrop.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.thermostat,
                                        size: 14,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        session.useCelsius
                                            ? '${selectedCrop.tempC.toStringAsFixed(0)}°C'
                                            : '${((selectedCrop.tempC * 9 / 5) + 32).round()}°F',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: accentColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: subtextColor,
                                      ),
                                      const SizedBox(width: 4),
                                      // FIXED: Updated to use durationHours and converted to String
                                      Text(
                                        '${selectedCrop.durationHours} hours',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: subtextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoRow(
                                'Slice thickness:',
                                selectedCrop.sliceThickness,
                                subtextColor,
                              ),
                            ),
                          ],
                        ),
                        _buildInfoRow(
                          'Pretreatment:',
                          selectedCrop.pretreatment,
                          subtextColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Smart Recommendations
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D2137)
                          : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Recommendations',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFFE6F1FF)
                                : const Color(0xFF1A2D4D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Recommended fan mode: ${selectedCrop.fanMode}\n'
                          '• Recommended tray load: ${selectedCrop.trayLoad}\n'
                          '• ${selectedCrop.sliceTip}',
                          style: TextStyle(
                            fontSize: 13,
                            color: subtextColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Preparation Steps
                  Row(
                    children: [
                      Icon(Icons.auto_stories, size: 20, color: accentColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Preparation Steps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    selectedCrop.preparationSteps.length,
                    (i) => _buildStep(
                      i + 1,
                      selectedCrop.preparationSteps[i]['title']!,
                      selectedCrop.preparationSteps[i]['desc']!,
                      isDark,
                      accentColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Drying Tips
                  const Text(
                    'Drying Tips',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...selectedCrop.dryingTips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 7),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tip,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? const Color(0xFFE6F1FF)
                                    : const Color(0xFF1A2D4D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Use These Settings
                  PrimaryButton(
                    label: 'Use These Settings',
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.startNewBatch,
                        arguments: {'cropName': selectedCrop.name},
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Settings will be applied to Start New Batch form',
                      style: TextStyle(fontSize: 12, color: subtextColor),
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

  Widget _buildInfoRow(String label, String value, Color subtextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: subtextColor)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    int number,
    String title,
    String desc,
    bool isDark,
    Color accentColor,
  ) {
    final subtextColor = isDark
        ? const Color(0xFF8892B0)
        : const Color(0xFF64748B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withOpacity(0.15),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 13, color: subtextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}