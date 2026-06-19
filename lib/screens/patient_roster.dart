import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/screens/police_report.dart';
import 'package:triage/widgets/card_flipper.dart';
import 'package:triage/widgets/patient_information_card.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../widgets/interview_transcriber.dart';
import '../widgets/patient_medical_card.dart';
import 'questionnaires.dart';
import 'encounter_screen.dart';
import 'meds.dart';

class PatientRoster extends StatefulWidget {
  const PatientRoster({super.key});

  @override
  State<PatientRoster> createState() => PatientRosterState();
}

class PatientRosterState extends State<PatientRoster> {
  List<dynamic> _patients = [];
  String _searchQuery = "";
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadPatientData();
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
  }

  Future<void> _loadPatientData() async {
    // DatabaseManager is a singleton, so this is safe and fast
    final data = await DatabaseManager().getAllPatientsWithVitals();

    setState(() {
      _patients = data.map((p) => Patient.fromJson(p)).toList();
    });
  }

  void updatePatient({required int index, required Patient patient}) {
    setState(() {
      _patients[index] = patient;
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

  void _launchEncounterScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncidentTriageScreen(),
        // This ensures the screen slides up like a focused task
        fullscreenDialog: true,
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
        Patient updatedPatient = _patients[index];

        // Increment the assessment count
        int currentCount = updatedPatient.assessments;
        updatedPatient.assessments = currentCount + 1;

        // Update the master list
        _patients[index] = updatedPatient;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // We remove the AppBar here because it's now handled by LuminescaHome in main.dart
    final filteredPatients = _patients.where((p) {
      final name = "${p.firstName} ${p.lastName}".toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      // Keeping the body as the main focus
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search by name...",
                      prefixIcon: const Icon(Icons.search),
                      // Add this to your decoration
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = ""; // Reset the query
                                  _searchController.clear();
                                });
                              },
                            )
                          : null, // No icon if the field is empty
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredPatients.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.deepLogicViolet, // Navy indicator for a "smart" feel
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    // Added top padding for breathing room
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      return FlippableCardController(
                        height: 352,
                        front: PatientMedicalCard(
                          patient: filteredPatients[index],
                          onPatientUpdate: ({required Patient patient}) {
                            updatePatient(index: index, patient: patient);
                          },
                          onVitalsUpdate: ({required Patient patient}) {
                            updatePatient(index: index, patient: patient);
                          },
                        ),
                        back: PatientInformationCard(
                          patient: filteredPatients[index],
                          onInterviewTap: () => _launchInterviewModal(context, index),
                          onAssessmentsTap: () => _showAssessmentsMenu(context, filteredPatients[index].patientUuid),
                          onMedsTap: () async {
                            final Map<String, dynamic>? result = await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              showDragHandle: true,
                              builder: (context) => MedicationScreen(patient: filteredPatients[index]),
                            );

                            if (result != null) {
                              setState(() {
                                // Create the writable copy to avoid read-only errors
                                Patient updatedPatient = filteredPatients[index];
                                // Map the returned values to our flat patient structure
                                updatedPatient.medications = result['medications'];
                                updatedPatient.medicationSafetyAudit = result['medication_safety_audit'];
                                filteredPatients[index] = updatedPatient;
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
                                filteredPatients[index].policeReports = reportCount;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _launchEncounterScreen(context),
        // New dedicated screen
        label: const Text("+", style: TextStyle(letterSpacing: 1.0, fontWeight: FontWeight.w600)),
        icon: const Icon(Symbols.frame_person),
        // Signals scanning capability
        backgroundColor: AppTheme.deepLogicViolet,
        foregroundColor: AppTheme.clinicalWhite,
      ),
    );
  }
}
