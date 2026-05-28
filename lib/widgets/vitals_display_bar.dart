import 'package:flutter/material.dart';
import '../app_theme.dart';

class VitalsData {
  final int pulse;
  final int systolic;
  final int diastolic;
  final double temp;
  final double spo2;

  VitalsData({
    required this.pulse,
    required this.systolic,
    required this.diastolic,
    required this.temp,
    required this.spo2,
  });
}

class VitalsBar extends StatelessWidget {
  final VitalsData vitals;
  final VoidCallback onAddPressed;
  final VoidCallback onHistoryPressed;

  const VitalsBar({
    super.key,
    required this.vitals,
    required this.onAddPressed,
    required this.onHistoryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight( // Ensures both containers match height perfectly
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. DATA AREA: Tapping here opens History
          Expanded(
            child: InkWell(
              onTap: onHistoryPressed,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.darkSlate,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  border: Border.all(color: Colors.white10, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _vitalItem('${vitals.systolic}/${vitals.diastolic}', "NIBP", "SYS/DIA", AppTheme.vitalsBP),
                    _vitalItem(vitals.pulse.toString(), "PULSE", "\u2661/MIN", AppTheme.vitalsPulse),
                    _vitalItem(vitals.spo2.toString(), "SpO2", "%", AppTheme.vitalsOxygen),
                    _vitalItem(vitals.temp.toString(), "TEMP", "°C", AppTheme.vitalsTemp),
                  ],
                ),
              ),
            ),
          ),

          // 2. ACTION CORNER: Tapping here jumps to Record Vitals
          InkWell(
            onTap: onAddPressed,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: Ink(
              width: 54,
              decoration: BoxDecoration(
                color: AppTheme.clinicalCyan,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vitalItem(String value, String label, String units, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withAlpha(196),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          units,
          style: TextStyle(
            color: color.withAlpha(150),
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}