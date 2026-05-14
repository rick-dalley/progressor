import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../classes/assessment_logic.dart';
import '../classes/database_manager.dart';
import '../generated/l10n.dart';
import '../widgets/likert_question.dart';

class StandardizedAssessmentScreen extends StatefulWidget {
  final String assessmentId;
  final String patientUuid;
  final bool isReadOnly;
  final String? scoreGuidePath;
  final Map<String, dynamic> template;
  final AssessmentLogic? logic;
  final ScrollController? scrollController;

  const StandardizedAssessmentScreen({
    super.key,
    required this.assessmentId,
    required this.patientUuid,
    required this.isReadOnly,
    required this.template,
    this.scoreGuidePath,
    this.logic,
    this.scrollController, // CHANGE 2: Add it to the constructor
  });

  @override
  StandardizedAssessmentScreenState createState() =>
      StandardizedAssessmentScreenState();
}

class StandardizedAssessmentScreenState
    extends State<StandardizedAssessmentScreen> {
  Map<String, int> answers = {};
  String? selectedImpactId;

  int get totalScore => answers.values.fold(0, (sum, val) => sum + val);
  bool _showValidationErrors = false;

  // At the top of your state class
  List<dynamic>? _scoreGuide;

  Future<void> _loadScoreGuide() async {
    // Only attempt to load if a path was provided
    if (widget.scoreGuidePath == null) return;

    try {
      final String response = await rootBundle.loadString(
        widget.scoreGuidePath!,
      );
      final data = await json.decode(response);
      if (mounted) {
        setState(() {
          _scoreGuide = data;
        });
      }
    } catch (e) {
      debugPrint("Error loading score guide: $e");
    }
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
          color: AppTheme.clinicalWhite,
          child: Column(
            children: [
              Text(
                widget.template['title'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.deepLogicViolet,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                instructionText,
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

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
                showWarning:
                    _showValidationErrors && !answers.containsKey(q['id']),
                onChanged: (score) {
                  setState(() {
                    answers[q['id']] = score;
                  });
                },
              );
              if (index == questions.length - 1) {
                final impactData = widget.template['questions_impact'];
                if (impactData != null) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      questionTile, // The last question is still rendered here!
                      _buildImpactSelector(widget.template['questions_impact']),
                      _buildScoreFooter(),
                      const SizedBox(height: 40), // iPhone bottom-area padding
                    ],
                  );
                } else {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      questionTile, // The last question is still rendered here!
                      _buildScoreFooter(),
                      const SizedBox(height: 40), // iPhone bottom-area padding
                    ],
                  );
                }
              }

              // 3. For all other indices, just return the tile
              return questionTile;
            },
          ),
        ),
      ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    // Mimics the paper checkbox/radio look
                    Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: isSelected ? AppTheme.clinicalCyan : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    // The text now has the full width to breathe
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? Colors.black : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
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

  Map<String, String>? getInterpretationOld() {
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
      "action": action,
    };
  }

  Map<String, String>? getInterpretation() {
    // Use the injected logic if available, otherwise fallback to basic total
    if (widget.logic != null) {
      return widget.logic!.interpret(answers, _scoreGuide);
    }

    // Generic fallback if no logic is injected
    return {
      "summary": "Total Score: $totalScore",
      "action": "Consult clinical manual for interpretation.",
    };
  }

  Future<void> _submitAssessment() async {
    // Convert our internal int answers to the String format required by the DB
    final Map<String, String> stringAnswers = answers.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    try {
      // 1. Call your persistence logic
      await DatabaseManager().saveAssessmentResults(
        assessmentId: widget.assessmentId, // 'phq-9.json'
        patientId: widget.patientUuid, // Ensure this is passed into the widget
        answers: stringAnswers,
        isComplete: true,
      );

      if (mounted) {
        // 2. Visual feedback for the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Assessment saved successfully")),
        );

        // 3. Return 'true' so the calling screen knows to refresh the icons/maps
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving assessment: $e")));
      }
    }
  }

  Widget _buildScoreFooter() {
    final questions = widget.template['questions_score'] as List;

    final bool isFormComplete = widget.logic!.isComplete(answers);

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
            if (interpretation['action'] != null &&
                interpretation['action']!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "Recommended Action: ${interpretation['action']}",
                style: const TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
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

                // Get the total expected count from your template
                final int totalExpected = (widget.template['questions_score'] as List).length;
                final int currentAnswered = answers.length;

                String message;
                if (currentAnswered < totalExpected) {
                  // Generic: "Please answer all 10 questions."
                  message = "Please answer all $totalExpected questions before finalizing.";
                } else {
                  // This handles the "Impact" question or any secondary requirements
                  message = "Please complete the remaining assessment fields.";
                }

                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message))
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

class PCL5Logic implements AssessmentLogic {
  @override
  bool isComplete(Map<String, int> answers) {
    // PCL-5 has 20 questions
    return answers.length == 20;
  }

  @override
  Map<String, String>? interpret(Map<String, int> answers, List<dynamic>? scoreGuide) {
    int totalScore = answers.values.fold(0, (sum, val) => sum + val);

    // Common clinical cutoff is 33
    bool isElevated = totalScore >= 33;

    String summary = "Total Severity Score: $totalScore/80. ";
    if (isElevated) {
      summary += "Results suggest clinically significant PTSD symptoms.";
    } else {
      summary += "Results are below the typical clinical threshold for PTSD.";
    }

    return {
      "summary": summary,
      "action": isElevated
          ? "Further clinical evaluation for PTSD is recommended."
          : "Continue to monitor symptoms."
    };
  }

  @override
  String getValidationMessage(Map<String, int> answers) {
    int remaining = 20 - answers.length;
    return "Please complete the remaining $remaining questions for the PCL-5.";
  }
}