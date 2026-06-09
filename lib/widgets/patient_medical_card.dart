import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/vitals.dart';
import 'package:triage/screens/patient_timeline_screen.dart';
import 'package:triage/widgets/patient_state.dart';
import 'package:triage/widgets/pulsing_chip.dart';
import 'package:triage/widgets/current_metrics.dart';
import 'package:triage/widgets/vitals_history.dart';
import '../app_theme.dart';
import '../classes/action.dart';
import '../classes/acuity.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/patient_sentiment.dart';
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

  @override
  void initState() {
    super.initState();
    patientController = PatientController(widget.patient);
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

  Future<void> showTimeLineScreen(BuildContext context, String uuid, String patientName) async {
    // Assuming this returns a List or an empty list
    final actions = PatientActionFactory.instance.getActionsForPatient(uuid);
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
                      CountdownTimer(admittedAt: patient.admitted),
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "at: 12:35 pm",
                              style: TextStyle(fontSize: 12, color: AppTheme.deepLogicViolet),
                            ),
                          ),
                          //Text(""),
                          SizedBox(width: 24.0),
                          // Graph: Expanded to fill remaining width
                          Expanded(
                            child: InkWell(
                              child: CurrentMetrics(vitals: patient.vitals, height: 108),
                              onTap: () {
                                showVitalsHistory(context: context, patientUuid: patientUuid, vitals: patient.vitals);
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
      },
    );
  }
}
