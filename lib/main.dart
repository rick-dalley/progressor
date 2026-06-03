import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:triage/classes/acuity.dart';
import 'package:triage/screens/start_up.dart';
import 'classes/action.dart';
import 'classes/phase_state_handlers.dart';
import 'generated/l10n.dart';
import 'screens/patient_roster.dart';
import 'app_theme.dart';

Future<void> main() async {
  // Ensure the binding is ready for the splash screen to render
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await PhasesFactory.instance.initialize('assets/process/phases.json');
  await PatientActionFactory.instance.initialize('assets/patients/patient_actions.json');
  await AcuityFactory.instance.initialize('assets/assessments/mental_health_acuity.json');
  runApp(const LuminescaApp());
}

class LuminescaApp extends StatelessWidget {
  const LuminescaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ... your localization and theme config ...
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      // Change 'home' to StartupScreen
      home: const StartupScreen(),
      // Define a route for the roster so pushReplacementNamed works
      routes: {
        '/roster': (context) => const LuminescaHome(),
      },
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