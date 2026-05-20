class ConditionReference {
  final int id;
  final String name;
  final String category;

  const ConditionReference({
    required this.id,
    required this.name,
    required this.category,
  });

  // Map a database row map directly into our object model
  factory ConditionReference.fromMap(Map<String, dynamic> map) {
    return ConditionReference(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
    );
  }
}

class PatientCondition {
  final int? patientConditionId; // Nullable if not yet inserted into SQLite
  final String patientUuid;
  final int conditionId;
  String treatmentNotes;
  int isActive; // 1 = Active, 0 = Historical
  DateTime onset;
  DateTime? recovery;
  final DateTime? recordedAt;

  PatientCondition({
    this.patientConditionId,
    required this.patientUuid,
    required this.conditionId,
    this.treatmentNotes = "",
    this.isActive = 1,
    DateTime? onset,
    this.recovery,
    this.recordedAt,
  }) : onset = onset ?? DateTime.now();

  // Convert an engine database row straight into your clean object layout
  factory PatientCondition.fromMap(Map<String, dynamic> map) {
    return PatientCondition(
      patientConditionId: map['patient_condition_id'] as int?,
      patientUuid: map['patient_uuid'] as String,
      conditionId: map['condition_id'] as int,
      treatmentNotes: map['treatment_notes'] as String? ?? "",
      isActive: map['is_active'] as int? ?? 1,
      onset: DateTime.parse(map['onset'] as String),
      recovery: map['recovery'] != null ? DateTime.parse(map['recovery'] as String) : null,
      recordedAt: map['recorded_at'] != null ? DateTime.parse(map['recorded_at'] as String) : null,
    );
  }

  // Format properties into a structured map row payload for database operations
  Map<String, dynamic> toMap() {
    return {
      if (patientConditionId != null) 'patient_condition_id': patientConditionId,
      'patient_uuid': patientUuid,
      'condition_id': conditionId,
      'treatment_notes': treatmentNotes,
      'is_active': isActive,
      'onset': onset.toIso8601String(),
      'recovery': recovery?.toIso8601String(),
    };
  }
}