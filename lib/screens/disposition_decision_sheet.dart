import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/journey_stage.dart';
import '../classes/patient.dart';
import '../classes/staff.dart';
import 'police_report.dart';

// Records a single journey-stage transition: outcome, decider (always
// explicitly picked — no ambient current-user concept exists anywhere in this
// app), and timestamp. Reused for every transition, not just the first —
// same mechanism the 48h legal disposition decision and a later discharge
// both go through.
class DispositionDecisionSheet extends StatefulWidget {
  final Patient patient;
  final JourneyStage proposedOutcome;
  final List<JourneyStage> options;

  const DispositionDecisionSheet({
    super.key,
    required this.patient,
    required this.proposedOutcome,
    required this.options,
  });

  @override
  State<DispositionDecisionSheet> createState() => _DispositionDecisionSheetState();
}

class _DispositionDecisionSheetState extends State<DispositionDecisionSheet> {
  late JourneyStage _selectedOutcome;
  String? _selectedStaffId;
  DateTime _decidedAt = DateTime.now();
  bool _section28 = false;
  bool _archive = false;
  bool _saving = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedOutcome = widget.proposedOutcome;
    _archive = terminalJourneyStages.contains(_selectedOutcome);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _decidedAt,
      firstDate: widget.patient.admitted,
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_decidedAt));
    if (time == null) return;
    setState(() {
      _decidedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _confirm() async {
    if (_selectedStaffId == null) return;
    setState(() => _saving = true);

    await DatabaseManager().insertDispositionDecision(
      patientUuid: widget.patient.patientUuid,
      statusBefore: widget.patient.journeyStage.name,
      statusAfter: _selectedOutcome.name,
      deciderId: _selectedStaffId!,
      decidedAt: _decidedAt,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (_archive) {
      await DatabaseManager().archivePatient(patientUuid: widget.patient.patientUuid);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);

    if (_section28 && _selectedOutcome == JourneyStage.admittance) {
      // Fetch the just-recorded decision's id so the handoff links to it —
      // it's the most recent one for this patient/outcome pair.
      final rows = await DatabaseManager().getDispositionDecisionsForPatient(widget.patient.patientUuid);
      final String? decisionId = rows.isEmpty ? null : rows.last['id'] as String?;
      if (decisionId != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                PoliceReportScreen(patientUuid: widget.patient.patientUuid, dispositionDecisionId: decisionId),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTerminalChoice = terminalJourneyStages.contains(_selectedOutcome);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Record Decision", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<JourneyStage>(
                  initialValue: _selectedOutcome,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: "Outcome"),
                  items: widget.options
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(journeyStageLabels[s] ?? s.name, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedOutcome = val;
                      _archive = terminalJourneyStages.contains(val);
                      if (val != JourneyStage.admittance) _section28 = false;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStaffId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: "Decider"),
                  items: StaffFactory.instance.allStaff.values
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              '${s.firstName} ${s.lastName} — ${s.position}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedStaffId = val),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Time"),
                  subtitle: Text(DateFormat('MMM d, y • h:mm a').format(_decidedAt)),
                  trailing: const Icon(Icons.edit),
                  onTap: _pickDateTime,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Notes (optional)"),
                ),
                if (_selectedOutcome == JourneyStage.admittance)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _section28,
                    onChanged: (val) => setState(() => _section28 = val ?? false),
                    title: const Text("Section 28 (involuntary)"),
                  ),
                if (isTerminalChoice)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _archive,
                    onChanged: (val) => setState(() => _archive = val ?? false),
                    title: const Text("Archive this patient from the active roster"),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_saving || _selectedStaffId == null) ? null : _confirm,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepLogicViolet),
                    child: const Text("Confirm", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
