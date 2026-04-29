import 'package:flutter/material.dart';
import 'package:triage/screens/asrs.dart';
import 'package:triage/screens/cssrs.dart';
import 'package:triage/screens/dast10.dart';
import 'package:triage/screens/gad7.dart';
import 'package:triage/screens/pcl5.dart';
import 'package:triage/screens/police_report.dart';
import 'package:triage/screens/timeline.dart';
import 'package:triage/screens/vitals.dart';
import 'package:triage/classes/templates.dart';
import '../classes/database_manager.dart';
import '../generated/l10n.dart';
import '../widgets/patient_card.dart';
import '../screens/phq9.dart';
import 'intake.dart';
import 'meds.dart';
import 'observation.dart';

class PatientRoster extends StatefulWidget {
  const PatientRoster({super.key});

  @override
  State<PatientRoster> createState() => _PatientRosterState();
}

class _PatientRosterState extends State<PatientRoster> {
  List<dynamic> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    // DatabaseManager is a singleton, so this is safe and fast
    final data = await DatabaseManager().getAllPatients();

    setState(() {
      _patients = data;
      // Since it's already a List<Map<String, dynamic>>,
      // you don't need to manually decode anymore.
    });
  }

  void _launchIntakeScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntakeScreen(),
        // This ensures the screen slides up like a focused task
        fullscreenDialog: true,
      ),
    );
  }
  void _showAssessmentsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Required to let the modal expand
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        // Limit the height so it doesn't hit the very top of the screen
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Container hugs the content
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("QUICK RECORD", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),

            Flexible( // Use Flexible so the ListView takes only the remaining space
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                      leading: const Icon(Icons.note_add, color: Colors.amber),
                      title: const Text("Observations"),
                      onTap: () { Navigator.pop(context); _launchObservationsModal(context);} // Link to Sticky Note Entry
                  ),
                  ListTile(
                      leading: const Icon(Icons.assignment, color: Colors.blueAccent),
                      title: const Text("PHQ-9"),
                      onTap: () => _launchAssessment(
                        context,
                        templateName: "phq-9.json",
                        screenBuilder: (data, controller) => PHQ9AssessmentScreen(template: data, scrollController: controller),
                      )
                  ),
                  ListTile(
                      leading: const Icon(Icons.assignment, color: Colors.blueAccent),
                      title: const Text("GAD-7"),
                      onTap: () => _launchAssessment(
                        context,
                        templateName: "gad-7.json",
                        screenBuilder: (data, controller) => GAD7AssessmentScreen(template: data, scrollController: controller),
                      )
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment, color: Colors.blueAccent),
                    title: const Text("C-SSRS"),
                      onTap: () => _launchAssessment(
                        context,
                        templateName: "c-ssrs.json",
                        screenBuilder: (data, controller) => CSSRSAssessmentScreen(template: data, scrollController: controller),
                      )
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment, color: Colors.blueAccent),
                    title: const Text("DAST-10"),
                      onTap: () => _launchAssessment(
                        context,
                        templateName: "dast-10.json",
                        screenBuilder: (data, controller) => DAST10AssessmentScreen(template: data, scrollController: controller),
                      )
                  ),
                  //ASRS-V1.1
                  ListTile(
                    leading: const Icon(Icons.assignment, color: Colors.blueAccent),
                    title: const Text("ASRS-V1.1"),
                      onTap: () => _launchAssessment(
                        context,
                        templateName: "asrs.json",
                        screenBuilder: (data, controller) => ASRSAssessmentScreen(template: data, scrollController: controller),
                      )
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment, color: Colors.blueAccent),
                    title: const Text("PCL-5"),
                      onTap: () => _launchAssessment(
                        context,
                        templateName: "pcl-5.json",
                        screenBuilder: (data, controller) => PCL5AssessmentScreen(template: data, scrollController: controller),
                      )
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _launchVitalsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the modal to grow beyond 50% screen height
      backgroundColor: Colors.transparent, // Let the container handle the color
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9, // Opens at 90% of screen height
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
                // A small handle to indicate the modal is draggable
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),

                Expanded(
                  child: VitalsScreen(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  void _launchObservationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the modal to grow beyond 50% screen height
      backgroundColor: Colors.transparent, // Let the container handle the color
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9, // Opens at 90% of screen height
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
                // A small handle to indicate the modal is draggable
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),

                Expanded(
                  child: ObservationScreen(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  void _launchTimelineModal(BuildContext context, Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Essential for large/tall content
      backgroundColor: Colors.transparent, // Allows for rounded top corners
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9, // Opens almost full screen
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
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)
                    )
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
                Expanded(
                  child: PatientTimelineScreen(patient: patient),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchAssessment(
      BuildContext context, {
        required String templateName,
        required Widget Function(Map<String, dynamic> template, ScrollController controller) screenBuilder,
      }) async {
    // 1. Fetch the requested template
    Map<String, dynamic> template = await Templates.getTemplate(templateName);
    // 2. Standardized Modal Plumbing
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
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
                const SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))
                ),
                Expanded(
                  // 3. Inject the specific screen here
                  child: screenBuilder(template, scrollController),
                ),
              ],
            ),
          );
        },
      ),
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
          color: Color(0xFF1A365D), // Navy indicator for a "smart" feel
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80), // Added top padding for breathing room
        itemCount: _patients.length,
        itemBuilder: (context, index) {
          return PatientCard(
            patient: _patients[index],
            onVitalsTap: () => _launchVitalsModal(context),
            onAssessmentsTap: () => _showAssessmentsMenu(context),
              onMedsTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  // 1. Add rounded corners to the top
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  // 2. Ensure the AppBar doesn't "bleed" over the rounded corners
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  builder: (context) => MedicationScreen(patient: _patients[index]),
                );
              },
            onPoliceTap: () {
            // We don't need Navigator.pop(context) here because
            // there is no menu to close—we're tapping the card directly.
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PoliceReportScreen()),
            );
          },// Your existing assessment menu
            onTimeLineTap: () => _launchTimelineModal(context, _patients[index])
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _launchIntakeScreen(context), // New dedicated screen
        label: const Text(
          "INTAKE",
          style: TextStyle(
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: const Icon(Icons.qr_code_scanner), // Signals scanning capability
        backgroundColor: const Color(0xFF1A365D),
        foregroundColor: Colors.white,
      ),
    );
  }
}