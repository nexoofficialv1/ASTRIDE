import 'package:flutter/material.dart';

ThemeData buildAstrideTheme() {
  const navy = Color(0xFF0D1B3D);
  const green = Color(0xFF22C55E);
  final scheme = ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: green, surface: Colors.white);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF4F6FB),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF4F6FB), elevation: 0, scrolledUnderElevation: 0),
    cardTheme: CardThemeData(elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
    inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none)),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
    navigationBarTheme: const NavigationBarThemeData(height: 72, indicatorColor: Color(0xFFE8E7FF)),
  );
}
