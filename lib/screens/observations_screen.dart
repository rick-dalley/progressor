import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../classes/assessment_logic.dart';
import '../classes/database_manager.dart';
import '../generated/l10n.dart';
import '../widgets/likert_question.dart';

class QuestionnaireSelectorScreen extends StatefulWidget {
  final String assessmentId;
  final String patientUuid;
  final bool isReadOnly;
  final String? scoreGuidePath;
  final Map<String, dynamic> template;
  final AssessmentLogic? logic;
  final ScrollController? scrollController;

  const QuestionnaireSelectorScreen({
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
  QuestionnaireSelectorScreenState createState() => QuestionnaireSelectorScreenState();
}

class QuestionnaireSelectorScreenState extends State<QuestionnaireSelectorScreen> {
  Map<String, AssessmentAnswer> answers = {};
  String? selectedImpactId;

  int get totalScore => answers.values.fold(0, (sum, val) => sum + val.value);
  bool _showValidationErrors = false;
  bool _isLoading = true;
  List<dynamic>? _scoreGuide;

  Future<void> _loadAnswers() async {
    final Map<String, String>? rawResults = await DatabaseManager().getLatestAssessmentResults(
      assessmentId: widget.assessmentId,
      patientId: widget.patientUuid,
    );

    //Initialize as a Map matching your new state definition
    Map<String, AssessmentAnswer> initialAnswers = {};

    if (rawResults != null) {
      initialAnswers = rawResults.map((key, value) {
        // Pass the raw string row straight to your clean parser constructor
        return MapEntry(key, AssessmentAnswer.fromRawString(value));
      });
    }

    if (mounted) {
      setState(() {
        answers = initialAnswers;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadScoreGuide() async {
    // Only attempt to load if a path was provided
    if (widget.scoreGuidePath == null) return;

    try {
      final String response = await rootBundle.loadString(widget.scoreGuidePath!);
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
    _loadAnswers();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final String instructionText = widget.template['column_headers'][0];
    final List questions = widget.template['questions_score'];
    final bool isFormComplete = widget.logic!.isComplete(answers, questions);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: _buildActionButton(isFormComplete),
        ),
      ),
      body: SafeArea(child: Column(children: [_buildHeader(instructionText), _buildQuestions(questions)])),
    );
  }

  Widget _buildActionButton(bool isFormComplete) {
    if (widget.isReadOnly) {
      return ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Close Review"));
    } else {
      return ElevatedButton(
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

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          } else {
            _submitAssessment();
          }
        },
        child: const Text("Finalize & Map to DSM"),
      );
    }
  }

  Widget _buildHeader(String instructionText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      color: AppTheme.clinicalWhite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Shrink-wrap header content cleanly
        children: [
          Text(
            widget.template['title'],
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.deepLogicViolet, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(
            instructionText,
            style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestions(List questions) {
    return Expanded(
      child: ListView.builder(
        // Crucial: This links the list scroll directly to the sheet thumb pull down
        controller: widget.scrollController,
        padding: const EdgeInsets.all(16.0),
        // Padding moved inside the list viewport
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];
          bool visible = widget.logic?.isVisible(q["id"], answers) ?? true;
          final qId = q['id'];
          Widget questionTile = visible
              ? LikertQuestionTile(
                  q: q as Map<String, dynamic>,
                  template: widget.template,
                  currentAnswer: answers[qId],
                  showWarning: _showValidationErrors && !answers.containsKey(qId),
                  onChanged: widget.isReadOnly
                      ? null
                      : (score) {
                          setState(() {
                            final existingText = answers[qId]?.text ?? "";
                            final isBoolText = existingText.contains("|");
                            answers[qId] = AssessmentAnswer(score, existingText, isBoolText);
                          });
                        },
                  onDescriptionChanged: widget.isReadOnly
                      ? null
                      : (id, description) {
                          setState(() {
                            final existingValue = answers[qId]?.value ?? 0;
                            //Break the reference cache for text changes too
                            answers[qId] = AssessmentAnswer(existingValue, description, true);
                          });
                        },
                )
              : const SizedBox.shrink();

          // If it's the last question in the layout loop, append the footers
          if (index == questions.length - 1) {
            final impactData = widget.template['questions_impact'];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                questionTile,
                if (impactData != null) _buildImpactSelector(impactData),
                _buildScoreFooter(),
                // Your scoring interpretation message renders here safely
                const SizedBox(height: 40),
              ],
            );
          }

          return questionTile;
        },
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
                  answers[id]?.value = 0;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    // Mimics the paper checkbox/radio look
                    Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
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
    // Use the injected logic if available, otherwise fallback to basic total
    if (widget.logic != null) {
      return widget.logic!.interpret(answers, _scoreGuide);
    }

    // Generic fallback if no logic is injected
    return {"summary": "Total Score: $totalScore", "action": "Consult clinical manual for interpretation."};
  }

  Future<void> _submitAssessment() async {
    // Convert our internal int answers to the String format required by the DB
    final Map<String, String> stringAnswers = answers.map((key, value) => MapEntry(key, value.asString()));

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Assessment saved successfully")));

        // 3. Return 'true' so the calling screen knows to refresh the icons/maps
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving assessment: $e")));
      }
    }
  }

  Widget _buildScoreFooter() {
    final questions = widget.template['questions_score'] as List;

    final bool isFormComplete = widget.logic!.isComplete(answers, questions);

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
            if (interpretation['action'] != null && interpretation['action']!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "Recommended Action: ${interpretation['action']}",
                style: const TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
          ],

          Text("Current Score: $totalScore", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
