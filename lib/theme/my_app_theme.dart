import 'package:flutter/material.dart';

class MyAppTheme {
  // Ultra-refined, modern minimalist dark theme palette
  static const Color _darkPrimary = Color(0xFF7C73FF);
  static const Color _darkSecondary = Color(0xFFA399FF);
  static const Color _darkBackground = Color(0xFF0A0A10);
  static const Color _darkSurface = Color(0xFF14141E);
  static const Color _darkCard = Color(0xFF1A1A28);
  static const Color _darkBorder = Color(0xFF26263A);
  static const Color _darkBorderLight = Color(0xFF32324C);
  static const Color _darkText = Color(0xFFF1F1F6);
  static const Color _darkTextSecondary = Color(0xFF9E9EB2);
  static const Color _darkTextMuted = Color(0xFF6B6B80);
  static const Color _darkError = Color(0xFFFF5C5C);
  static const Color _darkWarning = Color(0xFFF59E0B);
  static const Color _darkSuccess = Color(0xFF10B981);

  // Semantic color getters
  static Color get primaryColor => _darkPrimary;
  static Color get secondaryColor => _darkSecondary;
  static Color get backgroundColor => _darkBackground;
  static Color get surfaceColor => _darkSurface;
  static Color get cardColor => _darkCard;
  static Color get borderColor => _darkBorder;
  static Color get borderLightColor => _darkBorderLight;
  static Color get textColor => _darkText;
  static Color get textSecondaryColor => _darkTextSecondary;
  static Color get textMutedColor => _darkTextMuted;
  static Color get errorColor => _darkError;
  static Color get warningColor => _darkWarning;
  static Color get successColor => _darkSuccess;

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: _darkText,
        letterSpacing: -0.8,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: _darkText,
        letterSpacing: -0.5,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _darkText,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _darkText,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _darkText,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: _darkText,
      ),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: _darkTextSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _darkTextSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.2,
      ),
    );
  }

  static final ThemeData darkTheme = _buildDarkTheme();

  static ThemeData _buildDarkTheme() {
    final textTheme = _buildTextTheme();

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      useMaterial3: true,
      fontFamily: 'Roboto',

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
        centerTitle: false,
        iconTheme: const IconThemeData(color: _darkText, size: 22),
        titleTextStyle: textTheme.titleLarge,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkText,
          side: const BorderSide(color: _darkBorder, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _darkBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _darkPrimary, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: _darkTextMuted,
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: _darkTextSecondary,
          fontSize: 14,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: _darkSurface,
        selectedColor: _darkPrimary.withValues(alpha: 0.18),
        labelStyle: textTheme.bodyMedium,
        side: const BorderSide(color: _darkBorder, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        checkmarkColor: _darkPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: _darkPrimary,
        inactiveTrackColor: _darkBorder,
        thumbColor: _darkPrimary,
        overlayColor: _darkPrimary.withValues(alpha: 0.15),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurface,
        contentTextStyle: textTheme.bodyLarge,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _darkBorder, width: 1),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _darkBorder, width: 1),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurface,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          side: BorderSide(color: _darkBorder, width: 1),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: _darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _darkBorder, width: 1),
        ),
        textStyle: textTheme.bodyLarge,
      ),

      iconTheme: const IconThemeData(color: _darkText, size: 22),

      dividerColor: _darkBorder,
      dividerTheme: const DividerThemeData(color: _darkBorder, thickness: 1),
    );
  }
}
