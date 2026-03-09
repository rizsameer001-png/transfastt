// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary      = Color(0xFF1A3FAA);
  static const Color primaryDark  = Color(0xFF0D2580);
  static const Color primaryLight = Color(0xFFE0E7FF);

  // Accent
  static const Color accent       = Color(0xFFF59E0B);
  static const Color accentDark   = Color(0xFFD97706);

  // Semantic
  static const Color success      = Color(0xFF10B981);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color error        = Color(0xFFEF4444);
  static const Color info         = Color(0xFF3B82F6);

  // Neutrals
  static const Color background   = Color(0xFFF8FAFC);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color border       = Color(0xFFE2E8F0);
  static const Color textPrimary  = Color(0xFF0F172A);
  static const Color textSecondary= Color(0xFF64748B);
  static const Color textHint     = Color(0xFF94A3B8);

  // Status colors
  static const Color pending      = Color(0xFFF59E0B);
  static const Color processing   = Color(0xFF3B82F6);
  static const Color sent         = Color(0xFF8B5CF6);
  static const Color delivered    = Color(0xFF10B981);
  static const Color failed       = Color(0xFFEF4444);
  static const Color cancelled    = Color(0xFF6B7280);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.error,
      background: AppColors.background,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'DMSans',

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),

    // Card
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: const TextStyle(
        color: AppColors.textHint,
        fontSize: 14,
      ),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      selectedLabelStyle: TextStyle(fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontFamily: 'DMSans', fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryLight,
      labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 0,
    ),
  );
}

// Text Styles
class AppTextStyles {
  static const TextStyle h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'DMSans');
  static const TextStyle h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'DMSans');
  static const TextStyle h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'DMSans');
  static const TextStyle h4 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'DMSans');
  static const TextStyle bodyLg = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, fontFamily: 'DMSans');
  static const TextStyle body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, fontFamily: 'DMSans');
  static const TextStyle bodySm = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, fontFamily: 'DMSans');
  static const TextStyle caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textHint, fontFamily: 'DMSans');
  static const TextStyle label = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'DMSans');
  static const TextStyle amount = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'DMSans');
}
