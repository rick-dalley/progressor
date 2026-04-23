import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../generated/l10n.dart';

class PHQ9AssessmentScreen extends StatefulWidget {
  final Map<String, dynamic> template;

  // CHANGE 1: Add this optional controller to the class
  final ScrollController? scrollController;

  const PHQ9AssessmentScreen({
    super.key,
    required this.template,
    this.scrollController, // CHANGE 2: Add it to the constructor
  });
  @override
  PHQ9AssessmentScreenState createState() => PHQ9AssessmentScreenState();
}

class PHQ9AssessmentScreenState extends State<PHQ9AssessmentScreen> {
  Map<String, int> answers = {};
  String? selectedImpactId;
  int get totalScore => answers.values.fold(0, (sum, val) => sum + val);
  bool _showValidationErrors = false;

// At the top of your state class
  List<dynamic>? _scoreGuide;

  Future<void> _loadScoreGuide() async {
    final String response = await rootBundle.loadString('assets/questions/phq9_score_guide.json');
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
            itemCount: questions.length + 1, // Questions + 1 for Footer
            itemBuilder: (context, index) {
              // Render Questions
              if (index < questions.length) {
                final q = questions[index];
                return _buildQuestionItem(q);
              }

              // Render Footer at the very bottom of the scroll
              return Column(
                children: [
                  _buildImpactSelector(widget.template['questions_impact']),
                  _buildScoreFooter(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // Added the missing helper method here
  Widget _buildQuestionItem(Map<String, dynamic> q) {
    // Check if the question is missing an answer
    bool isMissing = !answers.containsKey(q['id']);

    // Only show the "error" state if the user has tried to submit
    bool showWarning = _showValidationErrors && isMissing;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16.0),
      // Give it a subtle red background and border if missing
      decoration: BoxDecoration(
        color: showWarning ? Colors.red.withValues(alpha:0.05) : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: showWarning ? Colors.red : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  q['text'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    // Turn the text red if missing
                    color: showWarning ? Colors.red.shade900 : Colors.black,
                  ),
                ),
              ),
              if (showWarning)
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(q['max_score'] + 1, (score) {
              String labelText = widget.template['column_headers'][score + 1] ?? "";

              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labelText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    ChoiceChip(
                      label: Text(
                        score.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      selected: answers[q['id']] == score,
                      onSelected: (selected) {
                        setState(() {
                          answers[q['id']] = score;
                          // Optional: remove error once they pick a value
                          if (answers.length == widget.template['questions_score'].length) {
                            _showValidationErrors = false;
                          }
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactSelector(List<dynamic> options) {
    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The instruction text from the template
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.template['questions_impact_text'] ?? "",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        // Vertical selection list
        Column(
          children: options.map((option) {
            final String id = option['id'];
            final String text = option['text'];
            final bool isSelected = answers.containsKey(id);

            return InkWell(
              onTap: () {
                setState(() {
                  // Clear out any previous impact selection (q10-q13)
                  for (var opt in options) {
                    answers.remove(opt['id']);
                  }
                  // Store the new one with value 0 to keep totalScore accurate
                  answers[id] = 0;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    // Mimics the paper checkbox/radio look
                    Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    // The text now has the full width to breathe
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? Colors.black : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Map<String, String>? getInterpretation() {
    final questions = widget.template['questions_score'] as List;

    // 1. Check for missing values
    if (answers.length < questions.length) return null;

    // 2. PHQ-9 Clinical Logic: Count symptoms >= 2 (More than half the days)
    int highFreqCount = 0;
    bool q1OrQ2HighFreq = false;

    for (var q in questions) {
      int score = answers[q['id']] ?? 0;
      if (score >= 2) {
        highFreqCount++;
        if (q['id'] == 'q1' || q['id'] == 'q2') q1OrQ2HighFreq = true;
      }
    }

    // 3. Determine Syndrome Suggestion
    String syndrome = "No specific depressive syndrome suggested.";
    if (q1OrQ2HighFreq) {
      if (highFreqCount >= 5) {
        syndrome = "Major Depressive Disorder suggested.";
      } else if (highFreqCount >= 2) {
        syndrome = "Other Depressive Syndrome suggested.";
      }
    }

    // 4. Match Total Score against JSON Assets
    int score = totalScore;
    String severity = "Unknown";
    String action = "No action defined.";

    if (_scoreGuide != null) {
      for (var entry in _scoreGuide!) {
        if (score <= entry['max_score']) {
          severity = entry['severity'];
          action = entry['action'];
          break;
        }
      }
    }

    return {
      "summary": "$syndrome Severity: $severity (Score: $score).",
      "action": action
    };
  }
  void _submitAssessment(){}
  Widget _buildScoreFooter() {
    final questions = widget.template['questions_score'] as List;

    // 1. Check if all 9 clinical questions are answered
    bool allQuestionsAnswered = questions.every((q) => answers.containsKey(q['id']));

    // 2. Check if the impact question (q10-q13) is answered
    // We check if any key starting with 'q10', 'q11', etc., exists
    // or if you used the 'impact_id' key approach we discussed.
    bool impactAnswered = answers.keys.any((key) => ['q10', 'q11', 'q12', 'q13'].contains(key));

    final bool isFormComplete = allQuestionsAnswered && impactAnswered;

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
              "Recommended Action: ${interpretation['action']}",
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

                String message = !allQuestionsAnswered
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
}

