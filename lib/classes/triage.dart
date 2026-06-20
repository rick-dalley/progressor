import 'package:flutter/cupertino.dart';
import 'package:triage/classes/patient_sentiment.dart';

import 'acuity.dart';

enum Severity {
  none,
  mild,
  minor,
  distracting,
  moderate,
  moderatelyStrong,
  difficult,
  strong,
  interfering,
  unbearable,
  debilitating,
}

extension SeveritySymbol on Severity {
  IconData get asIcon {
    switch (this) {
      case Severity.none:
      case Severity.mild:
        return patientSentiments[Sentiment.happy]!.iconData;
      case Severity.minor:
      case Severity.distracting:
        return patientSentiments[Sentiment.content]!.iconData;
      case Severity.moderate:
      case Severity.moderatelyStrong:
      case Severity.difficult:
        return patientSentiments[Sentiment.neutral]!.iconData;
      case Severity.strong:
      case Severity.interfering:
        return patientSentiments[Sentiment.dissatisfied]!.iconData;
      case Severity.unbearable:
      case Severity.debilitating:
        return patientSentiments[Sentiment.stressed]!.iconData;
    }
  }
}

extension SeverityDescription on Severity {
  String get asString {
    switch (this) {
      case Severity.none:
        return "Pain free.";
      case Severity.mild:
        return "Very mild, barely noticeable; you don't think about it most of the time.";
      case Severity.minor:
        return "Minor pain, annoying; may have occasional sharp twinges or twinges.";
      case Severity.distracting:
        return "Noticeable and distracting; however, you can adapt and get used to it.";
      case Severity.moderate:
        return "Moderate pain; you can ignore it for periods of time if deeply involved in an activity, but it is still distracting";
      case Severity.moderatelyStrong:
        return "Moderately strong pain; cannot be ignored for more than a few minutes, but you can still work or socialize with effort";
      case Severity.difficult:
        return "Interferes with normal daily activities; you have difficulty concentrating";
      case Severity.strong:
        return "Strong pain; prevents you from doing normal daily activities";
      case Severity.interfering:
        return "Very strong pain; it is hard to do anything at all";
      case Severity.unbearable:
        return "Very hard to tolerate; you cannot carry on a conversation";
      case Severity.debilitating:
        return "Worst pain possible";
    }
  }
}

enum OldCarts { onset, location, duration, characteristic, aggravator, reliever, timing, severity }

extension OldCartsMapper on OldCarts {
  String get name {
    switch (this) {
      case OldCarts.onset:
        return "Onset";
      case OldCarts.location:
        return "Location";
      case OldCarts.duration:
        return "Duration";
      case OldCarts.characteristic:
        return "Characteristic";
      case OldCarts.aggravator:
        return "Aggravator";
      case OldCarts.reliever:
        return "Reliever";
      case OldCarts.timing:
        return "Timing";
      case OldCarts.severity:
        return "Severity";
    }
  }
}

enum AssessmentType { toxidrome, psychosis, suicide, missing, breathing, bleeding, consciousness, systemic }

extension AssessmentTypeMapper on AssessmentType {
  String get rootNodeId {
    switch (this) {
      case AssessmentType.toxidrome:
        return "toxidrome_root";
      case AssessmentType.psychosis:
        return "psychosis_root";
      case AssessmentType.suicide:
        return "suicide_root";
      case AssessmentType.missing:
        return "missing_root";
      case AssessmentType.breathing:
        return "breathing_root";
      case AssessmentType.bleeding:
        return "hemorrhage_root";
      case AssessmentType.consciousness:
        return "neuro_root";
      case AssessmentType.systemic:
        return "systemic_root";
    }
  }
}

class TriageAssessmentResult {
  final Severity? toxidromeSeverity;
  final Severity? psychosisSeverity;
  final Severity? suicideRiskSeverity;
  final bool isMissingCritical;

  TriageAssessmentResult({
    this.toxidromeSeverity,
    this.psychosisSeverity,
    this.suicideRiskSeverity,
    this.isMissingCritical = false,
  });

  // Calculate the highest common denominator
  AcuityLevel get overallAcuity {
    if (isMissingCritical || suicideRiskSeverity == Severity.unbearable) {
      return AcuityLevel.resuscitation; // Highest level
    }
    if (psychosisSeverity == Severity.unbearable || toxidromeSeverity == Severity.unbearable) {
      return AcuityLevel.urgent;
    }
    return AcuityLevel.notUrgent;
  }
}

class SuggestedQuestion {
  final OldCarts oldCarts;
  final String text;
  SuggestedQuestion({required this.oldCarts, required this.text});
}

class Observation {
  final String question;
  final dynamic answer;
  final DateTime when;
  final OldCarts carts;
  Observation({required this.carts, required this.answer, required this.question}) : when = DateTime.now();
}

class Hypothesis {
  final String name;
  final double threshold;

  Hypothesis({required this.name, required this.threshold});
  // A function that looks at the ledger and returns 0.0 - 1.0
  double calculateProbability(Map<OldCarts, List<Observation>> ledger) {
    // Logic: If ledger[OldCarts.severity] is 'debilitating'
    // AND ledger[OldCarts.location] is 'head', probability is 0.9
    return 0.0;
  }
}

class Triage {
  Map<OldCarts, List<Observation>> ledger = {
    OldCarts.onset: [],
    OldCarts.location: [],
    OldCarts.duration: [],
    OldCarts.characteristic: [],
    OldCarts.aggravator: [],
    OldCarts.reliever: [],
    OldCarts.timing: [],
    OldCarts.severity: [],
  };

  Triage();

  OldCarts _parseQuestionAnswer(String question, dynamic answer) {
    OldCarts parsedCarts = OldCarts.onset;
    return parsedCarts;
  }

  void addObservationFromQA(String question, dynamic answer) {
    OldCarts carts = _parseQuestionAnswer(question, answer);
    ledger[carts]!.add(Observation(carts: carts, answer: answer, question: question));
    // Trigger re-calculation whenever data is added
    _reevaluateAcuity();
  }

  // The "Piling Up" method
  void addObservation(OldCarts carts, String question, dynamic answer) {
    ledger[carts]!.add(Observation(carts: carts, answer: answer, question: question));
    // Trigger re-calculation whenever data is added
    _reevaluateAcuity();
  }

  void _reevaluateAcuity() {
    // This is where your Probability Engine will live
    // 1. Analyze the 'ledger'
    // 2. Update hypothesis probabilities
    // 3. Determine acuity
  }

  // Helper to see what we are missing
  List<OldCarts> get missingCriticalEvidence {
    return ledger.entries.where((e) => e.value.isEmpty).map((e) => e.key).toList();
  }

  AcuityLevel suggestedAcuity() {
    return AcuityLevel.notUrgent;
  }

  List<String> suggestedRemediations() {
    List<String> remediations = [];
    remediations.add("");
    return remediations;
  }
}

class ESIQuestions {
  List<String> questions = [];
  ESIQuestions();
  void addQuestions() {
    questions.add(
      "1. Does the patient need immediate life-saving help?The nurse looks at the patient right away to see if they are dying or need immediate rescue. ",
    );
    questions.add("[1]Questions they ask themselves: ");
    questions.add("Is the airway open? ");
    questions.add("Is the patient breathing? ");
    questions.add("Do they have a pulse? ");
    questions.add("Are they unconscious? ");
    questions.add("[1]Result: If yes, the patient is Level 1 (Resuscitation). ");
    questions.add("[1] This includes people with stopped hearts or severe gunshot wounds.");
    questions.add("2. Is this a high-risk situation?");
    questions.add("If the patient is stable but could get worse very fast, they are looked at next. ");
    questions.add("[1]Questions they ask: Is the patient confused or disoriented? ");
    questions.add("Are they in severe pain? Are they having chest pain that feels like a heart attack? ");
    questions.add("[1]Result: If yes, the patient is Level 2 (Emergent). ");
    questions.add("[1] These patients need to see a doctor within minutes.");
    questions.add("3. How many hospital resources will this patient need?");
    questions.add(
      "For patients who are stable, the nurse counts how many tests or treatments the person will need before going home. ",
    );
    questions.add(
      "[1]Questions they ask: Will this person need blood tests, X-rays, intravenous (IV) fluids, or stitches? ",
    );
    questions.add("[1]Result:Level 3 (Urgent): Needs two or more resources (like blood tests and a CT scan). ");
    questions.add("[1] The nurse will also check their vital signs here. ");
    questions.add("If their heart rate or breathing is too fast, they might move up to Level 2. ");
    questions.add(
      "[1]Level 4 (Less Urgent): Needs only one resource (like a single X-ray for a broken finger, or just stitches). ",
    );
    questions.add(
      "[1]Level 5 (Non-Urgent): Needs no resources (like a prescription refill or a simple rash check). [1]",
    );
  }
}

Map<String, SuggestedQuestion> suggestedQuestions = {
  ".when": SuggestedQuestion(oldCarts: OldCarts.onset, text: "When did the symptoms start?"),
  ".loc": SuggestedQuestion(oldCarts: OldCarts.location, text: "Where does it hurt?"),
  ".dur": SuggestedQuestion(
    oldCarts: OldCarts.duration,
    text: "How long has the subject been experiencing these symptoms?",
  ),
  ".breth": SuggestedQuestion(
    oldCarts: OldCarts.severity,
    text: "Are you experiencing any difficulty breathing, shortness of breath, or chest pain?",
  ),
  ".diz": SuggestedQuestion(
    oldCarts: OldCarts.severity,
    text: "Have you fainted, felt severely dizzy, or lost consciousness?",
  ),
  ".nm": SuggestedQuestion(oldCarts: OldCarts.characteristic, text: "What is the subject's name?"),
  ".pls": SuggestedQuestion(oldCarts: OldCarts.characteristic, text: "Have you checked the pulse?"),
  ".wrs": SuggestedQuestion(oldCarts: OldCarts.aggravator, text: "What makes it feel worse?"),
  ".pn": SuggestedQuestion(oldCarts: OldCarts.characteristic, text: "What kind of pain is it?"),
  ".rad": SuggestedQuestion(
    oldCarts: OldCarts.characteristic,
    text: "Are you having any radiating pain (e.g., to your jaw, back, or arm)?",
  ),
  ".fever": SuggestedQuestion(
    oldCarts: OldCarts.characteristic,
    text: "Have you had a fever? If so, do you know how high it was?",
  ),
  ".naus": SuggestedQuestion(
    oldCarts: OldCarts.characteristic,
    text: "Are you experiencing any unusual sweating, nausea, or vomiting?",
  ),
  ".awar": SuggestedQuestion(
    oldCarts: OldCarts.characteristic,
    text: "Do you know your name, where you are, and today's date?",
  ),
  ".conf": SuggestedQuestion(
    oldCarts: OldCarts.characteristic,
    text:
        "Are you experiencing any sudden confusion, difficulty speaking, or weakness/numbness on one side of the body?",
  ),
  ".ideat": SuggestedQuestion(
    oldCarts: OldCarts.characteristic,
    text: "Are you having any thoughts of harming yourself or others?",
  ),
  ".cond": SuggestedQuestion(
    oldCarts: OldCarts.characteristic,
    text:
        "Do you have any significant medical conditions, such as diabetes, heart disease, asthma, or high blood pressure?",
  ),
  ".meds": SuggestedQuestion(
    oldCarts: OldCarts.characteristic,
    text: "Are you taking any medications right now? If so, for what?",
  ),
  ".allrg": SuggestedQuestion(
    oldCarts: OldCarts.characteristic,
    text: "Do you have any known allergies (especially to medications)?",
  ),
  ".btr": SuggestedQuestion(oldCarts: OldCarts.reliever, text: "Is there anything that makes it feel better?"),
  ".tm": SuggestedQuestion(oldCarts: OldCarts.timing, text: "How frequently do you feel it?"),
  ".sdn": SuggestedQuestion(
    oldCarts: OldCarts.timing,
    text: "Did the symptoms come on suddenly (like a switch) or gradually over time?",
  ),
  ".chng": SuggestedQuestion(
    oldCarts: OldCarts.timing,
    text: "Have the symptoms gotten better, worse, or stayed the same since they started?",
  ),
  ".cad": SuggestedQuestion(oldCarts: OldCarts.timing, text: "Is it constant or does it come in waves?"),
  ".sev": SuggestedQuestion(
    oldCarts: OldCarts.severity,
    text: "On a scale of 1 to 10 where 10 is unbearable how bad is it?",
  ),
  // add more questions from approved sources
  // :
  // :
};
