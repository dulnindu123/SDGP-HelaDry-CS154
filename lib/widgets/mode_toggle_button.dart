import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_controller.dart';

class ModeToggleButton extends StatelessWidget {
  const ModeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final isDark = themeController.isDarkMode;

    return GestureDetector(
      onTap: () => themeController.toggleTheme(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1A2D4D) : const Color(0xFFE8EDF5),
          border: Border.all(
            color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Icon(
          isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
          color: isDark ? const Color(0xFF00BCD4) : const Color(0xFF1976D2),
          size: 20,
        ),
      ),
    );
  }
}
