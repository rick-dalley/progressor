import 'package:flutter/material.dart';
import 'package:triage/screens/police_report.dart';
import 'package:triage/screens/timeline_screen.dart';
import 'package:triage/widgets/acuity_viewer.dart';
import 'package:triage/widgets/card_flipper.dart';
import 'package:triage/widgets/patient_information_card.dart';
import '../app_theme.dart';
import '../classes/acuity.dart';
import '../classes/database_manager.dart';
import '../widgets/interview_transcriber.dart';
import '../widgets/patient_medical_card.dart';
import 'assessments.dart';
import 'intake.dart';
import 'meds.dart';

class PatientRoster extends StatefulWidget {
  const PatientRoster({super.key});

  @override
  State<PatientRoster> createState() => PatientRosterState();
}

class PatientRosterState extends State<PatientRoster> {
  List<dynamic> _patients = [];
  final idFront = 'assets/screen_captures/license_front.png';
  final idBack = 'assets/screen_captures/license_back.png';

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    // DatabaseManager is a singleton, so this is safe and fast
    final data = await DatabaseManager().getAllPatientsWithVitals();

    setState(() {
      _patients = data.map((p) => Map<String, dynamic>.from(p)).toList();
    });
  }

  void _showAssessmentsMenu(BuildContext context, String patientUuid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssessmentsScreen(patientUuid: patientUuid),
    );
  }

  void _launchIntakeScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntakeScreen(frontOfId: idFront, backOfId: idBack),
        // This ensures the screen slides up like a focused task
        fullscreenDialog: true,
      ),
    );
  }

  void _launchTimelineModal(BuildContext context, Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Essential for large/tall content
      backgroundColor: Colors.transparent, // Allows for rounded top corners
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        // Opens almost full screen
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                // The "Drag Handle" - Essential for UX
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),

                // The Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "TIMELINE: ${patient['first_name']} ${patient['last_name'].toString().toUpperCase()}",
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                ),

                // The actual Timeline Content
                Expanded(child: PatientTimelineScreen(patient: patient)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _launchInterviewModal(BuildContext context, int index) async {
    // 1. Trigger the modal
    final bool? didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      // Allows the 85% height
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => InterviewModal(patient: _patients[index]),
    );

    // 2. If the user hit "Finalize & Summarize", update the roster
    if (didSave == true) {
      setState(() {
        // Create our writable copy
        Map<String, dynamic> updatedPatient = Map<String, dynamic>.from(_patients[index]);

        // Increment the assessment count
        int currentCount = updatedPatient['assessments'] ?? 0;
        updatedPatient['assessments'] = currentCount + 1;

        // Update the master list
        _patients[index] = updatedPatient;
      });
    }
  }

  void _launchAcuityModal(BuildContext context, Acuity acuity) {
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

  @override
  Widget build(BuildContext context) {
    // We remove the AppBar here because it's now handled by LuminescaHome in main.dart

    return Scaffold(
      // Keeping the body as the main focus
      body: _patients.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.deepLogicViolet, // Navy indicator for a "smart" feel
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              // Added top padding for breathing room
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> patient = Map<String, dynamic>.from(_patients[index]);
                return FlippableCardController(
                  height: 408,
                  front: PatientMedicalCard(
                    patient: patient,
                    onAcuityTap: (acuity) => _launchAcuityModal(context, acuity),
                    onTimeLineTap: () => _launchTimelineModal(context, _patients[index]),
                  ),
                  back: PatientInformationCard(
                    patient: patient,
                    onInterviewTap: () => _launchInterviewModal(context, index),
                    onAssessmentsTap: () => _showAssessmentsMenu(context, _patients[index]["patient_uuid"]),
                    onMedsTap: () async {
                      final Map<String, dynamic>? result = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        showDragHandle: true,
                        builder: (context) => MedicationScreen(patient: _patients[index]),
                      );

                      if (result != null) {
                        setState(() {
                          // Create the writable copy to avoid read-only errors
                          Map<String, dynamic> updatedPatient = {..._patients[index]};

                          // Map the returned values to our flat patient structure
                          updatedPatient['medications'] = result['medications'];
                          updatedPatient['medication_safety_audit'] = result['medication_safety_audit'];

                          _patients[index] = updatedPatient;
                        });
                      }
                    },
                    onPoliceTap: () async {
                      // 1. Navigate and WAIT for the signal from the Save button
                      final int? reportCount = await Navigator.push<int>(
                        context,
                        MaterialPageRoute(builder: (context) => const PoliceReportScreen()),
                      );

                      // 2. If the user hit "Save" (which returns true)
                      // Use a standard null check instead of the ! operator
                      if (reportCount != null && reportCount > 0) {
                        setState(() {
                          patient['police_reports'] = reportCount;
                          _patients[index] = patient;
                        });
                      }
                    },
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _launchIntakeScreen(context),
        // New dedicated screen
        label: const Text("INTAKE", style: TextStyle(letterSpacing: 1.0, fontWeight: FontWeight.w600)),
        icon: const Icon(Icons.qr_code_scanner),
        // Signals scanning capability
        backgroundColor: AppTheme.deepLogicViolet,
        foregroundColor: AppTheme.clinicalWhite,
      ),
    );
  }
}
