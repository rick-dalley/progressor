import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import '../classes/action.dart';
import '../classes/date_time_utilities.dart';
import '../classes/phase_state_handlers.dart';
import '../widgets/timeline_widget.dart';

class PatientTimelineScreen extends StatefulWidget {
  final List<PatientAction> actions;
  final List<Map<String, dynamic>> phaseSteps;
  final String patientName;

  const PatientTimelineScreen({
    super.key,
    required this.actions,
    this.phaseSteps = const [],
    required this.patientName,
  });

  @override
  State<PatientTimelineScreen> createState() => PatientTimelineScreenState();
}

class PatientTimelineScreenState extends State<PatientTimelineScreen> {
  // Resolves a phase_step row's (phase_id, step_id) back to the actual Event
  // it represents — step_id is that event's 1-based ordinal position within
  // its phase's event list (see DataSeeder._seedPhaseSteps /
  // DatabaseManager.startPhaseStep, the two writers of this scheme).
  Event? _eventFor(Map<String, dynamic> phaseStep) {
    final int phaseId = phaseStep['phase_id'] as int;
    final int stepId = phaseStep['step_id'] as int;
    if (phaseId < 0 || phaseId >= PhaseIdentifier.values.length) return null;
    final Phase phase = PhasesFactory.instance.getPhase(PhaseIdentifier.values[phaseId]);
    final List<Event> events = phase.events?.values.toList() ?? [];
    if (stepId < 1 || stepId > events.length) return null;
    return events[stepId - 1];
  }

  Widget _buildPhaseHistory() {
    if (widget.phaseSteps.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: widget.phaseSteps.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final Map<String, dynamic> step = widget.phaseSteps[index];
          final int phaseId = step['phase_id'] as int;
          final PhaseIdentifier phaseIdentifier = phaseId >= 0 && phaseId < PhaseIdentifier.values.length
              ? PhaseIdentifier.values[phaseId]
              : PhaseIdentifier.unknown;
          final Phase phase = PhasesFactory.instance.getPhase(phaseIdentifier);
          final Event? event = _eventFor(step);
          final bool isStarted = step['status'] == 'started';
          return ListTile(
            dense: true,
            leading: Icon(
              phaseIdentifierIcons[phaseIdentifier] ?? Symbols.local_police,
              color: isStarted ? AppTheme.deepLogicViolet : AppTheme.lightTheme.disabledColor,
            ),
            title: Text('${phase.label} — ${event?.label ?? 'Unknown step'}'),
            subtitle: Text(step['started_at']?.toString() ?? ''),
            trailing: Text(
              isStarted ? 'In progress' : 'Completed',
              style: TextStyle(
                fontSize: 12,
                color: isStarted ? AppTheme.deepLogicViolet : AppTheme.lightTheme.disabledColor,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double notchPadding = MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top : 47.0;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: MediaQuery.of(context).padding.copyWith(top: notchPadding)),
      child: Scaffold(
        backgroundColor: AppTheme.clinicalWhite,
        appBar: AppBar(
          title: Text("History of ${widget.patientName}", style: const TextStyle(fontSize: 18)),

          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close), // or Icons.arrow_back
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: AppTheme.clinicalWhite,
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildPhaseHistory(),
            Expanded(
              child: TimeLineWidget(
                actions: widget.actions,
                startTime: DTUtilities.aYearAgo(),
                endTime: DateTime.now(),
                timelineColor:Colors.black26,

              ),
            ),
          ],
        ),
      ),
    );
  }
}
