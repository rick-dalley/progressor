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