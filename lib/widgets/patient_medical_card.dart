import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/vitals.dart';
import 'package:triage/screens/patient_timeline_screen.dart';
import 'package:triage/screens/tracked_metrics_screen.dart';
import 'package:triage/screens/tracked_metrics_trend_screen.dart';
import 'package:triage/screens/therapy_comparison_screen.dart';
import 'package:triage/widgets/journey_stepper_widget.dart';
import 'package:triage/widgets/pulsing_chip.dart';
import 'package:triage/widgets/current_metrics.dart';
import 'package:triage/widgets/vitals_history.dart';
import '../app_theme.dart';
import '../classes/action.dart';
import '../classes/acuity.dart';
import '../classes/database_manager.dart';
import '../classes/dispositional.dart';
import '../classes/ems_handoff.dart';
import '../classes/journey_stage.dart';
import '../classes/patient.dart';
import '../classes/patient_sentiment.dart';
import '../classes/tracked_metric.dart';
import '../screens/acuity_viewer_screen.dart';
import '../screens/body_screen.dart';
import 'countdown_timer.dart';


class PatientMedicalCard extends StatefulWidget {
  // Pass the initial patient snapshot down from the roster list
  final Patient patient;
  final Function onPatientUpdate;
  final Function onVitalsUpdate;

  const PatientMedicalCard({
    super.key,
    required this.patient,
    required this.onPatientUpdate({required Patient patient}),
    required this.onVitalsUpdate({required Patient patient}),
  });

  @override
  State<PatientMedicalCard> createState() => PatientMedicalCardState();
}

class PatientMedicalCardState extends State<PatientMedicalCard> {
  late PatientController patientController;
  List<TrackedMetricSummary> _trackedMetrics = [];
  List<DispositionDecision> _decisions = [];
  Map<String, dynamic>? _admittancePoliceHandoff;
  EmsHandoff? _emsHandoff;

  @override
  void initState() {
    super.initState();
    patientController = PatientController(widget.patient);
    _loadTrackedMetrics();
    _loadDispositionDecisions();
    _loadEmsHandoff();
  }

  Future<void> _loadEmsHandoff() async {
    final row = await DatabaseManager().getEmsHandoffForPatient(patientController.patient.patientUuid);
    if (mounted) setState(() => _emsHandoff = row == null ? null : EmsHandoff.fromJson(row));
  }

  Future<void> _loadTrackedMetrics() async {
    final metrics = await TrackedMetrics.summariesForPatient(patientController.patient.patientUuid);
    if (mounted) setState(() => _trackedMetrics = metrics);
  }

  Future<void> _loadDispositionDecisions() async {
    final rows = await DatabaseManager().getDispositionDecisionsForPatient(patientController.patient.patientUuid);
    final decisions = rows.map(DispositionDecision.fromJson).toList();

    Map<String, dynamic>? handoff;
    final admittanceDecisions = decisions.where((d) => d.stageAfter == JourneyStage.admittance);
    if (admittanceDecisions.isNotEmpty) {
      handoff = await DatabaseManager().getPoliceHandoffForDecision(admittanceDecisions.first.id);
    }

    if (mounted) {
      setState(() {
        _decisions = decisions;
        _admittancePoliceHandoff = handoff;
      });
    }
  }

  @override
  void didUpdateWidget(covariant PatientMedicalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patient != widget.patient) {
      patientController = PatientController(widget.patient);
    }
  }

  // A completely separate, clean async routine to fetch fresh row data
  Future<void> refreshPatientData() async {
    final dynamic result = await DatabaseManager().getPatientWithVitals(
      patientUuid: patientController.patient.patientUuid,
    );
    final Map<String, dynamic> updatedPatient = result[0];

    if (mounted) {
      // Synchronous setState execution ONLY after the data is securely sitting in memory
      setState(() {
        patientController.patient = Patient.fromJson(updatedPatient);
      });
      widget.onPatientUpdate(patient:patientController.patient);
    }
    await _loadTrackedMetrics();
    await _loadDispositionDecisions();
  }

  void updateAcuity() {
    widget.onPatientUpdate(patient: patientController.patient);
    setState(() {});
  }

  void showAcuityModal(BuildContext context, Acuity? acuity) {
    if (acuity == null) {
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (BuildContext context) {
        return AcuityViewer(
          patientUuid: patientController.patient.patientUuid,
          acuity: acuity,
          patientController: patientController,
          onAcuityUpdated: updateAcuity,
        );
      },
    );
  }

  void showVitalsHistory({
    required BuildContext context,
    required String patientUuid,
    required CurrentVitalsRecord? vitals,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.clinicalWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) =>
          VitalsHistoryView(patientUuid: patientUuid, vitals: vitals, onAddedVitals: refreshPatientData),
    );
  }

  Future<void> showTrackedMetricsScreen(BuildContext context, String patientUuid, String patientName) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.clinicalWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => TrackedMetricsScreen(patientUuid: patientUuid, patientName: patientName),
    );
    await _loadTrackedMetrics();
  }

  Future<void> showTrackedMetricsTrendScreen(BuildContext context, String patientUuid, String patientName) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.clinicalWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => TrackedMetricsTrendScreen(patientUuid: patientUuid, patientName: patientName),
    );
    await _loadTrackedMetrics();
  }

  Future<void> showTherapyComparisonScreen(BuildContext context, String patientUuid, String patientName) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 1.0,
        child: TherapyComparisonScreen(patientUuid: patientUuid, patientName: patientName),
      ),
    );
  }

  Future<void> showTimeLineScreen(BuildContext context, String uuid, String patientName) async {
    // Assuming this returns a List or an empty list
    final actions = PatientActionFactory.instance.getActionsForPatient(uuid);
    final phaseSteps = await DatabaseManager().getPhaseStepsForPatient(uuid);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 1.0, // Near full screen
        child: PatientTimelineScreen(actions: actions, phaseSteps: phaseSteps, patientName: patientName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      key: ValueKey(patientController.patient.acuityLevel),
      listenable: patientController,
      builder: (context, _) {
        final patient = patientController.patient;
        Acuity? acuity = AcuityFactory.instance.getAcuity(level: patient.acuityLevel);
        final String fullName = '${patient.firstName} ${patient.lastName}';
        final String patientUuid = patient.patientUuid;
        Icon sentimentIcon = patientSentiments[patient.sentiment]?.getIcon() ?? Icon(Symbols.sentiment_neutral);
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            // side: BorderSide(color: statusColor, width: 3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  // 1. Apply the background color fill and styling
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor, // Swap this for whatever color matches your layout theme
                    borderRadius: BorderRadius.circular(8.0), // Keeps the container edges crisp and clean
                  ),
                  // 2. Add padding so your elements have breathing room inside the colored block
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),

                  child: Row(
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.deepCharcoal),
                      ),
                      const Spacer(),
                      // Replace the old monitor_heart button with this:
                      CountdownTimer(
                        admittedAt: patient.admitted,
                        firstDecisionOutcome: _decisions.isEmpty ? null : _decisions.first.stageAfter,
                      ),
                      SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Symbols.compare_arrows),
                        tooltip: "Compare therapies against events",
                        onPressed: () => showTherapyComparisonScreen(context, patientUuid, fullName),
                      ),
                      SizedBox(width: 4),
                      IconButton(
                        icon:sentimentIcon,
                        onPressed: (){
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true, // Allows full-screen height
                            useSafeArea: false,        // Prevents UI overlap with status/nav bars
                            builder: (BuildContext context) {
                              return SizedBox(
                                height: MediaQuery.of(context).size.height, // 90% screen height
                                child: BodyOutlineScreen(patient: patient,), // The Stateful Widget from before
                              );
                            },
                          );
                        },
                      )
                      ,
                    ],
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showAcuityModal(context, acuity);
                      },
                      child: PulsingChip(
                        iconData: AppTheme.acuityIcons[patient.acuityLevel]!,
                        text: acuity != null ? "Acuity: ${acuity.statusName}" : "Acuity: pending",
                        textColor: AppTheme.lightTheme.disabledColor,
                        iconColor: AppTheme.acuityColors[patient.acuityLevel],
                        backgroundColor: AppTheme.acuityBackgroundColors[patient.acuityLevel],
                        onTap: () {
                          showVitalsHistory(context: context, patientUuid: patientUuid, vitals: patient.vitals);
                        },
                        pulse: patient.acuityLevel == AcuityLevel.resuscitation,
                        shadowText: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  mainAxisSize: MainAxisSize.min, // Prevents Column from taking infinite height
                  children: [
                    // 1. Header
                    // Row(
                    //   children: [
                    //     const Icon(Symbols.monitoring, size: 24, color: AppTheme.deepLogicViolet),
                    //     const SizedBox(width: 8),
                    //     const Text(
                    //       "Tracking",
                    //       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepLogicViolet),
                    //     ),
                    //     Spacer(),
                    //     Icon(Icons.arrow_forward_ios, size: 20, color: AppTheme.lightTheme.disabledColor),
                    //   ],
                    // ),
                    // const SizedBox(height: 24.0),

                    // 2. Button and Graph Row
                    SizedBox(
                      height: 148, // Increased height to comfortably fit stacked icon buttons
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppTheme.deepLogicViolet),
                            tooltip: "Add a metric to track",
                            onPressed: () => showTrackedMetricsScreen(context, patientUuid, fullName),
                          ),
                          // Row itself: tap to see the trend across everything tracked.
                          Expanded(
                            child: InkWell(
                              child: CurrentMetrics(metrics: _trackedMetrics, height: 108),
                              onTap: () {
                                showTrackedMetricsTrendScreen(context, patientUuid, fullName);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 8),
                // Row(
                //   children: [
                //     Icon(Symbols.news, size: 24, color: AppTheme.lightTheme.primaryColor),
                //     SizedBox(width: 8.0),
                //     Text(
                //       "Patient Situation",
                //       style: TextStyle(
                //         fontSize: 18,
                //         fontWeight: FontWeight.bold,
                //         color: AppTheme.lightTheme.primaryColor,
                //       ),
                //     ),
                //   ],
                // ),
                Row(
                  children: [
                    Expanded(
                      child: JourneyStepperWidget(
                        patient: patient,
                        decisions: _decisions,
                        admittancePoliceHandoff: _admittancePoliceHandoff,
                        emsHandoff: _emsHandoff,
                        onDecisionRecorded: () async {
                          await _loadDispositionDecisions();
                          await refreshPatientData();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Symbols.history),
                      tooltip: "Detailed history",
                      onPressed: () => showTimeLineScreen(context, patientUuid, fullName),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
