import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import '../classes/dispositional.dart';
import '../classes/ems_handoff.dart';
import '../classes/journey_stage.dart';
import '../classes/patient.dart';
import '../classes/staff.dart';
import '../screens/disposition_decision_sheet.dart';
import '../screens/ems_handoff_report_screen.dart';
import '../screens/police_report.dart';

// Replaces the old PatientStateWidget along the bottom of the card — a real
// progress tracker instead of a static phase-label pager. Renders the walked
// path (derived straight from `decisions`, chronological) as filled circles
// connected by lines; the next possible stage(s) as empty, tappable circles;
// nothing further once the journey has reached a terminal stage.
class JourneyStepperWidget extends StatelessWidget {
  final Patient patient;
  final List<DispositionDecision> decisions;
  // The police_handoff row for the admittance decision, if this was a Section
  // 28 (involuntary) admission — its mere presence is the Section 28 marker.
  final Map<String, dynamic>? admittancePoliceHandoff;
  // A patient delivered to this facility by EMS carries a handoff record from
  // that crew — see ems_handoff.dart. Renders as a leading circle, color/icon
  // matched to the same AcuityLevel scheme Acuitage (the EMS-side app) uses,
  // ahead of the in-hospital journey.
  final EmsHandoff? emsHandoff;
  final VoidCallback onDecisionRecorded;

  const JourneyStepperWidget({
    super.key,
    required this.patient,
    required this.decisions,
    this.admittancePoliceHandoff,
    this.emsHandoff,
    required this.onDecisionRecorded,
  });

  List<JourneyStage> get _walkedPath => [JourneyStage.triage, ...decisions.map((d) => d.stageAfter)];

  Future<void> _openDecisionSheet(BuildContext context, JourneyStage proposed) async {
    final bool? recorded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.clinicalWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => DispositionDecisionSheet(
        patient: patient,
        proposedOutcome: proposed,
        options: nextPossibleStages(_walkedPath.last),
      ),
    );
    if (recorded == true) onDecisionRecorded();
  }

  Future<void> _openHistoryDetail(BuildContext context, DispositionDecision decision) async {
    final StaffMember? decider = StaffFactory.instance.getStaffMember(id: decision.deciderId);
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.clinicalWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(decision.description, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Decided by: ${decider != null ? '${decider.firstName} ${decider.lastName}' : 'Unknown staff'}'),
              const SizedBox(height: 4),
              Text('At: ${DateFormat('MMM d, y • h:mm a').format(decision.occurred)}'),
              if (decision.notes != null && decision.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(decision.notes!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openPoliceHandoff(BuildContext context, String dispositionDecisionId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            PoliceReportScreen(patientUuid: patient.patientUuid, dispositionDecisionId: dispositionDecisionId),
      ),
    );
  }

  void _openEmsHandoff(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EmsHandoffReportScreen(
          handoff: emsHandoff!,
          patientName: '${patient.firstName} ${patient.lastName}',
        ),
      ),
    );
  }

  Widget _circle({
    required IconData icon,
    required Color color,
    bool filled = true,
    bool emphasized = false,
    VoidCallback? onTap,
  }) {
    final double size = emphasized ? 40 : 34;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : Colors.transparent,
          border: Border.all(color: color, width: emphasized ? 3 : 2),
        ),
        child: Icon(icon, size: size * 0.55, color: filled ? Colors.white : color),
      ),
    );
  }

  Widget _line() => Container(width: 20, height: 2, color: AppTheme.cardBorder);

  @override
  Widget build(BuildContext context) {
    final List<JourneyStage> walked = _walkedPath;
    final JourneyStage current = walked.last;
    final bool isTerminal = terminalJourneyStages.contains(current);

    // The decision that produced walked[i] (i >= 1) is decisions[i - 1] —
    // walked[0] (triage) is the journey's starting point, not a decision.
    DispositionDecision? decisionFor(int walkedIndex) => walkedIndex == 0 ? null : decisions[walkedIndex - 1];

    return SizedBox(
      height: 64,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (emsHandoff != null) ...[
              _circle(
                icon: emsAssessmentTypeIcons[emsHandoff!.assessmentType] ?? Icons.circle_rounded,
                color: emsAssessmentTypeColors[emsHandoff!.assessmentType] ?? Colors.grey,
                onTap: () => _openEmsHandoff(context),
              ),
              _line(),
            ],
            for (int i = 0; i < walked.length; i++) ...[
              if (i > 0) _line(),
              Builder(
                builder: (context) {
                  final JourneyStage stage = walked[i];
                  final bool isAdmittanceWithHandoff = stage == JourneyStage.admittance &&
                      admittancePoliceHandoff != null;
                  final DispositionDecision? decision = decisionFor(i);
                  return _circle(
                    icon: isAdmittanceWithHandoff ? Symbols.local_police : (journeyStageIcons[stage] ?? Symbols.help),
                    color: journeyStageColors[stage] ?? Colors.grey,
                    emphasized: stage == current,
                    onTap: decision == null
                        ? null
                        : isAdmittanceWithHandoff
                            ? () => _openPoliceHandoff(context, decision.id)
                            : () => _openHistoryDetail(context, decision),
                  );
                },
              ),
            ],
            if (!isTerminal) ...[
              _line(),
              if (current == JourneyStage.treatment)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final outcome in terminalJourneyStages)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: _circle(
                          icon: journeyStageIcons[outcome]!,
                          color: journeyStageColors[outcome]!,
                          filled: false,
                          onTap: () => _openDecisionSheet(context, outcome),
                        ),
                      ),
                  ],
                )
              else
                Builder(
                  builder: (context) {
                    final JourneyStage next = journeyStageSequence[journeyStageSequence.indexOf(current) + 1];
                    return _circle(
                      icon: journeyStageIcons[next]!,
                      color: journeyStageColors[next]!,
                      filled: false,
                      onTap: () => _openDecisionSheet(context, next),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
