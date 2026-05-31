import 'package:flutter/cupertino.dart';

enum VitalType { systolic, diastolic, pulse, spo2, temperature, unknown }

const Map<String, VitalType> vitalTypeStrings = {
  "systolic": VitalType.systolic,
  "diastolic": VitalType.diastolic,
  "pulse": VitalType.pulse,
  "spo2": VitalType.spo2,
  "temp": VitalType.temperature,
  "unknown": VitalType.unknown,
};

const Map<VitalType, String> vitalTypeLabels = {
  VitalType.systolic:"systolic",
  VitalType.diastolic:"diastolic",
  VitalType.pulse:"pulse",
  VitalType.spo2: "spo2",
  VitalType.temperature:"temp",
  VitalType.unknown:"unknown"
};

const Map<VitalType, String> vitalDisplayLabels = {
  VitalType.systolic:"SYS",
  VitalType.diastolic:"DIA",
  VitalType.pulse:"PULSE",
  VitalType.spo2: "O2",
  VitalType.temperature:"TEMP",
};


class Limits {
  final double upper, lower;
  const Limits({required this.upper, required this.lower});
}

const Map<VitalType, Limits> vitalsLimits = {
  VitalType.systolic: Limits(upper: 130, lower: 110),
  VitalType.diastolic: Limits(upper: 90, lower: 60),
  VitalType.pulse: Limits(upper: 100, lower: 60),
  VitalType.spo2: Limits(upper: 100, lower: 90),
  VitalType.temperature: Limits(upper: 37.2, lower: 36.1),
};


class VitalMetric {
  final VitalType type;
  final String label;
  final double value;
  final DateTime recorded;
  final int readingId;

  VitalMetric({
    required this.readingId,
    required this.label,
    required this.value,
    DateTime? recorded
  }) : type = vitalTypeStrings[label] ?? VitalType.unknown,
        recorded = recorded ?? DateTime.timestamp();

  factory VitalMetric.fromJson(Map<String, dynamic> json) {
      String? rawDate = json["recorded_at"];
    return VitalMetric(
      readingId: json["reading_id"],
      label: json["metric_type"] ?? "unknown",
      value: json["metric_value"] != null ? (json["metric_value"] as num).toDouble(): 0.0,
      recorded: DateTime.tryParse( rawDate ?? "") ?? DateTime.timestamp(),
    );
  }
}

class VitalsRecord {
  // Use nullable types to simplify completion checks
  final int thisReading;
  VitalMetric? temp, o2, sys, dia, pulse;
  DateTime? recordedAt;

  VitalsRecord({required this.thisReading, required this.recordedAt});

  void addMetric(VitalMetric metric) {
    switch (metric.type) {
      case VitalType.systolic: sys = metric;
      case VitalType.diastolic: dia = metric;
      case VitalType.pulse: pulse = metric;
      case VitalType.spo2: o2 = metric;
      case VitalType.temperature: temp = metric;
      case VitalType.unknown: break;
    }
  }

  // Simple null check
  bool get isComplete => temp != null && sys != null && dia != null && pulse != null;
}

class VitalsHistoryBuilder {
  dynamic rawJson;
  List<VitalsRecord> history = [];

  VitalsHistoryBuilder({required dynamic json}){

    int currentReading = 0;
    VitalsRecord? activeVitalsRecord;
    for (dynamic item in json){
      int thisReading = item['reading_id'];
      if (item == null){
        continue;
      }
      VitalMetric metric = VitalMetric.fromJson(item);
      if((currentReading != thisReading)){
        activeVitalsRecord = VitalsRecord(thisReading: thisReading, recordedAt: metric.recorded);
        currentReading = thisReading;
      }
      activeVitalsRecord?.addMetric(metric);
      if (activeVitalsRecord != null){
        if(activeVitalsRecord.isComplete){
          history.add(activeVitalsRecord);
          activeVitalsRecord = null;
        }
      }
    }
  }
}

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

class CurrentVitalsRecord {
  // Use a final map to ensure it's initialized correctly
  final Map<VitalType, VitalInstance> mapValues = {};

  CurrentVitalsRecord();

  CurrentVitalsRecord.fromJson(dynamic history) {
    for (dynamic item in history) {
      String vitalTypeName = (item['metric_type']?.toString() ?? "unknown").toLowerCase();
      double value = (item['metric_value'] as num?)?.toDouble() ?? 0.0;
      double min = (item['min_found'] as num?)?.toDouble() ?? 0.0;
      double max = (item['max_found'] as num?)?.toDouble() ?? 0.0;

      _add(vitalTypeName, min, max, value);
    }
  }

  // Renamed to fromJoinedRow to reflect it handles a single row with all vitals
  CurrentVitalsRecord.fromPatientJson(Map<String, dynamic> row) {
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

    _add("temp",
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
