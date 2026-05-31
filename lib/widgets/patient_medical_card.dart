import 'package:flutter/material.dart';
import 'package:triage/classes/vitals.dart';
import 'package:triage/widgets/process_tree_widget.dart';
import 'package:triage/widgets/process_widgets.dart';
import 'package:triage/widgets/pulsing_chip.dart';
import 'package:triage/widgets/vertical_bar_mini.dart';
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
  final VoidCallback onTimeLineTap;
  final void Function(Acuity) onAcuityTap;

  const PatientMedicalCard({
    super.key,
    required this.patient,
    required this.onTimeLineTap,
    required this.onAcuityTap,
  });

  @override
  State<PatientMedicalCard> createState() => PatientMedicalCardState();
}

class PatientMedicalCardState extends State<PatientMedicalCard> {
  late Map<String, dynamic> patient;
  late CurrentVitalsRecord vitals;

  @override
  void initState() {
    super.initState();
    patient = widget.patient;
    vitals = CurrentVitalsRecord.fromPatientJson(patient);
  }

  @override
  void didUpdateWidget(covariant PatientMedicalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patient != widget.patient) {
      patient = widget.patient;
      vitals = CurrentVitalsRecord.fromPatientJson(patient);
    }
  }

  // A completely separate, clean async routine to fetch fresh row data
  Future<void> refreshPatientData() async {
    final dynamic result = await DatabaseManager().getPatientWithVitals(patientUuid: patient["patient_uuid"]);
    final Map<String, dynamic> updatedPatient = result[0];

    if (mounted) {
      // Synchronous setState execution ONLY after the data is securely sitting in memory
      setState(() {
        patient = updatedPatient;
        vitals = CurrentVitalsRecord.fromPatientJson(patient);
      });
    }
  }

  void showVitalsHistory({required BuildContext context, required String patientUuid, required CurrentVitalsRecord vitals}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.clinicalWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => VitalsHistoryView(patientUuid: patientUuid, vitals: vitals, onAddedVitals: refreshPatientData,),
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
                    "$lastName, $firstName",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.deepCharcoal),
                  ),
                  const Spacer(),
                  // Replace the old monitor_heart button with this:
                  CountdownTimer(admittedAt: admittedDate, onTap: widget.onTimeLineTap),
                ],
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => widget.onAcuityTap(acuity!),
                  child: PulsingChip(
                    iconData: AppTheme.acuityIcons[acuityId]!,
                    text: "Acuity: ${acuity?.statusName}",
                    textColor: AppTheme.lightTheme.disabledColor,
                    iconColor: AppTheme.acuityColors[acuityId],
                    backgroundColor: AppTheme.acuityBackgroundColors[acuityId],
                    onTap: () {
                      showVitalsHistory(context: context, patientUuid: patientUuid, vitals: vitals);
                    },
                    pulse: acuityId == 0,
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
                Row(
                  children: [
                    const Icon(Icons.monitor_heart, size: 32, color: AppTheme.deepLogicViolet),
                    const SizedBox(width: 8),
                    const Text(
                      "Vital Signs",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.deepLogicViolet),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 20, color: AppTheme.lightTheme.disabledColor),
                  ],
                ),
                const SizedBox(height: 24.0),

                // 2. Button and Graph Row
                SizedBox(
                  height: 100, // Increased height to comfortably fit stacked icon buttons
                  child: Row(
                    children: [
                      Text("blah de blah"),
                      SizedBox(width:24.0),
                      // Graph: Expanded to fill remaining width
                      Expanded(child:
                      InkWell(
                          child: VitalTrendContainerSmall(vitals: vitals, height: 56),
                          onTap: () {
                            showVitalsHistory(context: context, patientUuid: patientUuid, vitals: vitals);
                          }
                      ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight ,
                  child:                 Text("as of: 26/08/2026 12:35 pm",
                    style: TextStyle(fontSize: 12, color: AppTheme.deepLogicViolet),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            InkWell(
              onTap: () => _showProcessModal(context, patient['patient_uuid'], patient["phase_step_id"]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The Macro Linear Rail — tracks active phase block seamlessly
                  ProcessPhaseRail(currentPhaseId: thisPhaseId, phases: DatabaseManager().processBlueprint),

                  const SizedBox(height: 10),

                  // The Micro Active Steps Row — displays current sibling tasks
                  Builder(
                    builder: (context) {
                      // Generate the flat registry from our typed blueprint list

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
                  onProcessStepTapped: refreshPatientData,
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
