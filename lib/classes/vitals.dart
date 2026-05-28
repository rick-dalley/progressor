import 'package:flutter/cupertino.dart';

enum VitalType { systolic, diastolic, pulse, spo2, temperature, unknown }

const Map<String, VitalType> vitalTypeStrings = {
  "systolic": VitalType.systolic,
  "diastolic": VitalType.diastolic,
  "pulse": VitalType.pulse,
  "spo2": VitalType.spo2,
  "temperature": VitalType.temperature,
};

const Map<VitalType, String> vitalTypeLabels = {
  VitalType.systolic:"systolic",
  VitalType.diastolic:"diastolic",
  VitalType.pulse:"pulse",
  VitalType.spo2: "spo2",
  VitalType.temperature:"temperature",
};
class Limits {
  final double upper, lower;

  const Limits({required this.upper, required this.lower});
}

const Map<VitalType, Limits> vitalsLimits = {
  VitalType.systolic: Limits(upper: 130, lower: 110),
  VitalType.diastolic: Limits(upper: 90, lower: 60),
  VitalType.pulse: Limits(upper: 100, lower: 60),
  VitalType.spo2: Limits(upper: 95, lower: 90),
  VitalType.temperature: Limits(upper: 37.2, lower: 36.1),
};

class VitalInstance {
  final double min, max, current, upperLimit, lowerLimit;
  final VitalType vital;

  const VitalInstance({
    required this.min,
    required this.max,
    required this.current,
    required this.upperLimit,
    required this.lowerLimit,
    required this.vital,
  });
}

class CurrentVitals {
  // Use a final map to ensure it's initialized correctly
  final Map<VitalType, VitalInstance> mapValues = {};

  CurrentVitals();

  CurrentVitals.fromJson(dynamic history) {
    for (dynamic item in history) {
      String vitalTypeName = (item['metric_type']?.toString() ?? "unknown").toLowerCase();
      double value = (item['metric_value'] as num?)?.toDouble() ?? 0.0;
      double min = (item['min_found'] as num?)?.toDouble() ?? 0.0;
      double max = (item['max_found'] as num?)?.toDouble() ?? 0.0;

      _add(vitalTypeName, min, max, value);
    }
  }

  // Renamed to fromJoinedRow to reflect it handles a single row with all vitals
  CurrentVitals.fromPatientJson(Map<String, dynamic> row) {
    // Manually map each vital type from the columns
    _add("systolic",
        (row['min_systolic'] as num?)?.toDouble() ?? 0.0,
        (row['max_systolic'] as num?)?.toDouble() ?? 0.0,
        (row['current_systolic'] as num?)?.toDouble() ?? 0.0);

    _add("diastolic",
        (row['min_diastolic'] as num?)?.toDouble() ?? 0.0,
        (row['max_diastolic'] as num?)?.toDouble() ?? 0.0,
        (row['current_diastolic'] as num?)?.toDouble() ?? 0.0);

    _add("pulse",
        (row['min_pulse'] as num?)?.toDouble() ?? 0.0,
        (row['max_pulse'] as num?)?.toDouble() ?? 0.0,
        (row['current_pulse'] as num?)?.toDouble() ?? 0.0);

    _add("spo2",
        (row['min_spo2'] as num?)?.toDouble() ?? 0.0,
        (row['max_spo2'] as num?)?.toDouble() ?? 0.0,
        (row['current_spo2'] as num?)?.toDouble() ?? 0.0);

    _add("temperature",
        (row['min_temperature'] as num?)?.toDouble() ?? 0.0,
        (row['max_temperature'] as num?)?.toDouble() ?? 0.0,
        (row['current_temperature'] as num?)?.toDouble() ?? 0.0);
  }


  void _add(String label, double min, double max, double current) {
    VitalType? vitalType = vitalTypeStrings[label.toLowerCase()];

    // Safety checks
    if (vitalType == null || vitalType == VitalType.unknown || min < 0 || max < 0) {
      debugPrint("Skipping invalid vital: $label");
      return;
    }

    Limits? limits = vitalsLimits[vitalType];
    if (limits == null) return;

    // Create and save the instance
    mapValues[vitalType] = VitalInstance(
      min: min,
      max: max,
      current: current,
      upperLimit: limits.upper,
      lowerLimit: limits.lower,
      vital: vitalType,
    );
  }
}
