import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF0d59f2);
  static const Color primaryLight = Color(0xFF1a6aff);
  static const Color primaryDark = Color(0xFF0047cc);

  // Backgrounds
  static const Color backgroundDark = Color(0xFF101622);
  static const Color backgroundLight = Color(0xFFF5F6F8);
  static const Color surfaceDark = Color(0xFF1a2332);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // Status
  static const Color statusGreen = Color(0xFF10b981);
  static const Color statusOrange = Color(0xFFf59e0b);
  static const Color statusRed = Color(0xFFef4444);

  // Borders & Dividers
  static const Color borderDark = Color(0xFF334155);
  static const Color borderLight = Color(0xFFe2e8f0);

  // Text
  static const Color textDark = Color(0xFF0f172a);
  static const Color textLight = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF64748b);
  static const Color textMutedLight = Color(0xFF94a3b8);
}

class AppTheme {
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surfaceDark,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColors.textLight,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textMutedLight,
          ),
        ),
      ),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.surfaceLight,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColors.textDark,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
