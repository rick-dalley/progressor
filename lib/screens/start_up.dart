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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 5), // Starts well below the screen
      end: Offset.zero,          // Ends at its natural position
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    // Start the animation immediately
    _controller.forward();

    // 2. Run your heavy background tasks
    // These run in parallel while the user sees the animation
    await Future.wait([
      DatabaseManager().init(), // Initializes tables and seeds data
      // Future.delayed(const Duration(seconds: 2)), // Minimum splash time for "feel"
      // _yourMLEngine.load(),
    ]);

    // 3. Hand off to the main app once loading is complete
    if (mounted) {
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
      backgroundColor: AppTheme.monitorBlack, // Consistent with your clinical aesthetic
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "LUMINESCA",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            ClipRect( // Ensures the text only appears as it slides into the frame
              child: SlideTransition(
                position: _slideAnimation,
                child: Text(
                  "TRIAGE",
                  style: TextStyle(
                    color: AppTheme.deepLogicViolet, // Your brand action color
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