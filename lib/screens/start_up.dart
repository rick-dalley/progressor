import 'package:carbon_ui/carbon_ui.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CarbonStartupScreen(
      background: AppTheme.clinicalWhite,
      appName: 'Progressor',
      appNameColor: AppTheme.deepLogicViolet,
      // The transition point of the three — full violet-to-cyan gradient, gap
      // partway closed. See project_journey_mark_icon memory for the story this
      // maps to (Acuitage/Progressor/Ally = crisis/transition/settled).
      mark: const JourneyMark(size: 96, gradientColors: [AppTheme.deepLogicViolet, AppTheme.clinicalCyan]),
      progress: DatabaseManager.seedProgress,
      // Actually opening (and, on a genuinely fresh install, seeding) the database
      // now — rather than letting PatientRoster's own initState discover the need
      // to seed later with no visible progress — so the one-time seed happens
      // here, under the real progress readout above, and by the time the roster
      // appears its own query is already instant.
      initialize: () => DatabaseManager().database,
      onReady: () async {
        // The roster (with its demo data) is reachable immediately, profile or
        // not — registering is no longer a forced gate, it's an affordance under
        // the avatar button (a license icon until a profile is verified). See
        // LuminescaHomeState.
        if (context.mounted) Navigator.of(context).pushReplacementNamed('/roster');
      },
    );
  }
}
