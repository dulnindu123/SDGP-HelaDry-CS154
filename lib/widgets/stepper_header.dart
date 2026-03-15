import 'package:flutter/material.dart';

class StepperHeader extends StatelessWidget {
  final int currentStep; // 1, 2, or 3
  final List<String> labels;

  const StepperHeader({
    super.key,
    required this.currentStep,
    this.labels = const ['BLE', 'WiFi', 'Connect'],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark
        ? const Color(0xFF22D3EE)
        : const Color(0xFF0EA5E9);
    final inactiveColor = isDark
        ? const Color(0xFF22304A)
        : const Color(0xFFD8E2F0);
    final activeText = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF0F172A);
    final inactiveText = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = (index ~/ 2) + 1;
            final isCompleted = stepBefore < currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 2,
                decoration: BoxDecoration(
                  color: isCompleted ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final stepNumber = (index ~/ 2) + 1;
          final isActive = stepNumber == currentStep;
          final isCompleted = stepNumber < currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: isActive ? 36 : 32,
                height: isActive ? 36 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isActive
                      ? activeColor
                      : Colors.transparent,
                  border: Border.all(
                    color: isCompleted || isActive
                        ? activeColor
                        : inactiveColor,
                    width: 2,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '$stepNumber',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : inactiveText,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[stepNumber - 1],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive || isCompleted
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: isActive || isCompleted ? activeText : inactiveText,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
