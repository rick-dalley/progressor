import 'package:flutter/material.dart';
import '../app_theme.dart';

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
      // Load ML Engine here if needed
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
          ],
        ),
      ),
    );
  }
}
