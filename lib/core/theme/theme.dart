import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 1. Professional & Modern Palette
  static const Color primarySeedColor = Color(0xFF005F87); // A deep, professional blue

  // 2. Professional & Readable Typography
  static final TextTheme _textTheme = TextTheme(
    displayLarge: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.bold),
    titleLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600),
    bodyMedium: GoogleFonts.inter(fontSize: 14),
    labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
    bodySmall: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
  );

  static final TextTheme _darkTextTheme = _textTheme.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  );

  // 3. Centralized Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primarySeedColor,
      brightness: Brightness.light,
    ),
    textTheme: _textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 1,
      surfaceTintColor: Colors.transparent, // Prevents tinting on scroll
      iconTheme: const IconThemeData(color: Colors.black, size: 24),
      titleTextStyle: _textTheme.titleLarge?.copyWith(color: Colors.black),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: _textTheme.labelLarge,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: const BorderSide(color: Colors.black26, width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black26, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black26, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primarySeedColor, width: 2),
      ),
    ),
  );

  // 4. Centralized Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primarySeedColor,
      brightness: Brightness.dark,
    ),
    textTheme: _darkTextTheme,
    appBarTheme: AppBarTheme(
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: _darkTextTheme.titleLarge?.copyWith(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: _textTheme.labelLarge,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: const BorderSide(color: Colors.white38, width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white38, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white38, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primarySeedColor, width: 2),
      ),
    ),
  );
}

// 5. Theme Provider for State Management
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
}
