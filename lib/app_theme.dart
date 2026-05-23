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
  // Canadian Triage Acuity Colors (CTAS 1 to 5)
  // static const Color resuscitation = Color(0xFFD32F2F); // Level 1 - Crimson Red (Immediate life threat)
  // static const Color emergent = Color(0xFFE65100);     // Level 2 - Deep Safety Orange (Critical condition)
  // static const Color urgent = Color(0xFFFBC02D);       // Level 3 - Rich Amber Yellow (Severe/Urgent)
  // static const Color lessUrgent = Color(0xFF2E7D32);   // Level 4 - Forest/Clinical Green (Mild to Moderate)
  // static const Color nonUrgent = Color(0xFF1976D2);    // Level 5 - Royal/Signal Blue (Minor/Routine)
  // static const Color resuscitationBackground = Color(0x1AD32F2F); // Level 1 - Crimson Red (Immediate life threat)
  // static const Color emergentBackground = Color(0x1AE65100);     // Level 2 - Deep Safety Orange (Critical condition)
  // static const Color urgentBackground = Color(0x1AFBC02D);       // Level 3 - Rich Amber Yellow (Severe/Urgent)
  // static const Color lessUrgentBackground = Color(0x1A2E7D32);   // Level 4 - Forest/Clinical Green (Mild to Moderate)
  // static const Color nonUrgentBackground = Color(0x1A1976D2);// Level 5 - Royal/Signal Blue (Minor/Routine)

  static const Color resuscitation = Color(0xFFC2185B); // Level 1 - Crimson Berry (Deep cool red/pink base)
  static const Color emergent = Color(0xFFE65100);     // Level 2 - Burnt Ochre (Deep earthy safety orange)
  static const Color urgent = Color(0xFFFFEA00);       // Level 3 - Lemon Zest (Bright, high-contrast yellow)
  static const Color lessUrgent = Color(0xFF1B5E20);   // Level 4 - Forest Green (Deep dark value)
  static const Color nonUrgent = Color(0xFF0D47A1);
  static  Color resuscitationBackground = resuscitation.withAlpha(64); // Level 1 - Crimson Red (Immediate life threat)
  static  Color emergentBackground = emergent.withAlpha(64);     // Level 2 - Deep Safety Orange (Critical condition)
  static  Color urgentBackground = urgent .withAlpha(64);      // Level 3 - Rich Amber Yellow (Severe/Urgent)
  static  Color lessUrgentBackground = lessUrgent.withAlpha(64);   // Level 4 - Forest/Clinical Green (Mild to Moderate)
  static  Color nonUrgentBackground =nonUrgent.withAlpha(64); // Level 5 - Royal/Signal Blue (Minor/Routine)

  static const Map<int, Color> acuityColors = {
    0: resuscitation,
    1: emergent,
    2: urgent,
    3: lessUrgent,
    4: nonUrgent,
  };
  static  Map<int, Color> acuityBackgroundColors = {
    0: resuscitationBackground,
    1: emergentBackground,
    2: urgentBackground,
    3: lessUrgentBackground,
    4: nonUrgentBackground,
  };
  static const Map<int, IconData> acuityIcons = {
    0: Icons.signal_cellular_connected_no_internet_4_bar_sharp,
    1: Icons.signal_cellular_4_bar,
    2: Icons.signal_cellular_alt_2_bar,
    3: Icons.signal_cellular_alt_1_bar,
    4: Icons.signal_cellular_0_bar,

  };
  // Background colors
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