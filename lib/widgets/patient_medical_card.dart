import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/vitals.dart';
import 'package:triage/screens/patient_timeline_screen.dart';
import 'package:triage/widgets/patient_state.dart';
import 'package:triage/widgets/pulsing_chip.dart';
import 'package:triage/widgets/vertical_bar_mini.dart';
import 'package:triage/widgets/vitals_history.dart';
import '../app_theme.dart';
import '../classes/action.dart';
import '../classes/acuity.dart';
import '../classes/admittance_utils.dart';
import '../classes/database_manager.dart';
import '../classes/phase_state_handlers.dart';
import '../screens/acuity_viewer_screen.dart';
import 'countdown_timer.dart';

class PatientSentiment {
  final IconData iconData;
  final double diameter;
  final Color color;

  const PatientSentiment({required this.iconData, required this.diameter, required this.color});

  Icon getIcon() {
    return Icon(iconData, size: diameter, color: color);
  }
}

Map<SentimentScale, PatientSentiment> patientSentiments = {
  SentimentScale.calm: PatientSentiment(iconData: Symbols.sentiment_calm, color: Color(0xFF0EBA00), diameter: 32),
  SentimentScale.content: PatientSentiment(iconData: Symbols.sentiment_content, color: Colors.blue, diameter: 32),
  SentimentScale.neutral: PatientSentiment(iconData: Symbols.sentiment_neutral, color: Colors.blueGrey, diameter: 32),
  SentimentScale.dissatisfied: PatientSentiment(
    iconData: Symbols.sentiment_dissatisfied,
    color: Colors.purpleAccent,
    diameter: 32,
  ),
  SentimentScale.stressed: PatientSentiment(
    iconData: Symbols.sentiment_stressed,
    color: Colors.red.shade900,
    diameter: 32,
  ),
};

class PatientMedicalCard extends StatefulWidget {
  // Pass the initial patient snapshot down from the roster list
  final Map<String, dynamic> patient;

  const PatientMedicalCard({super.key, required this.patient});

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
        return AcuityViewer(acuity: acuity);
      },
    );
  }

  void showVitalsHistory({
    required BuildContext context,
    required String patientUuid,
    required CurrentVitalsRecord vitals,
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

  Future<void> showTimeLineScreen(BuildContext context, String uuid, String patientName) async {
    // Assuming this returns a List or an empty list
    final actions = PatientActionFactory.instance.getActionsForPatient(uuid);
debugPrint("showTimelineScreen-actions: ${actions.length}");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 1.0, // Near full screen
        child: PatientTimelineScreen(actions: actions, patientName: patientName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AcuityLevel acuityId = AcuityLevel.values[patient['acuity']];
    Acuity? acuity = AcuityFactory.instance.getAcuity(level:acuityId);
    final String lastName = (patient['first_name'] ?? 'Patient').toString();
    final String firstName = (patient['last_name'] ?? 'Unknown').toString();
    final String fullName = '$firstName $lastName';
    final String patientUuid = patient['patient_uuid'] ?? "";
    final admittedDate = AdmittanceUtils.generateRandomAdmittance();
    int randomNumber = Random().nextInt(4);
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
                  CountdownTimer(admittedAt: admittedDate),
                  SizedBox(width: 4),
                  ?patientSentiments[SentimentScale.values[randomNumber]]?.getIcon(),
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
                    iconData: AppTheme.acuityIcons[acuityId]!,
                    text: acuity != null ? "Acuity: ${acuity.statusName}" : "Acuity: pending",
                    textColor: AppTheme.lightTheme.disabledColor,
                    iconColor: AppTheme.acuityColors[acuityId],
                    backgroundColor: AppTheme.acuityBackgroundColors[acuityId],
                    onTap: () {
                      showVitalsHistory(context: context, patientUuid: patientUuid, vitals: vitals);
                    },
                    pulse: acuityId == AcuityLevel.resuscitation,
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
                    const Icon(Symbols.monitoring, size: 24, color: AppTheme.deepLogicViolet),
                    const SizedBox(width: 8),
                    const Text(
                      "Tracking",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepLogicViolet),
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
                      //Text(""),
                      SizedBox(width: 64.0),
                      // Graph: Expanded to fill remaining width
                      Expanded(
                        child: InkWell(
                          child: VitalTrendContainerSmall(vitals: vitals, height: 56),
                          onTap: () {
                            showVitalsHistory(context: context, patientUuid: patientUuid, vitals: vitals);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "as of: 26/08/2026 12:35 pm",
                    style: TextStyle(fontSize: 12, color: AppTheme.deepLogicViolet),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Symbols.news, size: 24, color: AppTheme.lightTheme.primaryColor),
                SizedBox(width: 8.0),
                Text(
                  "Patient Situation",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.lightTheme.primaryColor),
                ),
              ],
            ),
            InkWell(
              onTap: () => showTimeLineScreen(context, patientUuid, fullName),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The Macro Linear Rail — tracks active phase block seamlessly
                  PatientStateWidget(prompts: ["Previous", "Current", "Next"]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
