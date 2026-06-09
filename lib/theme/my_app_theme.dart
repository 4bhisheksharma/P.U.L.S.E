import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyAppTheme {
  // Color constants for dark theme
  static const Color _darkPrimary = Color(0xFF7C73FF);
  static const Color _darkSecondary = Color(0xFF9B8FFF);
  static const Color _darkBackground = Color(0xFF0F0F14);
  static const Color _darkSurface = Color(0xFF1A1A24);
  static const Color _darkCard = Color(0xFF212130);
  static const Color _darkBorder = Color(0xFF2D2D3A);
  static const Color _darkText = Color(0xFFE8E8F0);
  static const Color _darkTextSecondary = Color(0xFFB0B0C0);
  static const Color _darkError = Color(0xFFFF6B6B);
  static const Color _darkWarning = Color(0xFFFF9F43);
  static const Color _darkSuccess = Color(0xFF4CAF50);

  // Semantic color getters for easy access throughout the app
  static Color get primaryColor => _darkPrimary;
  static Color get secondaryColor => _darkSecondary;
  static Color get backgroundColor => _darkBackground;
  static Color get surfaceColor => _darkSurface;
  static Color get cardColor => _darkCard;
  static Color get borderColor => _darkBorder;
  static Color get textColor => _darkText;
  static Color get textSecondaryColor => _darkTextSecondary;
  static Color get errorColor => _darkError;
  static Color get warningColor => _darkWarning;
  static Color get successColor => _darkSuccess;

  static TextTheme _buildTextTheme() {
    final font = GoogleFonts.interTextTheme();

    return TextTheme(
      headlineLarge: font.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: _darkText,
        letterSpacing: -0.5,
      ),
      headlineMedium: font.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: _darkText,
        letterSpacing: -0.5,
      ),
      headlineSmall: font.headlineSmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _darkText,
        letterSpacing: -0.3,
      ),
      titleLarge: font.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _darkText,
      ),
      titleMedium: font.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _darkText,
      ),
      bodyLarge: font.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _darkText,
      ),
      bodyMedium: font.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _darkTextSecondary,
      ),
      bodySmall: font.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _darkTextSecondary,
      ),
      labelLarge: font.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme();

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,

      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        secondary: _darkSecondary,
        surface: _darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        error: _darkError,
      ),

      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _darkText),
        titleTextStyle: textTheme.titleLarge,
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
          shadowColor: _darkPrimary.withValues(alpha: 0.59),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkPrimary,
          side: const BorderSide(color: _darkBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _darkPrimary, width: 2),
        ),
        hintStyle: const TextStyle(
          color: _darkTextSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: _darkTextSecondary,
          fontSize: 14,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: _darkCard,
        selectedColor: _darkPrimary.withValues(alpha: 0.2),
        labelStyle: textTheme.bodyMedium,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        checkmarkColor: _darkPrimary,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: _darkPrimary,
        inactiveTrackColor: _darkPrimary.withValues(alpha: 0.15),
        thumbColor: _darkPrimary,
        overlayColor: _darkPrimary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkCard,
        contentTextStyle: textTheme.bodyLarge,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: _darkCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: textTheme.bodyLarge,
      ),

      iconTheme: const IconThemeData(color: _darkText, size: 24),

      dividerColor: _darkBorder,
      dividerTheme: const DividerThemeData(color: _darkBorder, thickness: 1),
    );
  }
}
