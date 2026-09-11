import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF23233A);
  static const Color darkTextPrimary = Color(0xFFE8E8E8);
  static const Color darkTextSecondary = Color(0xFFB6B4CC);
  static const Color darkCardBorder = Color(0xFF3A3854);

  static const Color background = Color(0xFFF4ECFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF8B5FBF);
  static const Color accent = Color(0xFFD988AC);
  static const Color textPrimary = Color(0xFF2A1D3A);
  static const Color textSecondary = Color(0xFF6B5C7A);
  static const Color cardBorder = Color(0xFFE0D3EC);

  // Accent colors for Home screen redesign
  static const Color periodRed = Color(0xFFE05C6E);
  static const Color moodYellow = Color(0xFFE8B84B);
  static const Color symptomOrange = Color(0xFFE8935A);

  // Accent color for Ovulation screen
  static const Color ovulationTeal = Color(0xFF5DCFA0);
}

class AppTextStyles {
  static TextStyle serif({
    double size = 20,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  // ✅ FIXED — removed the accidental `required List<Expanded> children` parameter
  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.normal,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color);
  }
}

ThemeData buildAppTheme() {
  return buildLightTheme();
}

ThemeData buildLightTheme() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      outline: AppColors.cardBorder,
      onTertiary: AppColors.textSecondary,
      tertiary: AppColors.periodRed,
    ),
    fontFamily: GoogleFonts.dmSans().fontFamily,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    textTheme: GoogleFonts.dmSansTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      outline: AppColors.darkCardBorder,
      onTertiary: AppColors.darkTextSecondary,
      tertiary: AppColors.periodRed,
    ),
    fontFamily: GoogleFonts.dmSans().fontFamily,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: AppColors.darkTextPrimary,
      displayColor: AppColors.darkTextPrimary,
    ),
  );
}
