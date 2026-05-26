import 'package:flutter/material.dart';

class HaloRipple extends StatelessWidget {
  final IconData iconData;
  final Color themeColor;
  final double baseRadius;

  // Changing this to Animation<double> gives us access to both
  // the animation state (.value) and the notification engine cleanly.
  final Animation<double> pulseAnimation;

  const HaloRipple({
    super.key,
    required this.iconData,
    required this.pulseAnimation,
    this.themeColor = const Color(0xFFC62828),
    this.baseRadius = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      // 1. FIXED: Pass the dynamic icon data parameter as the static child
      // instead of hardcoding the warning icon here.
      child: Icon(
        iconData,
        color: themeColor,
        size: baseRadius * 0.66, // Scales icon cleanly inside the box
      ),
      builder: (context, staticIcon) {
        // 2. Isolates the math calculations locally inside the builder loop
        final double currentScale = pulseAnimation.value;

        // As scale goes from 0.0 to 1.0, opacity fades from full to gone
        final double currentOpacity = (1.0 - currentScale).clamp(0.0, 1.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // The expanding background halo ring layer
            Container(
              width: baseRadius * currentScale,
              height: baseRadius * currentScale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeColor.withValues(alpha: 0.25 * currentOpacity),
              ),
            ),
            // The static icon sitting on top does NOT rebuild layout or paint vectors
            staticIcon!,
          ],
        );
      },
    );
  }
}