import 'package:flutter/material.dart';
import 'package:triage/widgets/process_tree_widget.dart';
import 'package:triage/widgets/process_widgets.dart';
import 'package:triage/widgets/pulsing_chip.dart';
import 'package:triage/widgets/vitals_display_bar.dart';
import 'package:triage/widgets/vitals_history.dart';
import '../app_theme.dart';
import '../classes/acuity.dart';
import '../classes/admittance_utils.dart';
import '../classes/database_manager.dart';
import '../classes/process_step.dart';
import 'countdown_timer.dart';

class PatientMedicalCard extends StatefulWidget {
  // Pass the initial patient snapshot down from the roster list
  final Map<String, dynamic> patient;
  final VoidCallback? onVitalsTap;
  final VoidCallback? onTimeLineTap;
  final void Function(Acuity) onAcuityTap;

  const PatientMedicalCard({
    super.key,
    required this.patient,
    this.onVitalsTap,
    this.onTimeLineTap,
    required this.onAcuityTap,
  });

  @override
  State<PatientMedicalCard> createState() => PatientMedicalCardState();
}

class PatientMedicalCardState extends State<PatientMedicalCard> {
  late Map<String, dynamic> patient;

  @override
  void initState() {
    super.initState();
    patient = widget.patient;
  }

  @override
  void didUpdateWidget(covariant PatientMedicalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patient != widget.patient) {
      patient = widget.patient;
    }
  }

  // A completely separate, clean async routine to fetch fresh row data
  Future<void> _refreshPatientData() async {
    final updatedPatient = await DatabaseManager().getPatientForUuid(patient["patient_uuid"]);
    if (mounted) {
      // Synchronous setState execution ONLY after the data is securely sitting in memory
      setState(() {
        patient["phase_step_id"] = updatedPatient["phase_step_id"];
      });
    }
  }

  void showVitalsHistory(BuildContext context, String patientUuid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.clinicalWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => VitalsHistoryView(patientUuid: patientUuid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int acuityId = patient['acuity'];
    Acuity? acuity = DatabaseManager().acuity?[acuityId];
    final String lastName = (patient['first_name'] ?? 'Patient').toString();
    final String firstName = (patient['last_name'] ?? 'Unknown').toString();
    final String patientUuid = patient['patient_uuid'] ?? "";
    final admittedDate = AdmittanceUtils.generateRandomAdmittance();
    final int thisStepId = patient['phase_step_id'] ?? 101;
    final int thisPhaseId = thisStepId ~/ 100;
    final Map<int, ProcessStep>? siblings = DatabaseManager().processBlueprint[thisPhaseId]?.children;
    final ProcessStep? thisStep = siblings?[thisStepId];
    final ProcessStep? previousStep = siblings?[thisStepId - 1];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // side: BorderSide(color: statusColor, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    "$lastName, $firstName",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.deepCharcoal),
                  ),
                  const Spacer(),
                  // Replace the old monitor_heart button with this:
                  CountdownTimer(admittedAt: admittedDate, onTap: widget.onTimeLineTap ?? () {}),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () => widget.onAcuityTap(acuity!),
                  child: PulsingChip(
                    iconData: AppTheme.acuityIcons[acuityId]!,
                    text: "Acuity: ${acuity?.statusName}",
                    color: AppTheme.acuityColors[acuityId],
                    backgroundColor: AppTheme.acuityBackgroundColors[acuityId],
                    onTap: () {
                      showVitalsHistory(context, patientUuid);
                    },
                    pulse: acuityId == 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tappable Vitals
            VitalsBar(
              onAddPressed: widget.onVitalsTap ?? () {},
              onHistoryPressed: () => showVitalsHistory(context, patientUuid),
              vitals: VitalsData(
                pulse: patient['current_pulse'],
                bp: "${patient['current_systolic']}/${patient['current_diastolic']}",
                temp: patient['current_temp'],
                spo2: patient['current_spo2'],
              ),
            ),

            const SizedBox(height: 16),

            // Assessments/Meds Row
            // Replace the Row with a Wrap for automatic overflow handling
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showProcessModal(context, patient['patient_uuid'], patient["phase_step_id"]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A. The Macro Linear Rail — tracks active phase block seamlessly
                  ProcessPhaseRail(currentPhaseId: thisPhaseId, phases: DatabaseManager().processBlueprint),

                  const SizedBox(height: 10),

                  // B. The Micro Active Steps Row — displays current sibling tasks
                  Builder(
                    builder: (context) {
                      // 1. Generate the flat registry from our typed blueprint list

                      return HorizontalStepViewer(thisStep: thisStep, previousStep: previousStep, siblings: siblings);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProcessModal(BuildContext context, String uuid, int stepId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Allows for rounded corners
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppTheme.clinicalWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildModalHandle(),
              Expanded(
                child: ProcessTreeOverlay(
                  patientUuid: uuid,
                  processStepId: stepId,
                  onProcessStepTapped: _refreshPatientData,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 4,
      width: 40,
      decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(2)),
    );
  }
}
