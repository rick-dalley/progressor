import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:triage/screens/police_report.dart';
import 'package:triage/screens/vitals.dart';
import 'package:triage/templates.dart';
import '../generated/l10n.dart';
import '../widgets/patient_card.dart';
import '../screens/assessment.dart';
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

  // Future-proof: Loading from local JSON for the POC
  Future<void> _loadPatientData() async {
    final String response = await rootBundle.loadString('assets/patients/patients.json');
    final List<dynamic> data = await json.decode(response);

    setState(() {
      // Filter out any nulls just in case the JSON has a trailing comma
      _patients = data.where((item) => item != null).toList();
    });
  }
  void _showEntryMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("QUICK RECORD", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            ListTile(
              leading: const Icon(Icons.monitor_heart, color: Colors.redAccent),
              title: const Text("Vitals"),
              onTap: () {
                Navigator.pop(context);
                _launchVitalsModal(context);
              }, // Link to Vitals Screen
            ),
            ListTile(
              leading: const Icon(Icons.note_add, color: Colors.amber),
              title: const Text("Observation (Sticker)"),
              onTap: () { Navigator.pop(context); _launchObservationsModal(context);} // Link to Sticky Note Entry
            ),
            ListTile(
              leading: const Icon(Icons.assignment, color: Colors.blueAccent),
              title: const Text("Assessment"),
              onTap: () {
                Navigator.pop(context);
                _launchAssessmentModal(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_police_outlined, color: Colors.greenAccent),
              title: const Text("Law Enforcement Handoff"),
              subtitle: const Text("Section 28, Form 10, or Verbal Report"),
              onTap: () {
                Navigator.pop(context); // Close the popup
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PoliceReportScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
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


  void _launchAssessmentModal(BuildContext context) {
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
                  child: AssessmentScreen(
                    // Pass your JSON template here
                    template: templates.getPhq9Template(),
                    // If your AssessmentScreen has a ListView, pass this controller to it
                    // so the scrolling feels integrated with the modal
                    scrollController: scrollController,
                  ),
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
          return PatientCard(patient: _patients[index]);
        },
      ),

      // Floating Action Button updated to match the new brand palette
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEntryMenu(context),
        label: const Text(
          "RECORD",
          style: TextStyle(
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: const Icon(Icons.add),
        // Using the Navy color from your main brand for a focused, intelligent action
        backgroundColor: const Color(0xFF1A365D),
        foregroundColor: Colors.white,
      ),
    );
  }
}