import 'package:flutter/material.dart';
import 'package:triage/widgets/vertical_range_indicator.dart';
import '../classes/vitals.dart';

class CurrentMetrics extends StatelessWidget {
  final CurrentVitalsRecord? vitals;
  final double? height;

  const CurrentMetrics({
    super.key,
    required this.vitals,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    double sanitizedHeight = height ?? 108;

    return  vitals == null
    ? SizedBox()
    : Row(
      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: vitals!.mapValues.entries.map((entry) {
        final MetricType type = entry.key;
        final MetricInstance data = entry.value;
        final Limits limits = vitalsLimits[type]!;
        final String label = metricDisplayLabels[type] ?? "value";
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 4.0),
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

  Color _getColorForType(MetricType type) {
    // Basic color mapping logic
    switch (type) {
      case MetricType.systolic: return Colors.blue;
      case MetricType.diastolic: return Colors.blueGrey;
      case MetricType.pulse: return Colors.purple;
      case MetricType.spo2: return Colors.green;
      case MetricType.temperature: return Colors.brown;
      default: return Colors.grey;
    }
  }
}