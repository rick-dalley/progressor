import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/acuity.dart';
import 'package:triage/classes/body_zone.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:triage/screens/staff_screen.dart';
import 'package:triage/screens/start_up.dart';
import 'classes/action.dart';
import 'classes/drugs.dart';
import 'classes/phase_state_handlers.dart';
import 'classes/staff.dart';
import 'generated/l10n.dart';
import 'screens/patient_roster.dart';
import 'app_theme.dart';

Future<void> main() async {
  // Ensure the binding is ready for the splash screen to render
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
      routes: {'/roster': (context) => const LuminescaHome()},
    );
  }
}

class LuminescaHome extends StatefulWidget {
  const LuminescaHome({super.key});

  @override
  State<StatefulWidget> createState() => LuminescaHomeState();
}

class LuminescaHomeState extends State<LuminescaHome> {
  // We make the initialization a Future that we can listen to
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      DatabaseManager().database,
      PhasesFactory.instance.initialize('assets/process/phases.json'),
      PatientActionFactory.instance.initialize('assets/patients/patient_actions.json'),
      AcuityFactory.instance.initialize('assets/assessment/mental_health_acuity.json'),
      TouchImageFactory.instance.initialize('assets/images/touch_points.json'),
      StaffFactory.instance.initialize(),
      DrugFactory.instance.initialize(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.inclusiveSans(fontSize: 20, letterSpacing: 0.5),
            children: const [
              TextSpan(
                text: 'CWICare',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.deepLogicViolet, letterSpacing: 1.2),
              ),
              TextSpan(
                text: ' — ',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300),
              ),
              TextSpan(
                text: 'Acuitage',
                style: TextStyle(fontWeight: FontWeight.w400, color: AppTheme.clinicalCyan),
              ),
            ],
          ),
        ),
        actions: [IconButton(onPressed: () => showStaff(context), icon: const Icon(Symbols.person))],
      ),
      // The Roster stays in the tree at all times (so it lays out),
      // and we only animate the loading overlay on top.
      body: Stack(
        children: [
          // 1. The Roster: Always present and laid out, just hidden by the stack
          const PatientRoster(),

          // 2. The Loading Overlay: Only exists while loading
          FutureBuilder(
            future: _initFuture,
            builder: (context, snapshot) {
              final isWaiting = snapshot.connectionState == ConnectionState.waiting;

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: isWaiting
                    ? Container(
                        key: const ValueKey('loading'),
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink(key: ValueKey('loaded')),
              );
            },
          ),
        ],
      ),
    );
  }

  void showStaff(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StaffScreen(),
    );
  }
}
