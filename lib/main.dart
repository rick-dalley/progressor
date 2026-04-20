import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/patient_roster.dart';

void main() {
  runApp(const LuminescaApp());
}

class LuminescaApp extends StatelessWidget {
  const LuminescaApp({super.key});

  // --- Luminesca Brand Palette ---
  static const Color navyIntelligent = Color(0xFF1A365D); // Smart / Authority
  static const Color greenTherapeutic = Color(0xFF4A7856); // Relaxing / Healing
  static const Color surfaceWhite = Color(0xFFF8F9FA);   // Anti-glare background

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luminesca - Triage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // Global font configuration for "Inclusive Sans"
        textTheme: GoogleFonts.inclusiveSansTextTheme(
          Theme.of(context).textTheme,
        ),

        colorScheme: ColorScheme.fromSeed(
          seedColor: navyIntelligent,
          primary: navyIntelligent,
          secondary: greenTherapeutic,
          surface: surfaceWhite,
          background: Colors.white,
        ),

        // Styling for all AppBars in the suite
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: navyIntelligent),
        ),
      ),
      home: const LuminescaHome(),
    );
  }
}

class LuminescaHome extends StatelessWidget {
  const LuminescaHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The "RichText" implementation to fix the branding hierarchy
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.inclusiveSans(
              fontSize: 20,
              letterSpacing: 0.5,
            ),
            children: const [
              TextSpan(
                text: 'LUMINESCA',
                style: TextStyle(
                  fontWeight: FontWeight.w700, // Bold for the core brand
                  color: LuminescaApp.navyIntelligent,
                  letterSpacing: 1.2,
                ),
              ),
              TextSpan(
                text: ' — ',
                style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w300
                ),
              ),
              TextSpan(
                text: 'Triage',
                style: TextStyle(
                  fontWeight: FontWeight.w400, // Regular/Lighter for the app function
                  color: LuminescaApp.greenTherapeutic,
                ),
              ),
            ],
          ),
        ),
      ),
      // This will now display your roster using the Inclusive Sans theme
      body: const PatientRoster(),
    );
  }
}