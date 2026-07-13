import 'package:flutter/material.dart';

abstract final class PartnerColors {
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
    seedColor: PartnerColors.green,
    brightness: Brightness.light,
    primary: PartnerColors.green,
    secondary: PartnerColors.orange,
    surface: PartnerColors.surface,
    error: PartnerColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: PartnerColors.background,
    fontFamily: 'Poppins',
    dividerColor: PartnerColors.border,
    appBarTheme: const AppBarTheme(
      backgroundColor: PartnerColors.surface,
      foregroundColor: PartnerColors.navy,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: PartnerColors.navy,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: const CardThemeData(
      color: PartnerColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
        side: BorderSide(color: PartnerColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: PartnerColors.green,
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
        foregroundColor: PartnerColors.navy,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: PartnerColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PartnerColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      hintStyle: const TextStyle(color: PartnerColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: PartnerColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: PartnerColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: PartnerColors.green, width: 1.6),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 74,
      backgroundColor: PartnerColors.surface,
      indicatorColor: Color(0x2219C65B),
      elevation: 8,
      shadowColor: Color(0x220B1D45),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: PartnerColors.navy,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
}
