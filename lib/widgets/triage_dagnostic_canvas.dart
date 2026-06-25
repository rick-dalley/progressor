import 'package:flutter/material.dart';
import '../classes/assessment_session.dart';
import '../classes/symptom_flag.dart';
import '../classes/symptom_evaluation.dart';

class DiagnosticCanvas extends StatelessWidget {
  final List<SymptomFlag> activeSymptoms;
  final List<HypothesisClassification> hypotheses;
  final AssessmentSession session; // Included to access your existing session logic

  const DiagnosticCanvas({super.key, required this.activeSymptoms, required this.hypotheses, required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Acuity Display
          Text(
            "Acuity: ${session.acuityScore > 5 ? 'CRITICAL' : 'STABLE'}",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: session.acuityScore > 5 ? Colors.red : Colors.green,
            ),
          ),
          const Divider(),

          // Top Hypothesis Display
          const Text("Top Hypothesis:", style: TextStyle(fontWeight: FontWeight.bold)),
          if (hypotheses.isNotEmpty) Text("• ${hypotheses.first.hypothesis.name} (${hypotheses.first.score} pts)"),
          if (hypotheses.isEmpty) const Text("• Awaiting symptoms..."),

          const SizedBox(height: 10),

          // Resuscitation Steps (Pulled from Session)
          const Text("Immediate Actions:", style: TextStyle(fontWeight: FontWeight.bold)),
          ...session.resuscitationSteps.map((s) => Text("• $s")),

          const SizedBox(height: 10),

          // Debugging/Verification of Active Symptoms
          Text("Symptoms Logged: ${activeSymptoms.length}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
