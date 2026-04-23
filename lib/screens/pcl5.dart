import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../generated/l10n.dart';
import '../widgets/likert_question.dart';

class PCL5AssessmentScreen extends StatefulWidget {
  final Map<String, dynamic> template;

  // CHANGE 1: Add this optional controller to the class
  final ScrollController? scrollController;

  const PCL5AssessmentScreen({
    super.key,
    required this.template,
    this.scrollController, // CHANGE 2: Add it to the constructor
  });
  @override
  PCL5AssessmentScreenState createState() => PCL5AssessmentScreenState();
}

class PCL5AssessmentScreenState extends State<PCL5AssessmentScreen> {
  Map<String, int> answers = {};
  String? selectedImpactId;
  int get totalScore => answers.values.fold(0, (sum, val) => sum + val);
  bool _showValidationErrors = false;

// At the top of your state class
  List<dynamic>? _scoreGuide;

  Future<void> _loadScoreGuide() async {
    final String response = await rootBundle.loadString('assets/questions/pcl5_score_guide.json');
    final data = await json.decode(response);
    setState(() {
      _scoreGuide = data;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadScoreGuide();
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
              if (index == questions.length - 1) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    questionTile, // The last question is still rendered here!
                    // _buildImpactSelector(widget.template['questions_impact']),
                    _buildScoreFooter(),
                    const SizedBox(height: 40), // iPhone bottom-area padding
                  ],
                );
              }

              // 3. For all other indices, just return the tile
              return questionTile;
            },
          ),
        ),
      ],
    );
  }
  Map<String, String>? getInterpretation() {
    final questions = widget.template['questions_score'] as List;
    if (answers.length < questions.length) return null;

    int totalScore = answers.values.fold(0, (sum, val) => sum + val);

    // Group endorsed items by cluster (Score >= 2)
    Map<String, int> clusterCounts = {"B": 0, "C": 0, "D": 0, "E": 0};

    for (var q in questions) {
      String cluster = q['cluster'];
      int score = answers[q['id']] ?? 0;
      if (score >= 2) {
        clusterCounts[cluster] = (clusterCounts[cluster] ?? 0) + 1;
      }
    }

    // DSM-5 Diagnostic Criteria
    bool meetsCriteria = clusterCounts['B']! >= 1 &&
        clusterCounts['C']! >= 1 &&
        clusterCounts['D']! >= 2 &&
        clusterCounts['E']! >= 2;

    String diagnosis = meetsCriteria
        ? "Criteria met for Provisional PTSD Diagnosis."
        : "DSM-5 cluster criteria not fully met.";

    return {
      "summary": "Total Score: $totalScore. $diagnosis",
    };
  }

  Widget _buildScoreFooter() {
    final questions = widget.template['questions_score'] as List;

    // 1. Check if all 9 clinical questions are answered
    bool isFormComplete = questions.every((q) => answers.containsKey(q['id']));

    // 2. Check if the impact question (q10-q13) is answered
    // We check if any key starting with 'q10', 'q11', etc., exists
    // or if you used the 'impact_id' key approach we discussed.
    bool impactAnswered = answers.keys.any((key) => ['q10', 'q11', 'q12', 'q13'].contains(key));

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

