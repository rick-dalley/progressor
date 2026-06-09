import 'package:flutter/material.dart';

import '../classes/toxidrome.dart';

class PupilSelector extends StatelessWidget {
  final PupilState selected;
  final Function(PupilState) onSelected;

  const PupilSelector({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: PupilState.values.map((state) {
        final isSelected = selected == state;
        final size = _getSizeForState(state);

        return GestureDetector(
          onTap: () => onSelected(state),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Colors.blue, width: 3) : null,
                ),
                child: CustomPaint(
                  size: const Size(60, 60),
                  painter: PupilPainter(pupilSize: size),
                ),
              ),
              const SizedBox(height: 8),
              Text(state.name.toUpperCase(),
                  style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        );
      }).toList(),
    );
  }

  double _getSizeForState(PupilState state) {
    switch (state) {
      case PupilState.pinpoint: return 0.2; // 20% of eye
      case PupilState.normal: return 0.5;  // 50% of eye
      case PupilState.dilated: return 0.8; // 80% of eye
    }
  }
}

class PupilPainter extends CustomPainter {
  final double pupilSize;
  PupilPainter({required this.pupilSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Sclera/Iris background
    final gradient = RadialGradient(colors: [Colors.white, Colors.brown.shade300, Colors.brown.shade700]);
    canvas.drawCircle(center, radius, Paint()..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius)));

    // 2. Black Pupil
    canvas.drawCircle(center, radius * pupilSize, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}