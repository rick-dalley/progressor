import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../app_theme.dart';

// The coarse, branch-aware overarching journey every patient walks — triage,
// then admittance, ward assignment, treatment, ending at one of three terminal
// outcomes reachable from ANY point along the way. Deliberately separate from
// PhaseIdentifier (phase_state_handlers.dart), which tracks a much finer-grained,
// strictly linear clinical-workflow checklist (58 events across 6 phases) — the
// two model different things and aren't meant to merge.
enum JourneyStage { triage, admittance, wardAssignment, treatment, released, transferred, deceased }

const Set<JourneyStage> terminalJourneyStages = {
  JourneyStage.released,
  JourneyStage.transferred,
  JourneyStage.deceased,
};

// The fixed linear in-hospital sequence — terminal stages are branches
// reachable from any point, not positioned in this list.
const List<JourneyStage> journeyStageSequence = [
  JourneyStage.triage,
  JourneyStage.admittance,
  JourneyStage.wardAssignment,
  JourneyStage.treatment,
];

const Map<JourneyStage, String> journeyStageLabels = {
  JourneyStage.triage: 'Triage',
  JourneyStage.admittance: 'Admitted',
  JourneyStage.wardAssignment: 'Ward Assignment',
  JourneyStage.treatment: 'Treatment',
  JourneyStage.released: 'Released',
  JourneyStage.transferred: 'Transferred',
  JourneyStage.deceased: 'Deceased',
};

// The one place these icons are defined — reused by the journey stepper, by
// CountdownTimer's post-decision swap, and by DispositionDecision.icon.
const Map<JourneyStage, IconData> journeyStageIcons = {
  JourneyStage.triage: Symbols.diagnosis,
  JourneyStage.admittance: Symbols.local_hospital,
  JourneyStage.wardAssignment: Symbols.bed,
  JourneyStage.treatment: Symbols.stethoscope,
  JourneyStage.released: Symbols.home,
  JourneyStage.transferred: Symbols.ambulance,
  JourneyStage.deceased: Symbols.skull,
};

const Map<JourneyStage, Color> journeyStageColors = {
  JourneyStage.triage: Colors.blueGrey,
  JourneyStage.admittance: Colors.teal,
  JourneyStage.wardAssignment: Colors.indigo,
  JourneyStage.treatment: AppTheme.deepLogicViolet,
  JourneyStage.released: Colors.green,
  JourneyStage.transferred: Colors.orange,
  JourneyStage.deceased: Colors.black87,
};

JourneyStage journeyStageFromDbValue(String value) =>
    JourneyStage.values.firstWhere((s) => s.name == value, orElse: () => JourneyStage.triage);

// Valid next stage(s) from a given stage — the linear next stage (if any) plus
// every terminal outcome, since any point along the way can end in
// death/release/transfer. Empty once already terminal — the journey has ended.
List<JourneyStage> nextPossibleStages(JourneyStage current) {
  if (terminalJourneyStages.contains(current)) return const [];
  final int idx = journeyStageSequence.indexOf(current);
  final List<JourneyStage> options = [];
  if (idx != -1 && idx < journeyStageSequence.length - 1) {
    options.add(journeyStageSequence[idx + 1]);
  }
  options.addAll(terminalJourneyStages);
  return options;
}
