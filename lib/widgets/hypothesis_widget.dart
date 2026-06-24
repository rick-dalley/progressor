import 'package:flutter/material.dart';
import 'package:triage/widgets/symptom_input_widget.dart';

import '../classes/symptom_evaluation.dart';
import '../classes/symptom_flag.dart';
import '../classes/triage.dart';

class HypothesisWidget extends StatefulWidget {
  final AssessmentType assessmentType;
  const HypothesisWidget({super.key, required this.assessmentType});

  @override
  State<StatefulWidget> createState() => HypothesisWidgetState();
}

class HypothesisWidgetState extends State<HypothesisWidget> {
  final EvaluateSymptoms engine = EvaluateSymptoms();

  void _onNewSymptom(SymptomFlag flag) {
    setState(() {
      engine.hypothesesFromNewSymptom(flag.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SymptomInputWidget(onSymptomAdded: _onNewSymptom),
        Expanded(
          child: ListView.builder(
            itemCount: engine.hypotheses.length,
            itemBuilder: (context, index) {
              final h = engine.hypotheses[index];
              return ListTile(title: Text(h.hypothesis.name), trailing: Text("${h.score} pts"));
            },
          ),
        ),
      ],
    );
  }
}
