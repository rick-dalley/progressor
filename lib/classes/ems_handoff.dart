import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'acuity.dart';

// Mirrors Acuitage's own AssessmentType (lib/classes/triage.dart) exactly —
// same values, titles, icons, colors — so a handoff reads as unmistakably
// "the same thing" a paramedic tapped in Acuitage, not a reinvented scheme.
// Acuitage and Progressor are separate apps/databases with no shared code
// today, so this is a deliberate duplicate, not an import.
enum EmsAssessmentType {
  toxidrome,
  psychosis,
  suicide,
  missing,
  breathing,
  bleeding,
  consciousness,
  systemic,
  cardiac,
  trauma,
  abdominal,
  esi,
}

const Map<EmsAssessmentType, String> emsAssessmentTypeLabels = {
  EmsAssessmentType.toxidrome: 'Toxidrome',
  EmsAssessmentType.psychosis: 'Psychotic Break',
  EmsAssessmentType.suicide: 'Suicide Risk',
  EmsAssessmentType.missing: 'Missing',
  EmsAssessmentType.breathing: 'Airway and Breathing',
  EmsAssessmentType.bleeding: 'Circulation and Hemorrhage',
  EmsAssessmentType.consciousness: 'Consciousness',
  EmsAssessmentType.systemic: 'Systemic and Environmental',
  EmsAssessmentType.cardiac: 'Chest Pain / Cardiac',
  EmsAssessmentType.trauma: 'Trauma',
  EmsAssessmentType.abdominal: 'Abdominal Pain',
  EmsAssessmentType.esi: 'Undifferentiated Presentation',
};

const Map<EmsAssessmentType, IconData> emsAssessmentTypeIcons = {
  EmsAssessmentType.toxidrome: Symbols.mixture_med,
  EmsAssessmentType.psychosis: Symbols.psychology,
  EmsAssessmentType.suicide: Symbols.skull,
  EmsAssessmentType.missing: Symbols.flashlight_on,
  EmsAssessmentType.breathing: Symbols.pulmonology,
  EmsAssessmentType.bleeding: Symbols.hematology,
  EmsAssessmentType.consciousness: Symbols.neurology,
  EmsAssessmentType.systemic: Symbols.body_system,
  EmsAssessmentType.cardiac: Symbols.cardiology,
  EmsAssessmentType.trauma: Symbols.accessibility_new,
  EmsAssessmentType.abdominal: Symbols.gastroenterology,
  EmsAssessmentType.esi: Symbols.question_mark,
};

const Map<EmsAssessmentType, Color> emsAssessmentTypeColors = {
  EmsAssessmentType.toxidrome: Colors.teal,
  EmsAssessmentType.psychosis: Colors.orange,
  EmsAssessmentType.suicide: Colors.black,
  EmsAssessmentType.missing: Colors.deepPurple,
  EmsAssessmentType.breathing: Colors.green,
  EmsAssessmentType.bleeding: Colors.red,
  EmsAssessmentType.consciousness: Colors.blue,
  EmsAssessmentType.systemic: Colors.brown,
  EmsAssessmentType.cardiac: Colors.pink,
  EmsAssessmentType.trauma: Colors.blueGrey,
  EmsAssessmentType.abdominal: Color(0xFF64008C),
  EmsAssessmentType.esi: Colors.grey,
};

// A stand-in for a real Acuitage → Progressor handoff — Acuitage (pre-hospital)
// and Progressor (in-hospital) are separate apps with separate databases today,
// no real sync pipe exists between them. This models what that pipe would carry
// if it existed: the EMS crew's on-scene acuity call, presenting-complaint
// category, and incident summary.
class EmsHandoff {
  final String id;
  final String patientUuid;
  final String? incidentName;
  final String? dispatchCode;
  final String? crew;
  final AcuityLevel onSceneAcuity;
  final EmsAssessmentType assessmentType;
  final String? destinationFacility;
  final String? narrative;
  final DateTime deliveredAt;

  const EmsHandoff({
    required this.id,
    required this.patientUuid,
    this.incidentName,
    this.dispatchCode,
    this.crew,
    required this.onSceneAcuity,
    required this.assessmentType,
    this.destinationFacility,
    this.narrative,
    required this.deliveredAt,
  });

  factory EmsHandoff.fromJson(Map<String, dynamic> row) => EmsHandoff(
    id: row['id'] as String,
    patientUuid: row['patient_uuid'] as String,
    incidentName: row['incident_name'] as String?,
    dispatchCode: row['dispatch_code'] as String?,
    crew: row['crew'] as String?,
    onSceneAcuity: AcuityLevel.values[(row['on_scene_acuity'] as int?) ?? AcuityLevel.notUrgent.index],
    assessmentType: EmsAssessmentType.values[(row['assessment_type_index'] as int?) ?? EmsAssessmentType.esi.index],
    destinationFacility: row['destination_facility'] as String?,
    narrative: row['narrative'] as String?,
    deliveredAt: DateTime.parse(row['delivered_at'] as String),
  );
}
