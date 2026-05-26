import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'halo_ripple_widget.dart';

class HaloRippleChip extends StatefulWidget {
  final IconData iconData;
  final String text;
  final Color? color;
  final Color? backgroundColor;
  final bool animate;

  const HaloRippleChip({
    super.key,
    required this.iconData,
    required this.text,
    this.color,
    this.backgroundColor,
    this.animate = true,
  });

  @override
  State<HaloRippleChip> createState() => HaloRippleChipState();
}

class HaloRippleChipState extends State<HaloRippleChip> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeOut);

    if (widget.animate) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant HaloRippleChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle toggleable animations dynamically if state changes at runtime
    if (widget.animate && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!widget.animate && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Resolve themes cleanly inside the build loop to prevent stale widget properties
    final resolvedColor = widget.color ?? AppTheme.lightTheme.primaryColor;
    const double iconContainerSize = 48.0; // Anchors the ripple bounds explicitly

    return Row(
      mainAxisSize: MainAxisSize.min, // Prevents row from greedily stealing horizontal space
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Constrain the icon and its halo effects to a static box so it never offsets the text
        SizedBox(
          width: iconContainerSize,
          height: iconContainerSize,
          child: Center(
            child: widget.animate
                ? HaloRipple(
              iconData: widget.iconData,
              pulseAnimation: _pulseAnimation,
              themeColor: resolvedColor,
              baseRadius: 40.0,
            )
                : Icon(
              widget.iconData,
              size: 30,
              color: resolvedColor,
              shadows: [
                Shadow(
                  color: Colors.black.withAlpha(64),
                  offset: const Offset(2, 2),
                  blurRadius: 4.0,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8), // Clean spacing padding
        Text(
          widget.text,
          style: TextStyle(
            fontSize: 16,
            color: resolvedColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}