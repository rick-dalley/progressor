import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'classes/database_manager.dart';
import 'screens/patient_roster.dart';
import 'generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final dbManager = DatabaseManager();
  dbManager.init(overwrite:true);
  runApp(const LuminescaApp());
}

class LuminescaApp extends StatelessWidget {
  const LuminescaApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        S.delegate, // The generated delegate from your arb file
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      title: 'Luminesca - Triage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
                  color: AppTheme.deepLogicViolet,
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
                  color: AppTheme.clinicalCyan,
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