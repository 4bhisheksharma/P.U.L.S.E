import 'package:flutter/material.dart';

class MyAppTheme {
  // Color constants for dark theme
  static const Color _darkPrimary = Color(0xFF7C73FF);
  static const Color _darkSecondary = Color(0xFF9B8FFF);
  static const Color _darkBackground = Color(0xFF0F0F14);
  static const Color _darkSurface = Color(0xFF1A1A24);
  static const Color _darkCard = Color(0xFF212130);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      useMaterial3: true,

      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        secondary: _darkSecondary,
        surface: _darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        error: Color(0xFFFF6B6B),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFFE8E8F0)),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE8E8F0),
          letterSpacing: 0.5,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 4,
          shadowColor: _darkPrimary.withAlpha(150),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkPrimary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 4,
        shadowColor: Colors.black.withAlpha(150),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2D2D3A), width: 1.5),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          // horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF2D2D3A), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF2D2D3A), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _darkPrimary, width: 2),
        ),
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),

      iconTheme: const IconThemeData(color: Color(0xFFE8E8F0), size: 24),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE8E8F0),
          letterSpacing: 0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE8E8F0),
          letterSpacing: 0.5,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFFE8E8F0),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFFB0B0C0),
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      dividerColor: const Color(0xFF2D2D3A),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2D2D3A),
        thickness: 1,
      ),
    );
  }
}
