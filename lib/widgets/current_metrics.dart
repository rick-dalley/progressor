import 'package:flutter/material.dart';
import 'package:carbon_ui/carbon_ui.dart';
import '../classes/tracked_metric.dart';

class CurrentMetrics extends StatelessWidget {
  final List<TrackedMetricSummary> metrics;
  final double? height;

  const CurrentMetrics({
    super.key,
    required this.metrics,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox();
    final double sanitizedHeight = height ?? 108;

    return Row(
      children: metrics.map((m) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 4.0),
          child: VerticalRangeIndicator(
            height: sanitizedHeight,
            current: m.current,
            min: m.min,
            max: m.max,
            clinicalMin: m.definition.healthyLower ?? m.min,
            clinicalMax: m.definition.healthyUpper ?? m.max,
            label: m.definition.symbol,
            color: m.definition.color,
          ),
        );
      }).toList(),
    );
  }
}
