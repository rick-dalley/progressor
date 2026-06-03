import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/acuity.dart';

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

  static const Map<AcuityLevel, Color> acuityColors = {
    AcuityLevel.resuscitation: resuscitation,
    AcuityLevel.emergent: emergent,
    AcuityLevel.urgent: urgent,
    AcuityLevel.lessUrgent: lessUrgent,
    AcuityLevel.notUrgent: nonUrgent,
  };

  static const Map<AcuityLevel, Color> acuityFontColors = {
    AcuityLevel.resuscitation: resuscitation,
    AcuityLevel.emergent: emergent,
    AcuityLevel.urgent: Color(0xFF000000),
    AcuityLevel.lessUrgent: lessUrgent,
    AcuityLevel.notUrgent: Color(0xFF080808),
  };

  static  Map<AcuityLevel, Color> acuityBackgroundColors = {
    AcuityLevel.resuscitation: resuscitationBackground,
    AcuityLevel.emergent: emergentBackground,
    AcuityLevel.urgent: urgentBackground,
    AcuityLevel.lessUrgent: lessUrgentBackground,
    AcuityLevel.notUrgent: nonUrgentBackground,
  };

  static const Map<AcuityLevel, IconData> acuityIcons = {
    AcuityLevel.resuscitation: Icons.emergency,
    AcuityLevel.emergent: Icons.circle_rounded,
    AcuityLevel.urgent: Icons.circle_rounded,
    AcuityLevel.lessUrgent: Icons.circle_rounded,
    AcuityLevel.notUrgent: Icons.circle_rounded,
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


  static Map<String, IconData> eventIcons = {
    "ED_ARRIV" : Symbols.check_in_out,
    "ED_AMBUL": Symbols.ambulance,
    "ED_POLIC": Symbols.local_police,
    "ED_INTAK": Symbols.medical_information,
    "ID_ANONY": Symbols.person_off,
    "ID_MERGE": Symbols.person_check,
    "TR_START": Symbols.stethoscope,
    "TR_COMPL": Symbols.stethoscope_check,
    "TR_REASS": Symbols.stethoscope_arrow,
    "DC_LWBS": Symbols.run_circle,
    "ED_ALLOC": Symbols.short_stay,
    "MD_ASSES": Symbols.medical_mask,
    "VT_LOGGD": Symbols.vital_signs,
    "CL_NOTES": Symbols.clinical_notes,
    "ED_RELOC": Symbols.moving_beds,
    "LB_ORDER": Symbols.fluid_balance,
    "LB_DRAWN": Symbols.labs,
    "LB_HEMOL": Symbols.hematology,
    "LB_RESUL": Symbols.lab_profile,
    "IM_ORDER": Symbols.skeleton,
    "IM_START": Symbols.radiology,
    "IM_REJCT": Symbols.radiology, //add an xbadge
    "IM_INTER": Symbols.radiology, //add a magnifying glass
    "MD_ADMIN": Symbols.admin_meds,
    "PR_PERFM": Symbols.procedure,
    "BL_TRANS": Symbols.fluid,
    "MH_DETAIN":Symbols.psychiatry_sharp,
    "RE_START": Symbols.shield_lock,
    "RE_TERMN": Symbols.shield,
    "IS_OLATN": Symbols.safety_divider,
    "PO_POWER": Symbols.balance,
    "SEC_INCI": Symbols.admin_panel_settings,
    "CS_REQU": Symbols.person_add,
    "CS_ARRIV": Symbols.person,
    "CS_DECIS": Symbols.person_check,
    "DP_DECIS": Symbols.arrow_split,
    "WD_REQU": Symbols.contact_support,
    "WD_ALLOC": Symbols.ward,
    "WD_REPOR": Symbols.assignment,
    "ED_BOARD": Symbols.short_stay,
    "ED_DEPAR": Symbols.moving_beds,
    "OR_TRANS": Symbols.surgical,
    "IC_TRANS": Symbols.diversity_1,
    "WD_ARRIV": Symbols.inpatient,
    "DC_INSTR": Symbols.developer_guide,
    "DC_CLEAR": Symbols.door_open,
    "DC_COMPL": Symbols.home,
    "DC_AMA": Symbols.person_cancel,
    "DC_ELOPD": Symbols.luggage,
    "DC_SHEL": Symbols.night_shelter,
    "DC_EXTRN": Symbols.local_police,
    "HSP_TRNS": Symbols.local_hospital,
    "DC_PASTR": Symbols.family_home,
    "PT_DECEAS": Symbols.deceased,
    "DC_CORON": Symbols.deceased,
    "UNKNWN":Symbols.unknown_document
  };

}