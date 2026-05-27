import 'package:flutter/material.dart';
import 'package:triage/widgets/pulsing_icon.dart';

import '../app_theme.dart';

class PulsingChip extends StatefulWidget {
  final IconData iconData;
  final String? text;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final bool pulse;
  final bool shadowText;
  final VoidCallback onTap;

  const PulsingChip({
    super.key,
    required this.iconData,
    required this.text,
    required this.iconColor,
    required this.textColor,
    required this.backgroundColor,
    required this.pulse,
    required this.onTap,
    required this.shadowText,
  });

  @override
  State<StatefulWidget> createState() => PulsingChipState();
}

class PulsingChipState extends State<PulsingChip> {
  late Color iconColor = widget.iconColor ?? AppTheme.lightTheme.primaryColor;
  late Color textColor = widget.textColor ?? AppTheme.lightTheme.disabledColor;
  late Color backgroundColor = widget.backgroundColor ?? AppTheme.lightTheme.canvasColor;
  late String text = widget.text ?? "";
  late IconData icon = widget.iconData;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        widget.pulse
            ? PulsingIcon(icon: icon, color: iconColor, size: 32)
            : Icon(
                icon,
                size: 32,
                color: iconColor,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(64), // Soft dark shadow layer
                    offset: const Offset(2, 2), // Pushes the shadow subtly downward
                    blurRadius: 4.0, // Keeps the shadow soft and realistic
                  ),
                ],
              ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor).copyWith(
            shadows: widget.shadowText
                ? [
                    Shadow(
                      color: Colors.black.withAlpha(64), // Soft dark shadow layer
                      offset: const Offset(2, 2), // Pushes the shadow subtly downward
                      blurRadius: 4.0, // Keeps the shadow soft and realistic
                    ),
                  ]
                : null, // Passing null tells copyWith not to apply any shadows
          ),
        ),
      ],
    );
  }
}
