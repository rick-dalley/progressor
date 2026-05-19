enum AssessmentType {
  isBool,
  isInteger,
  isBoolWithDescription,
}

class AssessmentAnswer {
  final int numberScore;
  final bool yesNoScore;
  final String description;

  const AssessmentAnswer({
    this.numberScore = 0,
    this.yesNoScore = false,
    this.description = '',
  });

  /// Factory constructor to parse any raw incoming database string
  /// cleanly based on the structural requirements of the question type.
  factory AssessmentAnswer.parse({
    required String rawValue,
    required AssessmentType type,
  }) {
    final sanitized = rawValue.trim();
    if (sanitized.isEmpty) return const AssessmentAnswer();

    switch (type) {
      case AssessmentType.isBool:
        final isYes = sanitized.toLowerCase() == 'true' || sanitized.toLowerCase() == 'yes' || sanitized == '1';
        return AssessmentAnswer(
          yesNoScore: isYes,
          numberScore: isYes ? 1 : 0,
        );

      case AssessmentType.isInteger:
        final score = int.tryParse(sanitized) ?? 0;
        return AssessmentAnswer(
          numberScore: score,
          yesNoScore: score > 0,
        );

      case AssessmentType.isBoolWithDescription:
      // Decouple compound fields structured as "VALUE|DESCRIPTION"
      // e.g., "Yes|Patient describes a vague passive desire..."
        if (sanitized.contains('|')) {
          final parts = sanitized.split('|');
          final rawBool = parts[0].trim().toLowerCase();
          final desc = parts.sublist(1).join('|').trim(); // Safeguard embedded pipes

          final isYes = rawBool == 'true' || rawBool == 'yes' || rawBool == '1';
          return AssessmentAnswer(
            yesNoScore: isYes,
            numberScore: isYes ? 1 : 0,
            description: desc,
          );
        }

        // Fallback fallback if no delimiter exists yet
        final isYes = sanitized.toLowerCase() == 'true' || sanitized.toLowerCase() == 'yes' || sanitized == '1';
        return AssessmentAnswer(
          yesNoScore: isYes,
          numberScore: isYes ? 1 : 0,
        );
    }
  }

  /// Collapses the object back into a flat database string string value
  String toRawValue(AssessmentType type) {
    switch (type) {
      case AssessmentType.isBool:
        return yesNoScore ? 'Yes' : 'No';
      case AssessmentType.isInteger:
        return numberScore.toString();
      case AssessmentType.isBoolWithDescription:
        final boolStr = yesNoScore ? 'Yes' : 'No';
        return description.isNotEmpty ? '$boolStr|$description' : boolStr;
    }
  }

  /// Helper to allow clean immutability modifications inside UI forms
  AssessmentAnswer copyWith({
    int? numberScore,
    bool? yesNoScore,
    String? description,
  }) {
    return AssessmentAnswer(
      numberScore: numberScore ?? this.numberScore,
      yesNoScore: yesNoScore ?? this.yesNoScore,
      description: description ?? this.description,
    );
  }
}