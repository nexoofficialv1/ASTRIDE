import 'package:flutter/material.dart';

abstract final class AstrideColors {
  static const navy = Color(0xFF0B1D45);
  static const navySoft = Color(0xFF173B72);
  static const green = Color(0xFF19C65B);
  static const greenDark = Color(0xFF079447);
  static const orange = Color(0xFFFF7A00);
  static const background = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const text = Color(0xFF17233C);
  static const muted = Color(0xFF6F788A);
  static const border = Color(0xFFE3E8F1);
  static const danger = Color(0xFFE53935);
  static const successTint = Color(0xFFEAFBF1);
  static const navyTint = Color(0xFFF0F4FB);
}

ThemeData buildAstrideTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AstrideColors.green,
    brightness: Brightness.light,
    primary: AstrideColors.green,
    secondary: AstrideColors.orange,
    surface: AstrideColors.surface,
    error: AstrideColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AstrideColors.background,
    fontFamily: 'Poppins',
    dividerColor: AstrideColors.border,
    appBarTheme: const AppBarTheme(
      backgroundColor: AstrideColors.surface,
      foregroundColor: AstrideColors.navy,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AstrideColors.navy,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AstrideColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
        side: BorderSide(color: AstrideColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AstrideColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AstrideColors.navy,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AstrideColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AstrideColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      hintStyle: const TextStyle(color: AstrideColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AstrideColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AstrideColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AstrideColors.green, width: 1.6),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 74,
      backgroundColor: AstrideColors.surface,
      indicatorColor: Color(0x2219C65B),
      elevation: 8,
      shadowColor: Color(0x220B1D45),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AstrideColors.navy,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
}
