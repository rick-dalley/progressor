abstract class AssessmentLogic {
  /// Logic to determine if the specific requirements of the form are met.
  bool isComplete(Map<String, int> answers);

  /// Logic to calculate and interpret the results.
  Map<String, String>? interpret(Map<String, int> answers, List<dynamic>? scoreGuide);

  /// Optional: Get a specific error message if validation fails.
  String getValidationMessage(Map<String, int> answers) => "Please complete all required fields.";
}

class PHQ9Logic implements AssessmentLogic {

  @override
  bool isComplete(Map<String, int> answers) {
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
  Map<String, String>? interpret(Map<String, int> answers, List<dynamic>? scoreGuide) {
    // 1. Calculate high frequency (threshold >= 2)
    int highFreqCount = 0;
    bool q1OrQ2HighFreq = false;

    // We assume the IDs are q1, q2... as defined in your JSON
    answers.forEach((id, score) {
      if (score >= 2) {
        if (id != 'q10') highFreqCount++; // Exclude the impact question from the count
        if (id == 'q1' || id == 'q2') q1OrQ2HighFreq = true;
      }
    });

    // 2. Syndrome Logic
    String syndrome = "No specific depressive syndrome suggested.";
    if (q1OrQ2HighFreq) {
      if (highFreqCount >= 5) {
        syndrome = "Major Depressive Disorder suggested.";
      }
      else if (highFreqCount >= 2) {
        syndrome = "Other Depressive Syndrome suggested.";
      }
    }

    // 3. Score Guide Lookup
    int totalScore = answers.values.fold(0, (sum, val) => sum + val);
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

    return {
      "summary": "$syndrome Severity: $severity (Score: $totalScore).",
      "action": action
    };
  }

  @override
  String getValidationMessage(Map<String, int> answers) {
    // You can actually use this to be helpful!
    if (answers.length < 9) return "Please answer all 9 clinical questions.";
    if (!answers.containsKey('q10')) return "Please select the impact of these symptoms.";
    return "Please complete the assessment.";
  }
}

class GAD7Logic implements AssessmentLogic{
  @override
  Map<String, String>? interpret(Map<String, int> answers, List<dynamic>? scoreGuide) {
    // 1. Calculate Total Score (Sum of q1 through q7)
    // Note: We ignore the impact question (often q8) for the total score.
    int totalScore = 0;
    answers.forEach((id, value) {
      if (id.startsWith('q') && id != 'q8') {
        totalScore += value;
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

    return {
      "summary": "Anxiety Severity: $severity (Total Score: $totalScore).",
      "action": action
    };
  }

  @override
  String getValidationMessage(Map<String, int> answers) {
    return "";
  }

  @override
  bool isComplete(Map<String, int> answers) {
    return true;
  }
}

class DAST10Logic implements AssessmentLogic {

  @override
  bool isComplete(Map<String, int> answers) {
    // DAST-10 is simple: all 10 questions must be answered.
    return answers.length == 10;
  }

  @override
  Map<String, String>? interpret(Map<String, int> answers, List<dynamic>? scoreGuide) {
    int totalScore = 0;

    answers.forEach((id, value) {
      // Question 3 is a "reverse" question in the standard DAST-10
      if (id == 'q3') {
        // If they answered 'No' (0), they get a point. If 'Yes' (1), they don't.
        if (value == 0) totalScore += 1;
      } else {
        // Standard tally: Yes (1) = 1 point
        if (value == 1) totalScore += 1;
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
      "action": action
    };
  }

  @override
  String getValidationMessage(Map<String, int> answers) {
    return "";
  }
}

class ASRS11Logic implements AssessmentLogic {
  @override
  bool isComplete(Map<String, int> answers) {
    // ASRS v1.1 has 18 questions total
    return answers.length == 18;
  }

  @override
  Map<String, String>? interpret(Map<String, int> answers, List<dynamic>? scoreGuide) {
    int partAScore = 0;

    // Thresholds: For some questions, 'Sometimes' (2) is a hit.
    // For others, only 'Often' (3) and 'Very Often' (4) count.

    // Part A thresholds
    if ((answers['q1'] ?? 0) >= 2) partAScore++;
    if ((answers['q2'] ?? 0) >= 2) partAScore++;
    if ((answers['q3'] ?? 0) >= 2) partAScore++;
    if ((answers['q4'] ?? 0) >= 3) partAScore++;
    if ((answers['q5'] ?? 0) >= 3) partAScore++;
    if ((answers['q6'] ?? 0) >= 3) partAScore++;

    String summary = "Part A Score: $partAScore/6. ";
    String action = "";

    if (partAScore >= 4) {
      summary += "Symptoms highly consistent with ADHD in adults.";
      action = "Further investigation by a clinician is recommended.";
    } else {
      summary += "Symptoms not highly consistent with ADHD.";
      action = "Monitor symptoms; further evaluation if clinical suspicion remains.";
    }

    return {
      "summary": summary,
      "action": action,
    };
  }

  @override
  String getValidationMessage(Map<String, int> answers) {
    return "Please complete all 18 questions for a full ASRS profile.";
  }
}