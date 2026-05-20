import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color darkSlate = Color(0xFF1E1E1E);
  static const Color deepLogicViolet = Color(0xFF7C4DFF);
  static const Color clinicalCyan = Color(0xFF00BCD4);
  static const Color clinicalCyanCanvas = Color(0x1A00BCD4);
  static const Color clinicalWhite = Color(0xFFF8F9FA);
  // Hpspital Monitor Vitals Palette
  static const Color vitalsBP = Color(0xFFFFB300);   // Gold/Orange
  static const Color vitalsOxygen = Color(0xFF82B1FF); // Blue
  static const Color vitalsPulse = Color(0xFF00E676);  // Green
  static const Color vitalsTemp = Color(0xFFFFFFFF);   // White
  static const Color monitorBlack = Color(0xFF000000);
  static Color canvasColor = Colors.grey.shade200;
  static Color cardBorder = Colors.grey.shade200;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: clinicalWhite,
      textTheme: GoogleFonts.inclusiveSansTextTheme(),
      colorScheme: ColorScheme.light(
        primary: deepLogicViolet,
        secondary: clinicalCyan,
        surface: Colors.white,
      ),

      // AppBar styling for Light Mode (Clean & Professional)
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: deepLogicViolet),
      ),

      // FAB remains consistent but pops against the white
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: deepLogicViolet,
        foregroundColor: Colors.white,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepLogicViolet,
          foregroundColor: clinicalWhite,
          minimumSize: const Size.fromHeight(55), // Standardized height for easy hit-targets
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
          elevation: 2, // Subtle lift to distinguish from the background
        ),
      ),

      // Text fields that look "Interactive" but clean
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepCharcoal,
      cardColor: darkSlate,

      colorScheme: const ColorScheme.dark(
        primary: deepLogicViolet,
        secondary: clinicalCyan,
        surface: darkSlate,
      ),

      // FAB Styling
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: deepLogicViolet,
        foregroundColor: Colors.white,
      ),

      // AppBar Styling
      appBarTheme: const AppBarTheme(
        backgroundColor: deepCharcoal,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold
        ),
      ),

      // Input Decoration (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withAlpha(8),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: deepLogicViolet, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white10),
        ),
      ),
    );
  }
}