class MetricValue {
  final double value;
  final DateTime recorded;

  // Standard constructor with named arguments
  const MetricValue({
    required this.value,
    required this.recorded,
  });

  /// Factory constructor to parse database raw maps cleanly
  factory MetricValue.fromJson(Map<String, dynamic> json) {
    // Safely parse the dynamic value column to a double
    final dynamic rawValue = json['metric_value'] ?? json['value'];
    final double parsedValue = (rawValue as num?)?.toDouble() ?? 0.0;

    // Safely handle the string-to-date conversion parsing
    final dynamic rawDate = json['recorded_at'] ?? json['recorded'];
    final DateTime parsedDate = rawDate != null
        ? DateTime.tryParse(rawDate.toString()) ?? DateTime.now()
        : DateTime.now();

    return MetricValue(
      value: parsedValue,
      recorded: parsedDate,
    );
  }

  /// Converts the model object back into a map structured for SQLite writes
  Map<String, dynamic> toJson() {
    return {
      'metric_value': value,
      'recorded_at': recorded.toIso8601String(), // Safe string format for database entries
    };
  }
}

class MedicalMath {
  static double calculateBMI({
    required double? weight,
    required String weightUom,
    required double? height,
    required String heightUom,
  }) {
    if (weight == null || height == null) return 0.0;
    if (weight <= 0 || height <= 0) return 0.0;

    double weightInKg = weight;
    double heightInMeters = height;

    // Convert weight to kg if logged in lbs
    if (weightUom.toLowerCase() == 'lbs') {
      weightInKg = weight * 0.45359237;
    }

    // Convert height to meters based on input type
    final String cleanHeightUom = heightUom.toLowerCase();
    if (cleanHeightUom == 'cm') {
      heightInMeters = height / 100.0;
    } else if (cleanHeightUom == 'in' || cleanHeightUom == 'inches') {
      heightInMeters = (height * 2.54) / 100.0;
    }

    final double bmi = weightInKg / (heightInMeters * heightInMeters);

    // Round to one decimal place (standard medical presentation)
    return double.parse(bmi.toStringAsFixed(1));
  }
}