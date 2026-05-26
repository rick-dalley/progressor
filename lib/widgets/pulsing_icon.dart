import 'package:flutter/material.dart';

class PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final int duration;

  const PulsingIcon({
    super.key,
    required this.icon,
    required this.color,
    this.duration = 400,
    this.size = 24.0,
  });

  @override
  State<PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<PulsingIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Set up a smooth 1.2-second pulse loop
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.duration),
      vsync: this,
    )..repeat(reverse: true); // Loops back and forth automatically

    // Keeps the pulse subtle (scaling from 90% to 115% size)
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Crucial to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. RepaintBoundary isolates this widget onto its own GPU layer
    return RepaintBoundary(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          widget.icon,
          color: widget.color,
          size: widget.size,
        ),
      ),
    );
  }
}