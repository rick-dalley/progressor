
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
  final int? id; // Nullable if not yet inserted into SQLite
  final String patientUuid;
  final int conditionId;
  String name;
  String treatmentNotes;
  int isActive; // 1 = Active, 0 = Historical
  DateTime? onset;
  DateTime? recovery;
  DateTime recordedAt;

  PatientCondition({
    this.id,
    required this.patientUuid,
    required this.conditionId,
    required this.name,
    required this.isActive,
    this.treatmentNotes = "",
    this.onset,
    this.recovery,
  }) : recordedAt =  DateTime.now();

  factory PatientCondition.fromCondition(String patientUuid, ConditionReference condition){
    return PatientCondition(
        patientUuid: patientUuid,
        conditionId: condition.id,
        name: condition.name,
        isActive:1,
        onset:DateTime.now());
  }

  // Convert an engine database row straight into your clean object layout
  factory PatientCondition.fromMap(Map<String, dynamic> map) {
    return PatientCondition(
      id: map['id'] as int,
      patientUuid: map['patient_uuid'] as String,
      conditionId: map['condition_id'] as int,
      name: map['name'] as String? ?? "",
      treatmentNotes: map['treatment_notes'] as String? ?? "",
      isActive: map['is_active'] as int? ?? 1,
      onset: map['onset'] != null ? DateTime.parse(map['onset'].toString()) : null,
      recovery: map['recovery'] != null ? DateTime.parse(map['recovery'].toString()) : null,
    );
  }

  // Format properties into a structured map row payload for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_uuid': patientUuid,
      'condition_id': conditionId,
      'treatment_notes': treatmentNotes,
      'is_active': isActive,
      'onset': onset?.toIso8601String(),
      'recovery': recovery?.toIso8601String(),
    };
  }
}