import 'package:flutter/material.dart';

import 'database_manager.dart';

// A clinician's caseload has no fixed set of vitals — this is the generic
// "whatever's being tracked for this patient" system, separate from the
// fixed 5-vital pipeline in vitals.dart (systolic/diastolic/pulse/spo2/temp),
// which stays as-is for detailed vitals trending. Names are deliberately
// distinct from vitals.dart's Metric/MetricInstance and metric_value.dart's
// MetricValue to avoid collisions within the same package.

const List<Color> trackedMetricPalette = [
  Colors.blue,
  Colors.blueGrey,
  Colors.purple,
  Colors.green,
  Colors.brown,
  Colors.teal,
  Colors.deepOrange,
  Colors.indigo,
  Colors.pink,
];

class TrackedMetricDefinition {
  final int id;
  final String name;
  final String symbol;
  final String category;
  final String unit;
  final String? description;
  final int colorIndex;
  final double? healthyLower;
  final double? healthyUpper;

  const TrackedMetricDefinition({
    required this.id,
    required this.name,
    required this.symbol,
    required this.category,
    required this.unit,
    this.description,
    required this.colorIndex,
    this.healthyLower,
    this.healthyUpper,
  });

  Color get color => trackedMetricPalette[colorIndex % trackedMetricPalette.length];

  factory TrackedMetricDefinition.fromMap(Map<String, dynamic> row) {
    return TrackedMetricDefinition(
      id: row['id'] as int,
      name: row['name'] as String,
      symbol: row['symbol'] as String,
      category: row['category'] as String,
      unit: row['unit'] as String,
      description: row['description'] as String?,
      colorIndex: (row['color_index'] as int?) ?? 0,
      healthyLower: (row['healthy_lower_limit'] as num?)?.toDouble(),
      healthyUpper: (row['healthy_upper_limit'] as num?)?.toDouble(),
    );
  }
}

class TrackedMetricSummary {
  final TrackedMetricDefinition definition;
  final double current;
  final double min;
  final double max;
  final DateTime? lastMeasured;

  const TrackedMetricSummary({
    required this.definition,
    required this.current,
    required this.min,
    required this.max,
    this.lastMeasured,
  });
}

class TrackedMetrics {
  static Future<List<TrackedMetricDefinition>> allDefinitions() async {
    final rows = await DatabaseManager().getAllTrackedMetricDefinitions();
    return rows.map(TrackedMetricDefinition.fromMap).toList();
  }

  static Future<List<int>> trackedMetricIdsFor(String patientUuid) {
    return DatabaseManager().getTrackedMetricIdsForPatient(patientUuid);
  }

  // Joins the patient's tracked metric ids against the catalog, then folds
  // in current/min/max/last-measured per metric from one aggregate query —
  // metrics with no readings yet still show up (current/min/max at 0) so a
  // newly-tracked metric doesn't just disappear from the card.
  static Future<List<TrackedMetricSummary>> summariesForPatient(String patientUuid) async {
    final List<TrackedMetricDefinition> all = await allDefinitions();
    final List<int> trackedIds = await trackedMetricIdsFor(patientUuid);
    if (trackedIds.isEmpty) return [];

    final Map<int, TrackedMetricDefinition> byId = {for (final d in all) d.id: d};
    final Map<int, Map<String, dynamic>> ranges = await DatabaseManager().getTrackedMetricRangesForPatient(
      patientUuid,
    );

    final List<TrackedMetricSummary> summaries = [];
    for (final int id in trackedIds) {
      final TrackedMetricDefinition? definition = byId[id];
      if (definition == null) continue;
      final Map<String, dynamic>? range = ranges[id];
      final DateTime? lastMeasured = range?['last_measured'] != null
          ? DateTime.tryParse(range!['last_measured'] as String)
          : null;
      summaries.add(
        TrackedMetricSummary(
          definition: definition,
          current: (range?['current_value'] as num?)?.toDouble() ?? 0.0,
          min: (range?['min_value'] as num?)?.toDouble() ?? 0.0,
          max: (range?['max_value'] as num?)?.toDouble() ?? 0.0,
          lastMeasured: lastMeasured,
        ),
      );
    }
    return summaries;
  }

  static Future<void> track({required String patientUuid, required int metricId}) {
    return DatabaseManager().trackMetricForPatient(patientUuid: patientUuid, metricId: metricId);
  }

  static Future<void> untrack({required String patientUuid, required int metricId}) {
    return DatabaseManager().untrackMetricForPatient(patientUuid: patientUuid, metricId: metricId);
  }

  static Future<void> addReading({required String patientUuid, required int metricId, required double value}) {
    return DatabaseManager().insertTrackedMetricReading(patientUuid: patientUuid, metricId: metricId, value: value);
  }

  static Future<List<Map<String, dynamic>>> readingsFor({required String patientUuid, required int metricId}) {
    return DatabaseManager().getTrackedMetricReadings(patientUuid: patientUuid, metricId: metricId);
  }
}
