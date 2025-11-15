import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF4A7AFF);
  static const Color primaryColorLight = Color(0xFF91B4FF);
  static const Color primaryColorDark = Color(0xFF1E56CC);
  
  // Secondary colors
  static const Color secondaryColor = Color(0xFF52C41A);
  static const Color secondaryColorLight = Color(0xFF8AE354);
  static const Color secondaryColorDark = Color(0xFF2B8000);
  
  // Accent colors
  static const Color accentColor = Color(0xFFFA8C16);
  
  // Background colors
  static const Color scaffoldDarkColor = Color(0xFF121212);
  static const Color cardDarkColor = Color(0xFF1E1E1E);
  static const Color surfaceDarkColor = Color(0xFF252525);
  
  // Text colors
  static const Color textPrimaryDarkColor = Color(0xFFFFFFFF);
  static const Color textSecondaryDarkColor = Color(0xFFB3B3B3);
  static const Color textDisabledDarkColor = Color(0xFF757575);
  
  // Error color
  static const Color errorColor = Color(0xFFF5222D);
  
  // Status colors
  static const Color successColor = Color(0xFF52C41A);
  static const Color warningColor = Color(0xFFFADB14);
  static const Color infoColor = Color(0xFF1890FF);
  
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: primaryColorDark,
      onPrimaryContainer: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: secondaryColorDark,
      onSecondaryContainer: Colors.white,
      tertiary: accentColor,
      onTertiary: Colors.white,
      error: errorColor,
      onError: Colors.white,
      background: scaffoldDarkColor,
      onBackground: textPrimaryDarkColor,
      surface: cardDarkColor,
      onSurface: textPrimaryDarkColor,
    ),
    scaffoldBackgroundColor: scaffoldDarkColor,
    cardColor: cardDarkColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: cardDarkColor,
      foregroundColor: textPrimaryDarkColor,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimaryDarkColor),
      displayMedium: TextStyle(color: textPrimaryDarkColor),
      displaySmall: TextStyle(color: textPrimaryDarkColor),
      headlineLarge: TextStyle(color: textPrimaryDarkColor),
      headlineMedium: TextStyle(color: textPrimaryDarkColor),
      headlineSmall: TextStyle(color: textPrimaryDarkColor),
      titleLarge: TextStyle(color: textPrimaryDarkColor),
      titleMedium: TextStyle(color: textPrimaryDarkColor),
      titleSmall: TextStyle(color: textPrimaryDarkColor),
      bodyLarge: TextStyle(color: textPrimaryDarkColor),
      bodyMedium: TextStyle(color: textPrimaryDarkColor),
      bodySmall: TextStyle(color: textSecondaryDarkColor),
      labelLarge: TextStyle(color: textPrimaryDarkColor),
      labelMedium: TextStyle(color: textPrimaryDarkColor),
      labelSmall: TextStyle(color: textSecondaryDarkColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: primaryColor, width: 1.5),
        foregroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDarkColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textSecondaryDarkColor),
      hintStyle: const TextStyle(color: textDisabledDarkColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardDarkColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryDarkColor,
      type: BottomNavigationBarType.fixed,
    ),
    dividerColor: Colors.white.withOpacity(0.1),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return Colors.transparent;
      }),
      side: const BorderSide(color: textSecondaryDarkColor),
    ),
  );
}
