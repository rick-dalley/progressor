import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/psychosis.dart';
import 'package:triage/widgets/toxidrome_test_widget.dart';

import '../widgets/psychosis_assessment_widget.dart';
import 'intake.dart';

class IncidentTriageScreen extends StatelessWidget {
  const IncidentTriageScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Intervention"),
        actions: [
          // The "John Doe" / Photo Quick-Capture Button
          IconButton(icon: const Icon(Icons.camera_alt), onPressed: () => _handleAnonymousCapture(context)),
        ],
      ),
      body: Column(
        children: [
          // 1. Quick Identity Header (Can be minimized or expanded)
          _buildIdentityHeader(context),

          // 2. The Triage/Reason Selection Grid
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildReasonChip(context, "Toxidrome", Symbols.mixture_med, Colors.red),
                _buildReasonChip(context, "Psychotic Break", Symbols.psychology, Colors.orange),
                _buildReasonChip(context, "Suicide Risk", Symbols.skull, Colors.deepPurple),
                _buildReasonChip(context, "Public Safety", Symbols.crowdsource, Colors.blue),
              ],
            ),
          ),
          // ToxidromeAssessmentWidget(),
          Expanded(child: PsychosisAssessmentWidget(subjectName: "subject")),
        ],
      ),
    );
  }

  Widget _buildIdentityHeader(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person_outline)),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Subject: John Doe", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Status: Unidentified", style: TextStyle(fontSize: 12)),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              _launchIntakeScreen(context);
            },
            child: const Text("EDIT"),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonChip(BuildContext context, String title, IconData icon, Color color) {
    return ElevatedButton(
      onPressed: () {
        // Here you would navigate to the specific Assessment screen
        // e.g., Navigator.push(context, MaterialPageRoute(builder: (_) => ToxidromeAssessmentScreen()));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _handleAnonymousCapture(BuildContext context) {
    // Quick camera logic would go here
  }
}
