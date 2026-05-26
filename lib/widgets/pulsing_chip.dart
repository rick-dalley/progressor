
import 'package:flutter/material.dart';
import 'package:triage/widgets/pulsing_icon.dart';

import '../app_theme.dart';

class PulsingChip extends StatefulWidget{
  final IconData iconData;
  final String? text;
  final Color? color;
  final Color? backgroundColor;
  final bool pulse;
  final VoidCallback onTap;
  const PulsingChip({
    super.key,
    required this.iconData,
    required this.text,
    required this.color,
    required this.backgroundColor,
    required this.pulse,
    required this.onTap,
});

  @override
  State<StatefulWidget> createState() => PulsingChipState();

}

class PulsingChipState extends State<PulsingChip>{
  late Color color = widget.color ?? AppTheme.lightTheme.primaryColor;
  late Color backgroundColor = widget.color ?? AppTheme.lightTheme.canvasColor;
  late String text = widget.text ?? "";
  late IconData icon = widget.iconData;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        widget.pulse
            ? PulsingIcon(icon: icon, color: color, size: 32)
            : Icon(
          icon,
          size: 32,
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

