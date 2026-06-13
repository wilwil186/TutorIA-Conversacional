import 'package:flutter/material.dart';

/// Simple, friendly Duolingo-ish theme.
const seedGreen = Color(0xFF58CC02);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: seedGreen,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF7F7F7),
    appBarTheme: const AppBarTheme(centerTitle: true),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
