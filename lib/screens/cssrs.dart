import 'package:flutter/material.dart';
import '../generated/l10n.dart';
import '../widgets/likert_question.dart';

class CSSRSAssessmentScreen extends StatefulWidget {
  final Map<String, dynamic> template;

  // CHANGE 1: Add this optional controller to the class
  final ScrollController? scrollController;

  const CSSRSAssessmentScreen({
    super.key,
    required this.template,
    this.scrollController, // CHANGE 2: Add it to the constructor
  });
  @override
  CSSRSAssessmentScreenState createState() => CSSRSAssessmentScreenState();
}

class CSSRSAssessmentScreenState extends State<CSSRSAssessmentScreen> {
  Map<String, int> answers = {};
  String? selectedImpactId;
  int get totalScore => answers.values.fold(0, (sum, val) => sum + val);
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final String instructionText = widget.template['column_headers'][0];
    final List questions = widget.template['questions_score'];

    return Column(
      children: [
        // 1. Frozen Header Area (Stays at the top)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          color: Colors.blueGrey.shade50,
          child: Column(
            children: [
              Text(
                widget.template['title'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                instructionText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // 2. Scrolling Content
        // Wrapping in Expanded tells the ListView: "Take up the rest of the modal's height."
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController, // Link to the DraggableSheet
            itemCount: questions.length, // Questions + 1 for Footer
            itemBuilder: (context, index) {

              final q = questions[index];

              bool showHeader = false;
              if (index == 0) {
                // Always show for the first item
                showHeader = true;
              } else {
                // Show if this cluster ID is different from the previous one
                final previousQ = questions[index - 1];
                if (q['cluster'] != previousQ['cluster']) {
                  showHeader = true;
                }
              }

              // 2. Build the Header Widget
              Widget header = const SizedBox.shrink();
              if (showHeader && q['cluster_name'] != null) {
                header = Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  color: Colors.blueGrey.withValues(alpha: 0.1),
                  child: Text(
                    q['cluster_name'].toString().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.blueGrey,
                    ),
                  ),
                );
              }

              Widget questionTile = LikertQuestionTile(
                // Cast 'q' and 'template' to the Map types expected by the widget
                q: q as Map<String, dynamic>,
                template: widget.template,
                currentValue: answers[q['id']],
                showWarning: _showValidationErrors && !answers.containsKey(q['id']),
                onChanged: (score) {
                  setState(() {
                    answers[q['id']] = score;
                  });
                },
              );
              // 4. THE FIX: Always return a Column so the header actually shows up
              print("Index: $index, Length - 1:${questions.length-1}");
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header, // This will be a SizedBox.shrink() unless showHeader is true
                  questionTile,
                  // Only attach the footer logic if it's the very last question
                  if (index == questions.length -1) ...[
                    _buildScoreFooter(),
                    const SizedBox(height: 40),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Map<String, String>? getInterpretation() {
    // 1. Minimum check: If the user hasn't touched the app, hide the footer box
    if (answers.isEmpty) return null;

    // 2. Mandatory Core: Questions 1 & 2, plus the 4 main Behavior questions
    final coreIds = ['q1', 'q2', 'b1', 'b2', 'b3', 'b4'];

    // If these core items aren't in the answers map, the form is incomplete
    bool coreComplete = coreIds.every((id) => answers.containsKey(id));

    if (!coreComplete) {
      return {"summary": "", "action": ""};
    }

    // 3. Clinical Logic (Cascading Severity)
    String summary = "Negative Screen";
    String action = "STABLE: No suicidal ideation or behavior endorsed.";

    // High Risk: Any Behavior (b1-b4) OR High Ideation (q4-q5)
    bool behaviorEndorsed = ['b1', 'b2', 'b3', 'b4'].any((id) => answers[id] == 1);
    bool highIdeation = (answers['q4'] == 1 || answers['q5'] == 1);

    if (behaviorEndorsed || highIdeation) {
      summary = "High Risk Endorsed";
      action = "HIGH RISK: Immediate safety protocol required. Endorsement of intent, plan, or behavior.";
    }
    // Moderate Risk: Method (q3)
    else if (answers['q3'] == 1) {
      summary = "Moderate Ideation";
      action = "MODERATE RISK: Urgent clinical consultation recommended. Method endorsed without intent.";
    }
    // Low Risk: Passive (q1 or q2)
    else if (answers['q1'] == 1 || answers['q2'] == 1) {
      summary = "Low Ideation (Passive)";
      action = "LOW RISK: Passive ideation detected. Routine mental health referral suggested.";
    }

    return {
      "summary": "Severity: $summary",
      "action": action,
    };
  }

  Widget _buildScoreFooter() {
    final interpretation = getInterpretation();

    // The form is "Ready" if the interpretation returned actual text
    bool isActionable = interpretation != null &&
        interpretation['summary']!.isNotEmpty &&
        interpretation['action']!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.blueGrey.shade50,
      child: Column(
        children: [
          if (isActionable) ...[
            Text(
              interpretation['summary']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              interpretation['action']!,
              style: const TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],

          Text(
            "Current Score: $totalScore",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (!isActionable) {
                  setState(() => _showValidationErrors = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please complete the required clinical indicators.")),
                  );
                } else {
                  _submitAssessment();
                }
              },
              child: const Text("Finalize & Map to DSM"),
            ),
          ),
        ],
      ),
    );
  }

  void _submitAssessment(){}

}

