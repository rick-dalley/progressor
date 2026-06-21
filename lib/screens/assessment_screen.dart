import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../classes/assessment_session.dart';
import '../classes/triage.dart';
import '../widgets/assessment_wizard.dart';
import '../widgets/command_wizard_bar.dart';
import '../widgets/psychosis_assessment_widget.dart';
import '../widgets/suicide_assessment_widget.dart';
import '../widgets/toxidrome_test_widget.dart';
import '../widgets/triage_dagnostic_canvas.dart';
import '../widgets/triage_history_drawer.dart';
import 'missing_person_screen.dart';

class CurrentNodeContent extends StatelessWidget {
  final Map<String, dynamic> nodeData;
  const CurrentNodeContent({super.key, required this.nodeData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(nodeData['question'] ?? "No question"),
        // Dynamically build buttons from the options list
        ...((nodeData['options'] as List).map(
          (opt) => ElevatedButton(
            onPressed: () => {} /* Call a callback to trigger wizard.advance */,
            child: Text(opt['label']),
          ),
        )),
      ],
    );
  }
}

class AssessmentScreen extends StatefulWidget {
  final AssessmentType type;
  const AssessmentScreen({super.key, required this.type});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  AssessmentWizard? _wizard;
  late AssessmentSession _session;
  late Map<String, dynamic> triageJSON;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _session = AssessmentSession();
    // Load data then initialize the wizard
    if (widget.type.needsData) {
      _loadTriageJson().then((data) {
        setState(() {
          triageJSON = data;
          _wizard = AssessmentWizard(triageFlow: data, currentNodeId: widget.type.rootNodeId);
          isLoading = false;
        });
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 2. Implementation to load the JSON
  Future<Map<String, dynamic>> _loadTriageJson() async {
    final String response = await rootBundle.loadString('assets/assessment/triage.json');
    final decodedJSON = json.decode(response) as List<dynamic>;
    return decodedJSON[widget.type.index] as Map<String, dynamic>;
  }

  // Inside AssessmentScreen build method
  @override
  Widget build(BuildContext context) {
    if (isLoading || (widget.type.needsData && _wizard == null)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      // Adds a button to the top right to open the drawer
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        actions: [
          Builder(
            builder: (context) =>
                IconButton(icon: const Icon(Icons.history), onPressed: () => Scaffold.of(context).openEndDrawer()),
          ),
        ],
      ),
      endDrawer: TriageHistoryDrawer(history: const [], onJump: (int p1) {}), // Your existing drawer class
      body: SafeArea(
        child: Column(
          children: [
            Expanded(flex: 2, child: DiagnosticCanvas(session: _session)),
            if (widget.type == AssessmentType.toxidrome) ToxidromeAssessmentWidget(),
            if (widget.type == AssessmentType.psychosis) PsychosisAssessmentWidget(subjectName: "subject"),
            if (widget.type == AssessmentType.suicide) SuicideAssessmentWidget(subjectName: ""),
            if (widget.type == AssessmentType.missing) MissingPersonCaptureScreen(),
            if (widget.type == AssessmentType.breathing) buildExpandedAssessmentWidget(),
            if (widget.type == AssessmentType.bleeding) buildExpandedAssessmentWidget(),
            if (widget.type == AssessmentType.consciousness) buildExpandedAssessmentWidget(),
            if (widget.type == AssessmentType.systemic) buildExpandedAssessmentWidget(),
            if (widget.type == AssessmentType.esi) buildExpandedAssessmentWidget(),
          ],
        ),
      ),
    );
  }

  Expanded buildExpandedAssessmentWidget() {
    return Expanded(
      flex: 1,
      child: CommandWizardBar(
        wizard: _wizard!,
        onAdvance: (label) => setState(() {
          _wizard!.advance(label);
          _session.processNodeResponse(_wizard!.currentNode['meta']);
        }),
        onBack: () => setState(() => _wizard!.goBack()),
      ),
    );
  }
}
