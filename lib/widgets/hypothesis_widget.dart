import 'package:flutter/material.dart';
import 'package:triage/widgets/symptom_input_widget.dart';
import '../classes/symptom_evaluation.dart';
import '../classes/symptom_flag.dart';
import '../classes/triage.dart';

// HypothesisWidget (The "Evidence Clustering" View)
class HypothesisWidget extends StatelessWidget {
  final AssessmentType assessmentType;
  final List<SymptomFlag> activeSymptoms;
  final Function(SymptomFlag) onSymptomAdded;
  final Function(SymptomFlag) onSymptomRemoved;
  final List<HypothesisClassification> hypotheses;

  const HypothesisWidget({
    super.key,
    required this.assessmentType,
    required this.activeSymptoms,
    required this.onSymptomAdded,
    required this.onSymptomRemoved,
    required this.hypotheses,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SymptomInputWidget(onSymptomAdded: onSymptomAdded),
        // Filter: only show hypotheses that have been touched (score > 0)
        ...hypotheses
            .where((h) => h.sharedSymptoms.isNotEmpty)
            .map(
              (h) => Card(
                child: Column(
                  children: [
                    ListTile(title: Text(h.hypothesis.name), trailing: Text("${h.score} pts")),
                    Wrap(children: h.sharedSymptoms.map((s) => Chip(label: Text(s.name))).toList()),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
