import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/carbon_ui.dart';

import '../app_theme.dart';
import 'action.dart';
import 'care_order.dart';
import 'database_manager.dart';
import 'dispositional.dart';
import 'phase_state_handlers.dart';
import 'tracked_metric.dart';

// Adapts Progressor's own data (clinical actions, tracked-metric readings,
// phase_step rows) into the shared CarbonTimelineScroller's rendering
// contracts — the app-specific "owns the data" half of the split, mirroring
// Ally's own timeline_scroller_page.dart.

const Map<ActionType, IconData> actionTypeIcons = {
  ActionType.administerMedicine: Symbols.medication,
  ActionType.performTest: Symbols.lab_panel,
  ActionType.answerQuestionnaire: Symbols.quiz,
  ActionType.observeBehaviour: Symbols.visibility,
  ActionType.performEventStep: Symbols.timeline,
  ActionType.interviewPatient: Symbols.record_voice_over,
  ActionType.changePrescription: Symbols.edit_note,
};

class PatientActionPoint implements CarbonTimelinePointEvent {
  final PatientAction action;
  const PatientActionPoint(this.action);

  @override
  DateTime get occurred => action.getFormattedOccurred();
  @override
  String get description => action.notes.isNotEmpty ? '${action.getName()} — ${action.notes}' : action.getName();
  @override
  String get typeKey => 'action:${action.type.name}';
  @override
  Color? get color => AppTheme.deepLogicViolet; // one consistent identity for clinical actions
  @override
  IconData? get icon => actionTypeIcons[action.type];
}

class TrackedMetricReadingPoint implements CarbonTimelinePointEvent {
  final TrackedMetricDefinition definition;
  final Map<String, dynamic> reading; // {id, value, measured, ...}
  const TrackedMetricReadingPoint({required this.definition, required this.reading});

  @override
  DateTime get occurred => DateTime.parse(reading['measured'] as String);
  @override
  String get description => '${definition.name}: ${reading['value']} ${definition.unit}';
  @override
  String get typeKey => 'metric:${definition.id}';
  @override
  Color? get color => definition.color;
  @override
  IconData? get icon => null; // catalog has no per-metric icon today
}

class PhaseStepSpan implements CarbonTimelineSpan {
  final Map<String, dynamic> row;
  final Phase phase;
  final Event event;
  const PhaseStepSpan({required this.row, required this.phase, required this.event});

  @override
  String get sourceId => row['id'].toString();
  @override
  String get label => phase.label;
  @override
  DateTime get startDate => DateTime.parse(row['started_at'] as String);
  @override
  DateTime get endDate =>
      row['completed_at'] != null ? DateTime.parse(row['completed_at'] as String) : DateTime.now();
  @override
  bool get isOngoing => row['completed_at'] == null;
  @override
  String get categoryLabel => phase.label;
  @override
  IconData? get icon => phaseIdentifierIcons[phase.id];
}

const Map<String, String> _therapySpanCategoryLabels = {'medication': 'Medications', 'physical_therapy': 'Physical Therapy'};
const Map<String, IconData> _therapySpanCategoryIcons = {'medication': Symbols.medication, 'physical_therapy': Symbols.exercise};

// A medication or physical-therapy episode logged against the patient's stay
// — see DataSeeder._seedTherapySpans / therapy_span table.
class TherapySpan implements CarbonTimelineSpan {
  final Map<String, dynamic> row;
  const TherapySpan(this.row);

  @override
  String get sourceId => row['id'] as String;
  @override
  String get label => row['label'] as String;
  @override
  DateTime get startDate => DateTime.parse(row['started_at'] as String);
  @override
  DateTime get endDate => row['ended_at'] != null ? DateTime.parse(row['ended_at'] as String) : DateTime.now();
  @override
  bool get isOngoing => row['ended_at'] == null;
  @override
  String get categoryLabel => _therapySpanCategoryLabels[row['category']] ?? row['category'] as String;
  @override
  IconData? get icon => _therapySpanCategoryIcons[row['category']];
}

class TherapyComparisonData {
  final List<CarbonTimelineSpan> spans;
  final List<CarbonTimelinePointEvent> points;
  final DateTime startTime;
  final DateTime endTime;
  const TherapyComparisonData({
    required this.spans,
    required this.points,
    required this.startTime,
    required this.endTime,
  });
}

// Resolves a phase_step row's (phase_id, step_id) back to its Event — the same scheme
// PatientTimelineScreen._eventFor already uses (step_id is 1-based ordinal position
// within the phase's event list). Duplicated rather than shared for now to avoid
// touching that working screen in this pass.
Event? _eventForPhaseStep(Map<String, dynamic> row) {
  final int phaseId = row['phase_id'] as int;
  final int stepId = row['step_id'] as int;
  if (phaseId < 0 || phaseId >= PhaseIdentifier.values.length) return null;
  final Phase phase = PhasesFactory.instance.getPhase(PhaseIdentifier.values[phaseId]);
  final List<Event> events = phase.events?.values.toList() ?? [];
  if (stepId < 1 || stepId > events.length) return null;
  return events[stepId - 1];
}

Future<TherapyComparisonData> loadTherapyComparisonData(String patientUuid) async {
  // Points: clinical actions + every tracked metric's readings, merged.
  final List<CarbonTimelinePointEvent> points = [
    ...PatientActionFactory.instance.getActionsForPatient(patientUuid).map(PatientActionPoint.new),
  ];
  final List<TrackedMetricSummary> summaries = await TrackedMetrics.summariesForPatient(patientUuid);
  for (final summary in summaries) {
    final readings = await TrackedMetrics.readingsFor(patientUuid: patientUuid, metricId: summary.definition.id);
    points.addAll(readings.map((r) => TrackedMetricReadingPoint(definition: summary.definition, reading: r)));
  }
  final List<Map<String, dynamic>> dispositionRows = await DatabaseManager().getDispositionDecisionsForPatient(
    patientUuid,
  );
  points.addAll(dispositionRows.map(DispositionDecision.fromJson));
  points.sort((a, b) => a.occurred.compareTo(b.occurred));

  // Spans: phase_step rows, resolved to labels, most-recent-first so the default
  // 3-lane selection favors the patient's current/recent phases.
  final List<CarbonTimelineSpan> spans = [];
  final List<Map<String, dynamic>> phaseSteps = await DatabaseManager().getPhaseStepsForPatient(patientUuid);
  for (final row in phaseSteps) {
    final int phaseId = row['phase_id'] as int;
    if (phaseId < 0 || phaseId >= PhaseIdentifier.values.length) continue;
    final Phase phase = PhasesFactory.instance.getPhase(PhaseIdentifier.values[phaseId]);
    final Event? event = _eventForPhaseStep(row);
    if (event == null) continue;
    spans.add(PhaseStepSpan(row: row, phase: phase, event: event));
  }
  final List<Map<String, dynamic>> therapySpanRows = await DatabaseManager().getTherapySpansForPatient(patientUuid);
  spans.addAll(therapySpanRows.map(TherapySpan.new));
  final List<Map<String, dynamic>> careOrderRows = await DatabaseManager().getCareOrdersForPatient(patientUuid);
  spans.addAll(careOrderRows.map(Therapy.fromJson));
  spans.sort((a, b) => b.startDate.compareTo(a.startDate));

  final DateTime now = DateTime.now();
  final List<DateTime> allStarts = [...spans.map((s) => s.startDate), ...points.map((p) => p.occurred)];
  final DateTime startTime = allStarts.isEmpty
      ? now.subtract(const Duration(days: 30))
      : allStarts.reduce((a, b) => a.isBefore(b) ? a : b);

  return TherapyComparisonData(spans: spans, points: points, startTime: startTime, endTime: now);
}
