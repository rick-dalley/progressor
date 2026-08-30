import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup the "Triage" slide animation
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 5), // Starts well below the screen
      end: Offset.zero, // Ends at its natural position
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    _controller.forward(); // Start the "Triage" slide animation

    await Future.wait([
      // Actually opening (and, on a genuinely fresh install, seeding) the database
      // now — rather than letting PatientRoster's own initState discover the need to
      // seed later with no visible progress — so the one-time seed happens here,
      // under a real progress readout (see build()'s ValueListenableBuilder), and by
      // the time the roster appears its own query is already instant.
      DatabaseManager().database,
      Future.delayed(const Duration(seconds: 2)), // Minimum time to show your branding
    ]);

    if (mounted) {
      // Navigate to the actual home screen and remove the splash from history
      Navigator.of(context).pushReplacementNamed('/roster');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.clinicalWhite, // Consistent with your clinical aesthetic
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Progressor",
              style: TextStyle(
                color: AppTheme.deepLogicViolet,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            ClipRect(
              // Ensures the text only appears as it slides into the frame
              child: SlideTransition(
                position: _slideAnimation,
                child: Text(
                  "CASELOAD, INTAKE TO RELEASE",
                  style: TextStyle(
                    color: AppTheme.clinicalCyan, // Your brand action color
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                  ),
                ),
              ),
            ),
            // Only ever appears during a genuinely fresh install's one-time seed
            // (DatabaseManager.seedProgress stays null otherwise, every other launch)
            // — an indefinite spinner with no explanation is exactly what read as "the
            // app is frozen" before this existed.
            ValueListenableBuilder<double?>(
              valueListenable: DatabaseManager.seedProgress,
              builder: (context, progress, _) {
                if (progress == null) return const SizedBox(height: 32);
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    children: [
                      const Text(
                        "Preparing Progressor for Use",
                        style: TextStyle(
                          color: AppTheme.deepCharcoal,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Preparing Database ${(progress * 100).round()}%",
                        style: const TextStyle(color: AppTheme.deepCharcoal, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
