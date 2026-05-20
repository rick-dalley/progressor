import 'package:flutter/material.dart';
import 'package:triage/classes/assessment_logic.dart';
import '../generated/l10n.dart';
import '../widgets/likert_question.dart';

class ASRSAssessmentScreen extends StatefulWidget {
  final Map<String, dynamic> template;

  // CHANGE 1: Add this optional controller to the class
  final ScrollController? scrollController;

  const ASRSAssessmentScreen({
    super.key,
    required this.template,
    this.scrollController, // CHANGE 2: Add it to the constructor
  });
  @override
  ASRSAssessmentScreenState createState() => ASRSAssessmentScreenState();
}

class ASRSAssessmentScreenState extends State<ASRSAssessmentScreen> {
  AssessmentAnswerMap answers = {};
  String? selectedImpactId;
  int get totalScore => answers.values.fold(0, (sum, val) => sum + val.value);
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
                currentAnswer: answers[q['id']] ?? AssessmentAnswer(0, "", false),
                showWarning: _showValidationErrors && !answers.containsKey(q['id']),
                onChanged: (score) {
                  setState(() {
                    answers[q['id']] ??= AssessmentAnswer(0, "", false);
                    answers[q['id']]?.value = score;
                  });
                },
                onDescriptionChanged: (id, description) {
                  setState(() {
                    answers[q['id']] ??= AssessmentAnswer(0, "", true);
                    answers[q['id']]?.text = description;
                  });
                },
              );

              // Always return a Column so the header actually shows up
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
    final questions = widget.template['questions_score'] as List;
    if (answers.length < questions.length) return null;

    int partAShadedCount = 0;

    for (var q in questions) {
      // Only look at Part A for the initial "Positive Screen" check
      if (q['cluster'] == 'A') {
        AssessmentAnswer? answer = answers[q['id']];
        int score  = answer?.value ?? 0;
        int threshold = q['threshold'] ?? 99; // Fallback if missing

        if (score >= threshold) {
          partAShadedCount++;
        }
      }
    }

    bool isPositiveScreen = partAShadedCount >= 4;

    String resultText = isPositiveScreen
        ? "Positive Screen: Symptoms are highly consistent with ADHD in adults."
        : "Negative Screen: Symptoms do not meet the threshold for a provisional ADHD diagnosis.";

    return {
      "summary": "Part A Endorsed: $partAShadedCount/6",
      "action": resultText,
    };
  }

  Widget _buildScoreFooter() {
    final questions = widget.template['questions_score'] as List;

    // Check if all 9 clinical questions are answered
    bool isFormComplete = questions.every((q) => answers.containsKey(q['id']));

    // Only get interpretation if the form is actually complete
    final interpretation = isFormComplete ? getInterpretation() : null;

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.blueGrey.shade50,
      child: Column(
        children: [
          // Display interpretation ONLY when everything is filled
          if (interpretation != null) ...[
            Text(
              interpretation['summary']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Recommended ${interpretation['action']}",
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

          ElevatedButton(
            onPressed: () {
              if (!isFormComplete) {
                setState(() => _showValidationErrors = true);

                String message = !isFormComplete
                    ? "Please answer all 9 clinical questions."
                    : "Please select the impact of these symptoms.";

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              } else {
                _submitAssessment();
              }
            },
            child: const Text("Finalize & Map to DSM"),
          ),
        ],
      ),
    );
  }

  void _submitAssessment(){}

}

