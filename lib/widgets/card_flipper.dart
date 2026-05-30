import 'dart:math';
import 'package:flutter/material.dart';

class FlippableCardController extends StatefulWidget {
  final Widget front;
  final Widget back;
  final double height;

  const FlippableCardController({
    super.key,
    required this.front,
    required this.back,
    this.height = 360,
  });

  @override
  State<FlippableCardController> createState() => FlippableCardControllerState();
}

class FlippableCardControllerState extends State<FlippableCardController> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animation = Tween<double>(begin: 0.0, end: pi).animate(_controller)
      ..addListener(() {
        setState(() {
          // Midpoint swap at 90 degrees
          _showFront = _controller.value < 0.5;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_controller.isDismissed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001) // 3D depth perception
              ..rotateY(_animation.value);

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: _showFront
                  ? widget.front
                  : Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(pi), // Corrects text mirroring
                child: widget.back,
              ),
            );
          },
        ),
      ),
    );
  }
}