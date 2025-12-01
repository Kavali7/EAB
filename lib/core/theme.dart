import 'package:flutter/material.dart';

class ChurchTheme {
  static const Color navy = Color(0xFF0A2342);
  static const Color gold = Color(0xFFF6B93B);
  static const Color slate = Color(0xFF102743);
  static const Color cloud = Color(0xFFF7F9FC);

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: cloud,
      colorScheme: ColorScheme.fromSeed(
        seedColor: navy,
        primary: navy,
        secondary: gold,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0.5,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0.6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(8),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: cloud,
        selectedColor: gold.withAlpha((255 * 0.15).round()),
        labelStyle: const TextStyle(color: slate, fontWeight: FontWeight.w600),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(fontWeight: FontWeight.w700, color: slate),
        titleMedium: const TextStyle(fontWeight: FontWeight.w600, color: slate),
      ),
    );
  }
}
