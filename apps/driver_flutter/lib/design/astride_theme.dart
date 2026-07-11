import 'package:flutter/material.dart';

abstract final class AstrideColors {
  static const navy = Color(0xFF0D1B3D);
  static const green = Color(0xFF22C55E);
  static const orange = Color(0xFFFF8A00);
  static const background = Color(0xFFF5F7FA);
  static const text = Color(0xFF1F2937);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const danger = Color(0xFFDC2626);
}

ThemeData buildAstrideTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AstrideColors.green,
    brightness: Brightness.light,
    primary: AstrideColors.green,
    secondary: AstrideColors.orange,
    surface: AstrideColors.white,
    error: AstrideColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AstrideColors.background,
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: AstrideColors.background,
      foregroundColor: AstrideColors.navy,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: AstrideColors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: AstrideColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AstrideColors.green,
        foregroundColor: AstrideColors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AstrideColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AstrideColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AstrideColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AstrideColors.green, width: 1.5),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AstrideColors.white,
      indicatorColor: Color(0x3322C55E),
      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w500)),
    ),
  );
}
