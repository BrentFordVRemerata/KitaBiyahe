import 'package:flutter/material.dart';

abstract final class KitaColors {
  static const ink = Color(0xFF173D32);
  static const forest = Color(0xFF134C3A);
  static const forestDeep = Color(0xFF0C382C);
  static const mint = Color(0xFFE3F1E7);
  static const mintBright = Color(0xFFD1E9D8);
  static const canvas = Color(0xFFF8F8F1);
  static const cream = Color(0xFFFDFBF5);
  static const border = Color(0xFFE0E7DD);
  static const muted = Color(0xFF5B7568);
  static const coral = Color(0xFFDF8458);
  static const warning = Color(0xFF966137);
}

ThemeData kitaTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: KitaColors.forest,
    primary: KitaColors.forest,
    secondary: KitaColors.coral,
    onSecondary: KitaColors.forestDeep,
    surface: KitaColors.cream,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: KitaColors.canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: KitaColors.canvas,
      foregroundColor: KitaColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        color: KitaColors.ink,
        letterSpacing: -1.8,
      ),
      displayMedium: TextStyle(
        fontSize: 33,
        fontWeight: FontWeight.w800,
        color: KitaColors.ink,
        letterSpacing: -1.1,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: KitaColors.ink,
        letterSpacing: -0.7,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: KitaColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: KitaColors.ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: KitaColors.ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: KitaColors.ink),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: KitaColors.muted),
    ),
    cardTheme: const CardThemeData(
      color: KitaColors.cream,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    dividerColor: KitaColors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: KitaColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: KitaColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: KitaColors.forest, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KitaColors.forest,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        minimumSize: const Size(48, 50),
        side: const BorderSide(color: KitaColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: KitaColors.cream,
      height: 76,
      indicatorColor: KitaColors.mint,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: KitaColors.cream,
      selectedColor: KitaColors.mint,
      side: const BorderSide(color: KitaColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      labelStyle: const TextStyle(
        color: KitaColors.ink,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
