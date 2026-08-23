import 'package:flutter/material.dart';

class SooktaColors {
  const SooktaColors._();

  static const leafGreen = Color(0xFF5C9A81);
  static const darkGreen = Color(0xFF2E7D32);
  static const cream = Color(0xFFFDF8E1);
  static const mustard = Color(0xFFFFB931);
}

ThemeData buildSooktaTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: SooktaColors.leafGreen,
    primary: SooktaColors.leafGreen,
    secondary: SooktaColors.cream,
    tertiary: SooktaColors.mustard,
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: SooktaColors.cream,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: SooktaColors.leafGreen,
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SooktaColors.leafGreen,
        foregroundColor: Colors.white,
      ),
    ),
  );
}
