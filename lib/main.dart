import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:carbon_ui/carbon_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/acuity.dart';
import 'package:triage/classes/body_zone.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:triage/classes/ems_handoff_import.dart';
import 'package:triage/classes/questionnaire_result_import.dart';
import 'package:triage/screens/import_ems_handoff_screen.dart';
import 'package:triage/screens/import_questionnaire_result_screen.dart';
import 'package:triage/screens/staff_screen.dart';
import 'package:triage/screens/start_up.dart';
import 'classes/action.dart';
import 'classes/drugs.dart';
import 'classes/phase_state_handlers.dart';
import 'classes/professional_gate.dart';
import 'classes/staff.dart';
import 'classes/symptom_evaluation.dart';
import 'generated/l10n.dart';
import 'screens/patient_roster.dart';
import 'app_theme.dart';

Future<void> main() async {
  // Ensure the binding is ready for the splash screen to render
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const LuminescaApp());
}

class LuminescaApp extends StatefulWidget {
  const LuminescaApp({super.key});

  @override
  State<LuminescaApp> createState() => _LuminescaAppState();
}

class _LuminescaAppState extends State<LuminescaApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _listenForEmsHandoffLinks();
  }

  // progressor://import?data=... (an EMS handoff, Acuitage today) and
  // progressor://questionnaireResult?data=... (a completed clinician-requested
  // questionnaire, Ally today) — both with no shared backend. Covers both a cold
  // start (app wasn't running yet) and a warm one.
  Future<void> _listenForEmsHandoffLinks() async {
    final Uri? initial = await _appLinks.getInitialLink();
    if (initial != null) _handleLink(initial);
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri uri) {
    if (uri.scheme != 'progressor') return;
    if (uri.host == 'import') {
      final EmsHandoffImportPayload? payload = EmsHandoffImportPayload.tryParse(uri);
      if (payload == null) return;
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => ImportEmsHandoffScreen(payload: payload)),
      );
    } else if (uri.host == 'questionnaireResult') {
      final QuestionnaireResultPayload? payload = QuestionnaireResultPayload.tryParse(uri);
      if (payload == null) return;
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => ImportQuestionnaireResultScreen(payload: payload)),
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
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
        '/onboarding': (context) => ProfessionalOnboardingWizard(
          onComplete: (profile) async {
            await DatabaseManager().saveProfessionalProfile(profile);
            if (profile.verificationStatus.grantsFullAccess && context.mounted) {
              await ProfessionalGate.handleNewlyVerified(context);
            }
            _navigatorKey.currentState?.pushReplacementNamed('/roster');
          },
        ),
      },
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
  ProfessionalProfile? _professionalProfile;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
    _loadProfile();
  }

  // The wizard guarantees a profile exists by the time this screen is ever reached
  // (StartupScreen routes to /onboarding first when none is on file), so this is just
  // populating the avatar button, never gating access to the roster itself.
  Future<void> _loadProfile() async {
    final profile = await DatabaseManager().getProfessionalProfile();
    if (mounted) setState(() => _professionalProfile = profile);
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
      SymptomFactory.instance.initialize('assets/assessment/symptoms.json'),
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
                text: 'Progressor',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.deepLogicViolet, letterSpacing: 1.2),
              ),
              TextSpan(
                text: ' — ',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300),
              ),
              TextSpan(
                text: 'Caseload',
                style: TextStyle(fontWeight: FontWeight.w400, color: AppTheme.clinicalCyan),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(onPressed: () => showStaff(context), icon: const Icon(Symbols.person)),
          if (_professionalProfile != null)
            ProfessionalAvatarButton(
              profile: _professionalProfile!,
              onSave: (updated) {
                setState(() => _professionalProfile = updated);
                DatabaseManager().saveProfessionalProfile(updated);
              },
              onNewlyVerified: () => ProfessionalGate.handleNewlyVerified(context),
            ),
        ],
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
