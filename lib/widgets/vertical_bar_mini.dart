import 'package:flutter/material.dart';
import 'package:triage/widgets/vertical_range_indicator.dart';
import '../classes/vitals.dart';

class VitalTrendContainerSmall extends StatelessWidget {
  final CurrentVitals vitals;
  final double? height;

  const VitalTrendContainerSmall({
    super.key,
    required this.vitals,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    double sanitizedHeight = height ?? 36;
    return Row(
      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: vitals.mapValues.entries.map((entry) {
        final VitalType type = entry.key;
        final VitalInstance data = entry.value;
        final Limits limits = vitalsLimits[type]!;
        final String label = vitalTypeLabels[type] ?? "value";
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: VerticalRangeIndicator(
            height: sanitizedHeight,
            current: data.current,
            min: data.min,
            max: data.max,
            clinicalMin: limits.lower,
            clinicalMax: limits.upper,
            label: label.toUpperCase(),
            color: _getColorForType(type),
          ),
        );
      }).toList(),
    );
  }

  Color _getColorForType(VitalType type) {
    // Basic color mapping logic
    switch (type) {
      case VitalType.systolic: return Colors.blue;
      case VitalType.diastolic: return Colors.blueGrey;
      case VitalType.pulse: return Colors.purple;
      case VitalType.spo2: return Colors.green;
      case VitalType.temperature: return Colors.brown;
      default: return Colors.grey;
    }
  }
}