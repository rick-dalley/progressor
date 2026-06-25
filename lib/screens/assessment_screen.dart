import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../classes/assessment_session.dart';
import '../classes/symptom_evaluation.dart';
import '../classes/symptom_flag.dart';
import '../classes/triage.dart';
import '../widgets/hypothesis_widget.dart';
import '../widgets/triage_dagnostic_canvas.dart';
import '../widgets/triage_history_drawer.dart';

class AssessmentScreen extends StatefulWidget {
  final AssessmentType type;
  const AssessmentScreen({super.key, required this.type});

  @override
  State<AssessmentScreen> createState() => AssessmentScreenState();
}

class AssessmentScreenState extends State<AssessmentScreen> {
  // 1. Declare the session and engine at the class level
  late AssessmentSession _session;
  final EvaluateSymptoms _engine = EvaluateSymptoms();
  final List<SymptomFlag> _activeSymptoms = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _session = AssessmentSession();
    // Simulate async loading if needed, or set loading to false
    setState(() {
      isLoading = false;
    });
  }

  void _handleNewSymptom(SymptomFlag flag) {
    if (_activeSymptoms.contains(flag)) return;

    setState(() {
      _activeSymptoms.add(flag);
      // Explicitly pass flag.name (which is a String) to match the engine's requirement
      _engine.hypothesesFromNewSymptom(flag.name);
    });
  }

  void _handleRemoveSymptom(SymptomFlag flag) {
    setState(() {
      _activeSymptoms.remove(flag);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        actions: [
          Builder(
            builder: (context) =>
                IconButton(icon: const Icon(Icons.history), onPressed: () => Scaffold.of(context).openEndDrawer()),
          ),
        ],
      ),
      endDrawer: TriageHistoryDrawer(history: const [], onJump: (int p1) {}),
      body: SafeArea(
        child: Column(
          children: [
            // DIAGNOSTIC AREA: Passed the fully-initialized _session
            Expanded(
              flex: 2,
              child: DiagnosticCanvas(
                activeSymptoms: _activeSymptoms,
                hypotheses: _engine.hypotheses,
                session: _session,
              ),
            ),
            // INPUT AREA: Passed the handlers
            // Inside AssessmentScreenState.build
            HypothesisWidget(
              assessmentType: widget.type,
              activeSymptoms: _activeSymptoms,
              // The callback here MUST expect a SymptomFlag, not a String
              onSymptomAdded: (SymptomFlag flag) => _handleNewSymptom(flag),
              onSymptomRemoved: (SymptomFlag flag) => _handleRemoveSymptom(flag),
              hypotheses: _engine.hypotheses,
            ),
          ],
        ),
      ),
    );
  }
}
