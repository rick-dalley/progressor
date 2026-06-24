// AssessmentLogic
// abstract base class for classes calculating scores

class AssessmentAnswer {
  int value = 0;
  String text = "";
  bool isBoolText = false;

  AssessmentAnswer(this.value, this.text, this.isBoolText);

  AssessmentAnswer.fromRawString(String rawAnswer) {
    isBoolText = rawAnswer.contains('|');
    if (isBoolText) {
      final parts = rawAnswer.split('|');
      final String firstPart = parts[0].trim().toLowerCase();
      // Safely handle stringified booleans ('true'/'false') or numbers
      if (firstPart == 'true' || firstPart == 'false') {
        value = 0;
      } else {
        value = int.tryParse(firstPart) ?? 0;
      }

      // Join the remaining narrative string slice back together
      text = parts.sublist(1).join('|');
    } else {
      final String cleanAnswer = rawAnswer.trim().toLowerCase();

      if (cleanAnswer == 'true' || cleanAnswer == 'false') {
        value = 0;
      } else {
        value = int.tryParse(cleanAnswer) ?? 0;
      }
      text = "";
    }
  }

  factory AssessmentAnswer.fromInstance(AssessmentAnswer other) {
    return AssessmentAnswer(other.value, other.text, other.isBoolText);
  }

  factory AssessmentAnswer.fromDynamic(dynamic dynamicAnswer) {
    if (dynamicAnswer is AssessmentAnswer) {
      return AssessmentAnswer.fromInstance(dynamicAnswer);
    }
    return AssessmentAnswer.fromRawString(dynamicAnswer?.toString() ?? "0");
  }

  String asString() {
    if (isBoolText) {
      return '$value|$text';
    } else {
      return '$value';
    }
  }
}

typedef AssessmentAnswerMap = Map<String, AssessmentAnswer>;

abstract class AssessmentLogic {
  /// Logic to determine if the specific requirements of the form are met.
  bool isComplete(AssessmentAnswerMap answers, [List<dynamic>? questions]);
  bool isVisible(String questionId, AssessmentAnswerMap answers) => true;

  /// Logic to calculate and interpret the results.
  Map<String, String>? interpret(AssessmentAnswerMap answers, List<dynamic>? scoreGuide);

  /// Optional: Get a specific error message if validation fails.
  String getValidationMessage(AssessmentAnswerMap answers) => "Please complete all required fields.";
}

class PHQ9Logic implements AssessmentLogic {
  @override
  bool isComplete(AssessmentAnswerMap answers, [List<dynamic>? questions]) {
    // 1. Check clinical questions (q1-q9)
    for (int i = 1; i <= 9; i++) {
      if (!answers.containsKey('q$i')) return false;
    }

    // 2. Check if ANY of the potential impact IDs exist
    final impactIds = ['q10', 'q11', 'q12', 'q13'];
    bool impactAnswered = answers.keys.any((key) => impactIds.contains(key));

    return impactAnswered;
  }

  @override
  Map<String, String>? interpret(AssessmentAnswerMap answers, List<dynamic>? scoreGuide) {
    // 1. Calculate high frequency (threshold >= 2)
    int highFreqCount = 0;
    bool q1OrQ2HighFreq = false;

    // We assume the IDs are q1, q2... as defined in your JSON
    answers.forEach((id, ans) {
      if (ans.value >= 2) {
        if (id != 'q10') highFreqCount++; // Exclude the impact question from the count
        if (id == 'q1' || id == 'q2') q1OrQ2HighFreq = true;
      }
    });

    // 2. Syndrome Logic
    String syndrome = "No specific depressive syndrome suggested.";
    if (q1OrQ2HighFreq) {
      if (highFreqCount >= 5) {
        syndrome = "Major Depressive Disorder suggested.";
      } else if (highFreqCount >= 2) {
        syndrome = "Other Depressive Syndrome suggested.";
      }
    }

    // 3. Score Guide Lookup
    int totalScore = answers.values.fold(0, (sum, val) => sum + val.value);
    String severity = "Unknown";
    String action = "No action defined.";

    if (scoreGuide != null) {
      for (var entry in scoreGuide) {
        if (totalScore <= entry['max_score']) {
          severity = entry['severity'];
          action = entry['action'];
          break;
        }
      }
    }

    return {"summary": "$syndrome Severity: $severity (Score: $totalScore).", "action": action};
  }

  @override
  String getValidationMessage(AssessmentAnswerMap answers) {
    // You can actually use this to be helpful!
    if (answers.length < 9) return "Please answer all 9 clinical questions.";
    if (!answers.containsKey('q10')) return "Please select the impact of these symptoms.";
    return "Please complete the assessment.";
  }

  @override
  bool isVisible(String questionId, AssessmentAnswerMap answers) {
    return true;
  }
}

class GAD7Logic implements AssessmentLogic {
  @override
  bool isVisible(String questionId, AssessmentAnswerMap answers) {
    return true;
  }

  @override
  Map<String, String>? interpret(AssessmentAnswerMap answers, List<dynamic>? scoreGuide) {
    // 1. Calculate Total Score (Sum of q1 through q7)
    // Note: We ignore the impact question (often q8) for the total score.
    int totalScore = 0;
    answers.forEach((id, ans) {
      if (id.startsWith('q') && id != 'q8') {
        totalScore += ans.value;
      }
    });

    String severity = "Unknown";
    String action = "No action defined.";

    // 2. Standard Threshold Lookup
    if (scoreGuide != null) {
      for (var entry in scoreGuide) {
        if (totalScore <= entry['max_score']) {
          severity = entry['severity'];
          action = entry['action'];
          break;
        }
      }
    }

    return {"summary": "Anxiety Severity: $severity (Total Score: $totalScore).", "action": action};
  }

  @override
  String getValidationMessage(AssessmentAnswerMap answers) {
    return "";
  }

  @override
  bool isComplete(AssessmentAnswerMap answers, [List<dynamic>? questions]) {
    return true;
  }
}

class DAST10Logic implements AssessmentLogic {
  @override
  bool isComplete(AssessmentAnswerMap answers, [List<dynamic>? questions]) {
    // DAST-10 is simple: all 10 questions must be answered.
    return answers.length == 10;
  }

  @override
  bool isVisible(String questionId, AssessmentAnswerMap answers) {
    return true;
  }

  @override
  Map<String, String>? interpret(AssessmentAnswerMap answers, List<dynamic>? scoreGuide) {
    int totalScore = 0;

    answers.forEach((id, answer) {
      // Question 3 is a "reverse" question in the standard DAST-10
      if (id == 'q3') {
        // If they answered 'No' (0), they get a point. If 'Yes' (1), they don't.
        if (answer.value == 0) totalScore += 1;
      } else {
        // Standard tally: Yes (1) = 1 point
        if (answer.value == 1) totalScore += 1;
      }
    });

    String severity = "Unknown";
    String action = "No action defined.";

    if (scoreGuide != null) {
      for (var entry in scoreGuide) {
        if (totalScore <= entry['max_score']) {
          severity = entry['severity'];
          action = entry['action'] ?? "";
          break;
        }
      }
    }

    return {
      "summary": "Degree of Problems Related to Drug Use: $severity",
      "score": "Score: $totalScore/10",
      "action": action,
    };
  }

  @override
  String getValidationMessage(AssessmentAnswerMap answers) {
    return "";
  }
}

class ASRS11Logic implements AssessmentLogic {
  @override
  bool isComplete(AssessmentAnswerMap answers, [List<dynamic>? questions]) {
    // ASRS v1.1 has 18 questions total
    return answers.length == 18;
  }

  @override
  bool isVisible(String questionId, AssessmentAnswerMap answers) {
    return true;
  }

  @override
  Map<String, String>? interpret(AssessmentAnswerMap answers, List<dynamic>? scoreGuide) {
    int partAScore = 0;

    // Thresholds: For some questions, 'Sometimes' (2) is a hit.
    // For others, only 'Often' (3) and 'Very Often' (4) count.

    // Part A thresholds
    if ((answers['q1']?.value ?? 0) >= 2) partAScore++;
    if ((answers['q2']?.value ?? 0) >= 2) partAScore++;
    if ((answers['q3']?.value ?? 0) >= 2) partAScore++;
    if ((answers['q4']?.value ?? 0) >= 3) partAScore++;
    if ((answers['q5']?.value ?? 0) >= 3) partAScore++;
    if ((answers['q6']?.value ?? 0) >= 3) partAScore++;

    String summary = "Part A Score: $partAScore/6. ";
    String action = "";

    if (partAScore >= 4) {
      summary += "Symptoms highly consistent with ADHD in adults.";
      action = "Further investigation by a clinician is recommended.";
    } else {
      summary += "Symptoms not highly consistent with ADHD.";
      action = "Monitor symptoms; further evaluation if clinical suspicion remains.";
    }

    return {"summary": summary, "action": action};
  }

  @override
  String getValidationMessage(AssessmentAnswerMap answers) {
    return "Please complete all 18 questions for a full ASRS profile.";
  }
}

class PCL5Logic implements AssessmentLogic {
  @override
  bool isComplete(AssessmentAnswerMap answers, [List<dynamic>? questions]) {
    // PCL-5 has 20 questions
    return answers.length == 20;
  }

  @override
  bool isVisible(String questionId, AssessmentAnswerMap answers) {
    return true;
  }

  @override
  Map<String, String>? interpret(AssessmentAnswerMap answers, List<dynamic>? scoreGuide) {
    int totalScore = answers.values.fold(0, (sum, val) => sum + val.value);

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
      "action": isElevated ? "Further clinical evaluation for PTSD is recommended." : "Continue to monitor symptoms.",
    };
  }

  @override
  String getValidationMessage(AssessmentAnswerMap answers) {
    int remaining = 20 - answers.length;
    return "Please complete the remaining $remaining questions for the PCL-5.";
  }
}

class CSSRSLogic implements AssessmentLogic {
  @override
  bool isVisible(String id, AssessmentAnswerMap answers) {
    final int q1 = answers['q1']?.value ?? 0;
    final int q2 = answers['q2']?.value ?? 0;

    // Instruction: "If 2 is 'yes', ask 3-5"
    if (['q3', 'q4', 'q5'].contains(id)) {
      return q2 == 1;
    }

    // Instruction: "If 1 or 2 is 'yes', complete 'Intensity'"
    // In your JSON, this includes 'intensity_freq'
    if (id.startsWith('intensity_')) {
      return (q1 == 1 || q2 == 1);
    }

    // Specific logic for Potential Lethality (Only if Actual=0)
    if (id == 'potential_lethality') {
      return answers.containsKey('actual_lethality') && answers['actual_lethality']?.value == 0;
    }

    return true;
  }

  @override
  bool isComplete(AssessmentAnswerMap answers, [List<dynamic>? questions]) {
    if (questions == null || questions.isEmpty) return false;
    for (var q in questions) {
      final String id = q['id'];

      // The logic dictates requirement: if it's visible, it MUST be answered.
      if (isVisible(id, answers)) {
        if (!answers.containsKey(id)) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Map<String, String>? interpret(AssessmentAnswerMap answers, List<dynamic>? scoreGuide) {
    // Find the highest 'Yes' answer in the screening section
    int highestSeverity = 0;
    for (int i = 5; i >= 1; i--) {
      if (answers['asrs_q$i']?.value == 1) {
        highestSeverity = i;
        break;
      }
    }

    String summary = "Highest Ideation Severity: Level $highestSeverity. ";
    String action = "Routine monitoring.";

    if (highestSeverity >= 4) {
      action = "IMMEDIATE REFERRAL: High risk ideation with intent/plan.";
    } else if (highestSeverity > 0) {
      action = "Consider mental health consultation.";
    }

    return {"summary": summary, "action": action};
  }

  @override
  String getValidationMessage(AssessmentAnswerMap answers) {
    return "";
  }
}
