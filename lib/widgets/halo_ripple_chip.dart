import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'halo_ripple_widget.dart';

class AnimatedChip extends StatefulWidget {
  final IconData iconData;
  final String text;
  final Color? color;
  final Color? backgroundColor;
  final bool animate;

  const AnimatedChip({
    super.key,
    required this.iconData,
    required this.text,
    required this.color,
    required this.backgroundColor,
    this.animate = true,
  });

  @override
  State<AnimatedChip> createState() => AnimatedChipState();
}

class AnimatedChipState extends State<AnimatedChip> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final color = widget.color ?? AppTheme.lightTheme.primaryColor;
  late final backgroundColor = widget.backgroundColor ?? AppTheme.lightTheme.canvasColor;
  late final text = widget.text;

  @override
  void initState() {
    super.initState();
    // 2. Initialize the controller to dictate the speed of the ripple loop
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500), // 1.5 second ripple cycle
      vsync: this,
    )..repeat(); // .repeat() continuously resets from 0.0 to 1.0

    // 3. Define the animation curve (linear, ease-out, etc.)
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pulseController.dispose(); // Always clean up your controllers!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IconData icon = widget.iconData;
    Color iconColor = color;
    return Row(
      children: [
        widget.animate
            ? HaloRipple(
                iconData: Icons.add_alert_rounded,
                pulseAnimation: _pulseAnimation, // Pass the animation down
                themeColor: iconColor, // Customize color
                baseRadius: 40.0, // Customize size
              )
            : Icon(
                icon,
                size: 30,
                color: color,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(64), // Soft dark shadow layer
                    offset: const Offset(2, 2), // Pushes the shadow subtly downward
                    blurRadius: 4.0, // Keeps the shadow soft and realistic
                  ),
                ],
              ),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 16, color: color)),
      ],
    );
  }
}
