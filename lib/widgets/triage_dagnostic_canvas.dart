import 'package:flutter/material.dart';

import '../classes/assessment_session.dart';

class DiagnosticCanvas extends StatelessWidget {
  final AssessmentSession session;
  final bool showAnatomyMap; // Toggle this from the parent

  const DiagnosticCanvas({super.key, required this.session, this.showAnatomyMap = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: showAnatomyMap ? _buildAnatomyView() : _buildSummaryView(),
      ),
    );
  }

  Widget _buildSummaryView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Acuity: ${session.acuityScore > 5 ? 'CRITICAL' : 'STABLE'}",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: session.acuityScore > 5 ? Colors.red : Colors.green,
            ),
          ),
          const Divider(),
          Text("Hypothesis:", style: const TextStyle(fontWeight: FontWeight.bold)),
          ...session.differentialDiagnosis.map((d) => Text("• $d")),
          const SizedBox(height: 10),
          Text("Immediate Actions:", style: const TextStyle(fontWeight: FontWeight.bold)),
          ...session.resuscitationSteps.map((s) => Text("• $s")),
        ],
      ),
    );
  }

  Widget _buildAnatomyView() {
    // Placeholder for your Acuitage anatomy mapping logic
    return Center(child: Text("Anatomy Map Layer Active"));
  }
}
