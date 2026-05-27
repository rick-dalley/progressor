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
  static const Color vitalsBP = Color(0xFFFFB300);
  static const Color vitalsOxygen = Color(0xFF82B1FF);
  static const Color vitalsPulse = Color(0xFF00E676);
  static const Color vitalsTemp = Color(0xFFFFFFFF);
  static const Color monitorBlack = Color(0xFF000000);

  static const Color resuscitation = Color(0xFF043AC4);
  static const Color emergent = Color(0xFFFC900F);
  static const Color urgent = Color(0xFFFFEA00);
  static const Color lessUrgent = Color(0xFF23C402);
  static const Color nonUrgent = Color(0xFFFFFFFF);

  static  Color resuscitationBackground = resuscitation.withAlpha(96);
  static  Color emergentBackground = emergent.withAlpha(96);
  static  Color urgentBackground = urgent .withAlpha(96);
  static  Color lessUrgentBackground = lessUrgent.withAlpha(96);
  static  Color nonUrgentBackground = nonUrgent.withAlpha(96);

  static const Map<int, Color> acuityColors = {
    0: resuscitation,
    1: emergent,
    2: urgent,
    3: lessUrgent,
    4: nonUrgent,
  };

  static const Map<int, Color> acuityFontColors = {
    0: resuscitation,
    1: emergent,
    2: Color(0xFF000000),
    3: lessUrgent,
    4: Color(0xFF080808),
  };

  static  Map<int, Color> acuityBackgroundColors = {
    0: resuscitationBackground,
    1: emergentBackground,
    2: urgentBackground,
    3: lessUrgentBackground,
    4: nonUrgentBackground,
  };

  static const Map<int, IconData> acuityIcons = {
    0: Icons.emergency,
    1: Icons.circle_rounded,
    2: Icons.circle_rounded,
    3: Icons.circle_rounded,
    4: Icons.circle_rounded,
  };

  // Background colors
  static const Color canvasColor = Color(0xFFF5F5F7);
  static const Color cardBorder = Color(0xFFAAAAAA);
  static const Color chipBorder = Color(0xFFCCCCCC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color defaultFontColor = deepCharcoal;
  static const Color defaultInverseFontColor = surfaceColor;
  static const Color processStepPrimary = Color(0xFF2E7D32);
  static const Color processStepTerminal = Color(0xFFFF3232);
  static const Color processStepPlain = Color(0xFFA0A0A0);
  static const Color processStepPossible = Color(0xFF90A4AE);
  static const Color processStepRequired = Color(0xFF1E88E5);
  static const Color processStepActive = Color(0xFF7C4DFF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: canvasColor,
      textTheme: GoogleFonts.inclusiveSansTextTheme(),
      colorScheme: ColorScheme.light(
        primary: deepLogicViolet,
        secondary: clinicalCyan,
        surface: surfaceColor,
      ),

      // AppBar styling for Light Mode (Clean & Professional)
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(color: defaultFontColor, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: deepLogicViolet),
      ),

      // FAB remains consistent but pops against the white
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: deepLogicViolet,
        foregroundColor: defaultInverseFontColor,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepLogicViolet,
          foregroundColor: defaultInverseFontColor,
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
        fillColor: surfaceColor,
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