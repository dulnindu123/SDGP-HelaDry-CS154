import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ━━━━━━━━━━━━━━━ DARK THEME TOKENS ━━━━━━━━━━━━━━━
  static const Color darkBg = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurface2 = Color(0xFF162033);
  static const Color darkIconBg = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF22304A);

  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkSubtext = Color(0xFF94A3B8);
  static const Color darkMuted = Color(0xFF64748B);

  static const Color darkPrimary = Color(0xFF22D3EE);
  static const Color darkPrimaryPressed = Color(0xFF14B8D4);
  static const Color darkSecondary = Color(0xFFF97316);
  static const Color darkSuccess = Color(0xFF34D399);
  static const Color darkAccentGreen = Color(0xFF4D7C0F);
  static const Color darkDanger = Color(0xFFEF4444);

  // Status backgrounds
  static const Color successBg = Color(0xFF0B2A22);
  static const Color warningBg = Color(0xFF2A1C0B);
  static const Color dangerBg = Color(0xFF2A0B0B);
  static const Color infoBg = Color(0xFF06202A);

  // ━━━━━━━━━━━━━━━ LIGHT THEME TOKENS ━━━━━━━━━━━━━━━
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF6F8FC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightIconBg = Color(0xFFEAF0F7);
  static const Color lightBorder = Color(0xFFD8E2F0);

  static const Color lightText = Color(0xFF0F172A);
  static const Color lightSubtext = Color(0xFF475569);
  static const Color lightMuted = Color(0xFF64748B);

  static const Color lightPrimary = Color(0xFF0EA5E9);
  static const Color lightPrimaryPressed = Color(0xFF0284C7);
  static const Color lightSecondary = Color(0xFFF97316);
  static const Color lightSuccess = Color(0xFF10B981);
  static const Color lightDanger = Color(0xFFEF4444);

  // ── shared accents ──
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color recordsPurple = Color(0xFF6B21A8);

  // ━━━━━━━━ GRADIENT PRESETS ━━━━━━━━
  static const List<Color> dashboardGradientDark = [
    Color(0xFF0B1120),
    Color(0xFF134E4A),
    Color(0xFF0E7490),
  ];
  static const List<Color> dashboardGradientLight = [
    Color(0xFF0EA5E9),
    Color(0xFF22C55E),
  ];

  static const List<Color> splashGradient = [
    Color(0xFF0B1120),
    Color(0xFF134E4A),
    Color(0xFF0E7490),
  ];

  static const List<Color> wifiHeaderGradientDark = [
    Color(0xFF0B1120),
    Color(0xFF134E4A),
    Color(0xFF0E7490),
  ];
  static const List<Color> wifiHeaderGradientLight = [
    Color(0xFF0EA5E9),
    Color(0xFF06B6D4),
    Color(0xFF22C55E),
  ];

  static const List<Color> batchHeaderGradientDark = [
    Color(0xFF0B1120),
    Color(0xFF134E4A),
  ];
  static const List<Color> batchHeaderGradientLight = [
    Color(0xFF0EA5E9),
    Color(0xFF22C55E),
  ];

  static const List<Color> recordsGradient = [
    Color(0xFF7C3AED),
    Color(0xFF6B21A8),
  ];

  static const List<Color> cropGuideGradientDark = [
    Color(0xFF0B1120),
    Color(0xFF0E7490),
  ];
  static const List<Color> cropGuideGradientLight = [
    Color(0xFF06B6D4),
    Color(0xFF0EA5E9),
  ];

  // ━━━━━━━━ TEXT THEME ━━━━━━━━
  static TextTheme _buildTextTheme(Color textColor, Color subtextColor) {
    return TextTheme(
      // Display / Big Title: 32, 700
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
      ),
      // H1 / Screen title: 24, 700
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.3,
      ),
      // H2 / Card title: 20, 600
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      // H3 / Section title: 18, 600
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      // Body large: 16, 400
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      // Body default: 14, 400
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      // Body small: 13, 400
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: subtextColor,
      ),
      // Label / Caption: 12, 500
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: subtextColor,
      ),
      // Button: 16, 600
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      // Micro / Hint: 11, 400
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: subtextColor,
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━ DARK THEME ━━━━━━━━━━━━━━━━━
  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(darkText, darkSubtext);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: darkPrimary,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkSurface,
        error: darkDanger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: darkText),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkDanger),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: darkMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: darkSubtext,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkBg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: const BorderSide(color: darkBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkSurface2,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: darkText,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimary;
          return darkMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkPrimary.withValues(alpha: 0.4);
          }
          return darkBorder;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: darkPrimary,
        thumbColor: darkPrimary,
        inactiveTrackColor: darkBorder,
        overlayColor: darkPrimary.withValues(alpha: 0.15),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        trackHeight: 4,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimary;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: darkBorder, width: 1.5),
      ),
      dividerColor: darkBorder,
      iconTheme: const IconThemeData(color: darkSubtext),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  // ━━━━━━━━━━━━━━━━━ LIGHT THEME ━━━━━━━━━━━━━━━━━
  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(lightText, lightSubtext);

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: lightPrimary,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightSurface,
        error: lightDanger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: lightText),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightDanger),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: lightMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: lightSubtext,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightPrimary,
          side: const BorderSide(color: lightBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPrimary,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: lightText,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return lightPrimary;
          return lightMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return lightPrimary.withValues(alpha: 0.4);
          }
          return lightBorder;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: lightPrimary,
        thumbColor: lightPrimary,
        inactiveTrackColor: lightBorder,
        overlayColor: lightPrimary.withValues(alpha: 0.15),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        trackHeight: 4,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return lightPrimary;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: lightBorder, width: 1.5),
      ),
      dividerColor: lightBorder,
      iconTheme: const IconThemeData(color: lightSubtext),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
