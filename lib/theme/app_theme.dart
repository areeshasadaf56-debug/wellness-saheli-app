import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette grounded in the earthy, clinical-botanical tones of the app's
/// PCOS education material — terracotta, olive and warm parchment instead
/// of a generic lavender "period app" look. Every value below is a named
/// role, not a one-off, so the same six colors carry the whole app.
class AppColors {
  static const Color background = Color(0xFFF6F1E2);
  static const Color surface = Color(0xFFFFFCF5);
  static const Color primary = Color(0xFFA6462A);
  static const Color accent = Color(0xFF6B7A4C);
  static const Color textPrimary = Color(0xFF2C2417);
  static const Color textSecondary = Color(0xFF6E6248);
  static const Color cardBorder = Color(0xFFE6DAC0);

  // Accent colors for Home screen redesign
  static const Color periodRed = Color(0xFFC1503A);
  static const Color moodYellow = Color(0xFFD69A3C);
  static const Color symptomOrange = Color(0xFFDD7F2E);

  // Accent color for Ovulation screen
  static const Color ovulationTeal = Color(0xFF4F8C78);

  // Extra earthy tones for category tags (contraception, PCOS chips, etc.)
  static const Color sage = Color(0xFF8A9A5B);
  static const Color clay = Color(0xFFB08968);
}

class AppTextStyles {
  static TextStyle serif({
    double size = 20,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.fraunces(
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
    return GoogleFonts.jost(fontSize: size, fontWeight: weight, color: color);
  }
}

ThemeData buildAppTheme() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onPrimary: Colors.white,
    ),
    fontFamily: GoogleFonts.jost().fontFamily,
    useMaterial3: true,
  );
}
