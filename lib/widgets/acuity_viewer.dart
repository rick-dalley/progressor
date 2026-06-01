import 'package:flutter/material.dart';
import 'package:triage/widgets/pulsing_icon.dart';
import '../app_theme.dart';
import '../classes/acuity.dart';

class AcuityViewer extends StatelessWidget {
  final Acuity acuity;

  const AcuityViewer({super.key, required this.acuity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Dropping top padding to 0.0 allows the header container to fuse with the very top of the sheet
      padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // This Container now captures the entire top crown of the sheet
          Container(
            width: double.infinity,
            color: AppTheme.acuityBackgroundColors[acuity.level],
            padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0), // 12px padding above the handle
            child: Column(
              children: [
                // Grab handle sits comfortably inside the matching tinted background
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).hintColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    acuity.level == AcuityLevel.notUrgent
                    ? PulsingIcon(icon: AppTheme.acuityIcons[acuity.level]!, color: AppTheme.acuityColors[acuity.level]!, size: 32,)
                    :Icon(
                      AppTheme.acuityIcons[acuity.level],
                      size: 32,
                      color: AppTheme.acuityColors[acuity.level],
                      shadows: [
                        Shadow(
                          color: Colors.black.withAlpha(64), // Soft dark shadow layer
                          offset: const Offset(2, 2), // Pushes the shadow subtly downward
                          blurRadius: 4.0, // Keeps the shadow soft and realistic
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(acuity.statusName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Body Content Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24.0),
                const Text(
                  "INTERVENTION WINDOW",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  "${acuity.interventionWindow} minutes",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                ),
                const SizedBox(height: 24.0),
                const Text(
                  "CLINICAL PICTURE",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  acuity.clinicalPicture,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(210),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
