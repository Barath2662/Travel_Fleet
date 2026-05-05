import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _brandPrimaryLight = Color(0xFF2563EB); // Blue
  static const _brandSecondaryLight = Color(0xFF009688); // Teal
  static const _brandTertiaryLight = Color(0xFFFF9800); // Orange
  static const _brandAccentLight = Color(0xFFFF9800); // Orange
  static const _surfaceLight = Color(0xFFFFFFFF);
  static const _backgroundLight = Color(0xFFF5F5F5);
  static const _textPrimaryLight = Color(0xFF111827);

  static const _brandPrimaryDark = Color(0xFF2563EB); // Blue
  static const _brandSecondaryDark = Color(0xFF009688); // Teal
  static const _brandTertiaryDark = Color(0xFFFF9800); // Orange
  static const _surfaceDark = Color(0xFF1E1E1E);
  static const _backgroundDark = Color(0xFF121212);
  static const _textPrimaryDark = Color(0xFFFFFFFF);

  // Common Shape
  static final _defaultShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );

  static final _lightTextTheme = GoogleFonts.spaceGroteskTextTheme().apply(
        bodyColor: _textPrimaryLight,
        displayColor: _textPrimaryLight,
      );

  static final _darkTextTheme = GoogleFonts.spaceGroteskTextTheme().apply(
        bodyColor: _textPrimaryDark,
        displayColor: _textPrimaryDark,
      );

  static final lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
    textTheme: _lightTextTheme,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: _brandPrimaryLight,
      onPrimary: Colors.white,
      secondary: _brandSecondaryLight,
      onSecondary: Colors.white,
      tertiary: _brandTertiaryLight,
      onTertiary: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: _surfaceLight,
      onSurface: _textPrimaryLight,
      outline: Color(0xFFE5E7EB),
    ),
    scaffoldBackgroundColor: _backgroundLight,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: _textPrimaryLight,
      iconTheme: IconThemeData(color: _textPrimaryLight),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _textPrimaryLight,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shadowColor: Colors.black.withAlpha((0.05 * 255).round()),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _surfaceLight,
      shape: _defaultShape,
      clipBehavior: Clip.antiAlias,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: _brandPrimaryLight,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: _defaultShape,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        foregroundColor: _brandPrimaryLight,
        side: const BorderSide(color: _brandPrimaryLight, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: _defaultShape,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _brandPrimaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _brandPrimaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Colors.black54),
      hintStyle: const TextStyle(color: Colors.black38),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      iconColor: _brandAccentLight,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _brandPrimaryLight,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade200,
      thickness: 1,
      space: 1,
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
    textTheme: _darkTextTheme,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: _brandPrimaryDark,
      onPrimary: Colors.white,
      secondary: _brandSecondaryDark,
      onSecondary: Colors.white,
      tertiary: _brandTertiaryDark,
      onTertiary: Colors.black,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: _surfaceDark,
      onSurface: _textPrimaryDark,
      outline: Color(0xFF2A2A2A),
    ),
    scaffoldBackgroundColor: _backgroundDark,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: _textPrimaryDark,
      iconTheme: IconThemeData(color: _textPrimaryDark),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _textPrimaryDark,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shadowColor: Colors.black.withAlpha((0.2 * 255).round()),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _surfaceDark,
      shape: _defaultShape,
      clipBehavior: Clip.antiAlias,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: _brandPrimaryDark,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: _defaultShape,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        foregroundColor: _brandPrimaryDark,
        side: const BorderSide(color: _brandPrimaryDark, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: _defaultShape,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _brandPrimaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _brandPrimaryDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Colors.white54),
      hintStyle: const TextStyle(color: Colors.white38),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      iconColor: _brandSecondaryDark,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _brandPrimaryDark,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.white12,
      thickness: 1,
      space: 1,
    ),
  );
}
