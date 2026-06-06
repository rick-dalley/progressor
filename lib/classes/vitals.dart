enum MetricType { systolic, diastolic, pulse, spo2, temperature, unknown }

const Map<String, MetricType> metricTypeStrings = {
  "systolic": MetricType.systolic,
  "diastolic": MetricType.diastolic,
  "pulse": MetricType.pulse,
  "spo2": MetricType.spo2,
  "temp": MetricType.temperature,
  "unknown": MetricType.unknown,
};

const Map<MetricType, String> metricTypeLabels = {
  MetricType.systolic:"systolic",
  MetricType.diastolic:"diastolic",
  MetricType.pulse:"pulse",
  MetricType.spo2: "spo2",
  MetricType.temperature:"temp",
  MetricType.unknown:"unknown"
};

const Map<MetricType, String> metricDisplayLabels = {
  MetricType.systolic:"SYS",
  MetricType.diastolic:"DIA",
  MetricType.pulse:"PULSE",
  MetricType.spo2: "O2",
  MetricType.temperature:"TEMP",
};


class Limits {
  final double upper, lower;
  const Limits({required this.upper, required this.lower});
}

const Map<MetricType, Limits> vitalsLimits = {
  MetricType.systolic: Limits(upper: 130, lower: 110),
  MetricType.diastolic: Limits(upper: 90, lower: 60),
  MetricType.pulse: Limits(upper: 100, lower: 60),
  MetricType.spo2: Limits(upper: 100, lower: 90),
  MetricType.temperature: Limits(upper: 37.2, lower: 36.1),
};


class Metric {
  final MetricType type;
  final String label;
  final double value;
  final DateTime recorded;
  final int readingId;

  Metric({
    required this.readingId,
    required this.label,
    required this.value,
    DateTime? recorded
  }) : type = metricTypeStrings[label] ?? MetricType.unknown,
        recorded = recorded ?? DateTime.timestamp();

  factory Metric.fromJson(Map<String, dynamic> json) {
      String? rawDate = json["recorded_at"];
    return Metric(
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
  Metric? temp, o2, sys, dia, pulse;
  DateTime? recordedAt;

  VitalsRecord({required this.thisReading, required this.recordedAt});

  void addMetric(Metric metric) {
    switch (metric.type) {
      case MetricType.systolic: sys = metric;
      case MetricType.diastolic: dia = metric;
      case MetricType.pulse: pulse = metric;
      case MetricType.spo2: o2 = metric;
      case MetricType.temperature: temp = metric;
      case MetricType.unknown: break;
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
      Metric metric = Metric.fromJson(item);
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

class MetricInstance {
  final double min, max, current, upperLimit, lowerLimit;
  final MetricType vital;
  const MetricInstance({
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
  final Map<MetricType, MetricInstance> mapValues = {};

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

  CurrentVitalsRecord.fromPatientJson(Map<String, dynamic> metric){
    _add("systolic",
        (metric['min_systolic'] as num?)?.toDouble() ?? 0.0,
        (metric['max_systolic'] as num?)?.toDouble() ?? 0.0,
        (metric['current_systolic'] as num?)?.toDouble() ?? 0.0);

    _add("diastolic",
        (metric['min_diastolic'] as num?)?.toDouble() ?? 0.0,
        (metric['max_diastolic'] as num?)?.toDouble() ?? 0.0,
        (metric['current_diastolic'] as num?)?.toDouble() ?? 0.0);

    _add("pulse",
        (metric['min_pulse'] as num?)?.toDouble() ?? 0.0,
        (metric['max_pulse'] as num?)?.toDouble() ?? 0.0,
        (metric['current_pulse'] as num?)?.toDouble() ?? 0.0);

    _add("spo2",
        (metric['min_spo2'] as num?)?.toDouble() ?? 0.0,
        (metric['max_spo2'] as num?)?.toDouble() ?? 0.0,
        (metric['current_spo2'] as num?)?.toDouble() ?? 0.0);

    _add("temp",
        (metric['min_temperature'] as num?)?.toDouble() ?? 0.0,
        (metric['max_temperature'] as num?)?.toDouble() ?? 0.0,
        (metric['current_temperature'] as num?)?.toDouble() ?? 0.0);

  }

  void _add(String label, double min, double max, double current) {
    MetricType? metricType = metricTypeStrings[label.toLowerCase()];

    // Safety checks
    if (metricType == null || metricType == MetricType.unknown || min < 0 || max < 0) {
      return;
    }

    Limits? limits = vitalsLimits[metricType];
    if (limits == null) return;

    // Create and save the instance
    mapValues[metricType] = MetricInstance(
      min: min,
      max: max,
      current: current,
      upperLimit: limits.upper,
      lowerLimit: limits.lower,
      vital: metricType,
    );
  }

}
