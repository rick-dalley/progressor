import 'package:flutter/material.dart';
import 'package:carbon_ui/carbon_ui.dart';

import 'journey_stage.dart';

// "Actionable" — something with a timestamp and a description of what happened
// — already exists in this codebase as CarbonTimelinePointEvent (carbon_ui,
// built for the therapy-comparison timeline). Dispositional implements it
// directly instead of inventing a second, near-duplicate interface, so every
// disposition decision is automatically a timeline bubble for free.
abstract class Dispositional implements CarbonTimelinePointEvent {
  String get statusBefore;
  String get statusAfter;
  String get deciderId; // StaffMember.id — always explicitly picked, no ambient current-user concept exists in this app
}

class DispositionDecision implements Dispositional {
  final String id;
  final String patientUuid;
  @override
  final String statusBefore;
  @override
  final String statusAfter;
  @override
  final String deciderId;
  @override
  final DateTime occurred; // decided_at — "date of change"
  final String? notes;

  const DispositionDecision({
    required this.id,
    required this.patientUuid,
    required this.statusBefore,
    required this.statusAfter,
    required this.deciderId,
    required this.occurred,
    this.notes,
  });

  factory DispositionDecision.fromJson(Map<String, dynamic> row) => DispositionDecision(
    id: row['id'] as String,
    patientUuid: row['patient_uuid'] as String,
    statusBefore: row['status_before'] as String,
    statusAfter: row['status_after'] as String,
    deciderId: row['decider_id'] as String,
    occurred: DateTime.parse(row['decided_at'] as String),
    notes: row['notes'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_uuid': patientUuid,
    'status_before': statusBefore,
    'status_after': statusAfter,
    'decider_id': deciderId,
    'decided_at': occurred.toIso8601String(),
    'notes': notes,
  };

  JourneyStage get stageBefore => journeyStageFromDbValue(statusBefore);
  JourneyStage get stageAfter => journeyStageFromDbValue(statusAfter);

  @override
  String get description =>
      '${journeyStageLabels[stageBefore] ?? statusBefore} → ${journeyStageLabels[stageAfter] ?? statusAfter}';
  @override
  String get typeKey => 'disposition:$statusAfter';
  @override
  Color? get color => journeyStageColors[stageAfter];
  @override
  IconData? get icon => journeyStageIcons[stageAfter];
}
