import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/widgets/patient_information_card.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/phase_state_handlers.dart';
import '../widgets/interview_transcriber.dart';
import '../widgets/patient_medical_card.dart';
import 'care_orders_screen.dart';
import 'discharge_report_screen.dart';
import 'questionnaires.dart';
import 'send_questionnaire_screen.dart';
import 'intake.dart';
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

  // Looks the patient up by uuid rather than a list position — positions no
  // longer correspond to _patients once the roster is grouped with section
  // headers interleaved (see _buildGroupedItems).
  void updatePatient({required Patient patient}) {
    setState(() {
      final int idx = _patients.indexWhere((p) => p.patientUuid == patient.patientUuid);
      if (idx != -1) _patients[idx] = patient;
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

  // TODO(next-milestone): replace with a real admission form. IntakeScreen is
  // presently just a 4-field ID-scan capture, kept reachable here as a
  // stopgap now that the old "New Intervention" EMS screen is cut.
  void _launchIntakeScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IntakeScreen(),
        // This ensures the screen slides up like a focused task
        fullscreenDialog: true,
      ),
    );
  }

  void _launchInterviewModal(BuildContext context, Patient patient) async {
    // 1. Trigger the modal
    final bool? didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      // Allows the 85% height
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => InterviewModal(patient: patient),
    );

    // 2. If the user hit "Finalize & Summarize", update the roster. `patient`
    // is the same object referenced by _patients, so mutating it in place
    // (inside setState, to trigger a rebuild) is enough — no list surgery.
    if (didSave == true) {
      setState(() {
        patient.assessments = patient.assessments + 1;
      });
    }
  }

  // Groups patients by their real current phase (blueprint order), sorted
  // within each group by admission time (longest-waiting first). Returns a
  // flat list mixing PhaseIdentifier header sentinels and Patient items, for
  // a single ListView.builder — matches the rest of the app's list patterns
  // rather than introducing slivers for the first time.
  List<Object> _buildGroupedItems(List<Patient> patients) {
    final Map<PhaseIdentifier, List<Patient>> grouped = {};
    for (final Patient patient in patients) {
      grouped.putIfAbsent(patient.currentPhase, () => []).add(patient);
    }

    final List<Object> items = [];
    // Iterate the enum directly (always fully defined) rather than
    // PhasesFactory.instance.allPhases, which may still be loading — see
    // main.dart's _initializeApp race with this screen's own patient load.
    for (final PhaseIdentifier phase in PhaseIdentifier.values) {
      final List<Patient>? group = grouped[phase];
      if (group == null || group.isEmpty) continue;
      group.sort((a, b) => a.admitted.compareTo(b.admitted));
      items.add(phase);
      items.addAll(group);
    }
    return items;
  }

  String _phaseLabel(PhaseIdentifier phase) {
    final String label = PhasesFactory.instance.getPhase(phase).label;
    return label.isNotEmpty ? label : phase.name;
  }

  Widget _buildPhaseHeader(PhaseIdentifier phase, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(phaseIdentifierIcons[phase] ?? Symbols.local_police, size: 18, color: AppTheme.deepLogicViolet),
          const SizedBox(width: 8),
          Text(
            '${_phaseLabel(phase).toUpperCase()} ($count)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepLogicViolet,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We remove the AppBar here because it's now handled by LuminescaHome in main.dart
    final List<Patient> filteredPatients = _patients.cast<Patient>().where((p) {
      final name = "${p.firstName} ${p.lastName}".toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
    final List<Object> groupedItems = _buildGroupedItems(filteredPatients);

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
                    itemCount: groupedItems.length,
                    itemBuilder: (context, index) {
                      final Object item = groupedItems[index];
                      if (item is PhaseIdentifier) {
                        // Count is everything until the next header (or the list's end).
                        int count = 0;
                        for (int i = index + 1; i < groupedItems.length && groupedItems[i] is Patient; i++) {
                          count++;
                        }
                        return _buildPhaseHeader(item, count);
                      }

                      final Patient patient = item as Patient;
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            PatientMedicalCard(
                              patient: patient,
                              onPatientUpdate: ({required Patient patient}) {
                                updatePatient(patient: patient);
                              },
                              onVitalsUpdate: ({required Patient patient}) {
                                updatePatient(patient: patient);
                              },
                            ),
                            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                            Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                                title: const Text(
                                  "More Info",
                                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.deepCharcoal),
                                ),
                                leading: const Icon(Icons.info_outline, color: AppTheme.deepLogicViolet),
                                children: [
                                  PatientInformationCard(
                                    patient: patient,
                                    onInterviewTap: () => _launchInterviewModal(context, patient),
                                    onAssessmentsTap: () => _showAssessmentsMenu(context, patient.patientUuid),
                                    onMedsTap: () async {
                                      final Map<String, dynamic>? result = await showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        useSafeArea: true,
                                        showDragHandle: true,
                                        builder: (context) => MedicationScreen(patient: patient),
                                      );

                                      // `patient` is the same object referenced by _patients, so
                                      // mutating it in place is enough to persist the change.
                                      if (result != null) {
                                        setState(() {
                                          patient.medications = result['medications'];
                                          patient.medicationSafetyAudit = result['medication_safety_audit'];
                                        });
                                      }
                                    },
                                    onOrdersTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        useSafeArea: true,
                                        showDragHandle: true,
                                        builder: (context) => CareOrdersScreen(patient: patient),
                                      );
                                    },
                                    onDischargeReportTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        useSafeArea: true,
                                        showDragHandle: true,
                                        builder: (context) => DischargeReportScreen(patient: patient),
                                      );
                                    },
                                    onSendQuestionnaireTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => SendQuestionnaireScreen(patient: patient)),
                                      );
                                    },
                                    onArchiveTap: () async {
                                      await DatabaseManager().archivePatient(patientUuid: patient.patientUuid);
                                      await _loadPatientData();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _launchIntakeScreen(context),
        label: const Text("+", style: TextStyle(letterSpacing: 1.0, fontWeight: FontWeight.w600)),
        icon: const Icon(Symbols.frame_person),
        // Signals scanning capability
        backgroundColor: AppTheme.deepLogicViolet,
        foregroundColor: AppTheme.clinicalWhite,
      ),
    );
  }
}
