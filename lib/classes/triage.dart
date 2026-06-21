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
        return "Minor pain, annoying; may have occasional sharp twinges.";
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

enum AssessmentType { toxidrome, psychosis, suicide, missing, breathing, bleeding, consciousness, systemic, esi }

extension MapToRoot on AssessmentType {
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
      case AssessmentType.esi:
        return "esi_root";
    }
  }
}

extension RequiresData on AssessmentType {
  bool get needsData {
    switch (this) {
      case AssessmentType.toxidrome:
        return false;
      case AssessmentType.psychosis:
        return false;
      case AssessmentType.suicide:
        return false;
      case AssessmentType.missing:
        return false;
      case AssessmentType.breathing:
        return true;
      case AssessmentType.bleeding:
        return true;
      case AssessmentType.consciousness:
        return true;
      case AssessmentType.systemic:
        return true;
      case AssessmentType.esi:
        return true;
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

Map<String, String> answers = {
  ".ptrn": "The symptoms follow a pattern",
  ".cnst": "The pain is constant",
  ".h": "An hour ago",
  ".h?": "? hours ago",
  ".m": "a minute ago",
  ".m?": "? minutes ago",
  ".nbr": "not breathing",
  ".np": "no pulse",
  ".wp": "weak pulse",
  ".hr?": "pluse rate is ?",
  ".rr?": "respiratory rate is ?",
  ".bp??": "blood pressure is ? over ?",
  ".t?": "temperature is ?",
  ".unc": "unconscious",
  ".pin": "pinpoint pupils",
  ".dil": "dilated pupils",
  ".sa": "suicide attempt",
  ".pn?": "pain severity is ?",
  ".stom": "pain is in my stomach",
  ".chst": "pain is in my chest",
  ".fnt": "fainted",
  ".syn": "syncope",
  ".del": "delirium",
  ".lth": "lethargic, the patient is drowsy but easily roused",
  ".ob": "obtunded, the patient is in a deeper sleep and needs a loud voice or shake to rouse them",
  "st": "stupor. the patient is unresponsive",
  "cm": "the patient is unconscious and cannot be roused",
};

Map<String, SuggestedQuestion> suggestedQuestions = {
  ".ptrn": SuggestedQuestion(oldCarts: OldCarts.timing, text: "Does the symptom follow a pattern?"),
  ".recr": SuggestedQuestion(
    oldCarts: OldCarts.timing,
    text: " Is it constant (always present) or intermittent (comes and goes)?",
  ),
  ".when": SuggestedQuestion(oldCarts: OldCarts.onset, text: "When did the symptoms start?"),
  ".hs": SuggestedQuestion(oldCarts: OldCarts.onset, text: "Was it sudden or gradual?"),
  ".loc": SuggestedQuestion(oldCarts: OldCarts.location, text: "Where does it hurt?"),
  ".locx": SuggestedQuestion(oldCarts: OldCarts.location, text: "Where exactly is the symptom located?"),
  ".lspr": SuggestedQuestion(oldCarts: OldCarts.location, text: "Does it spread to anywhere else?"),

  ".dur": SuggestedQuestion(oldCarts: OldCarts.duration, text: "How long have you been experiencing these symptoms?"),
  ".last": SuggestedQuestion(oldCarts: OldCarts.duration, text: "Does it last seconds, minutes, or hours?"),
  ".desc": SuggestedQuestion(
    oldCarts: OldCarts.characteristic,
    text: "How does the patient describe the feeling? (e.g., sharp, dull, aching, throbbing, burning)",
  ),
  ".breth": SuggestedQuestion(
    oldCarts: OldCarts.severity,
    text: "Are you experiencing any difficulty breathing, shortness of breath, or chest pain?",
  ),
  ".diz": SuggestedQuestion(
    oldCarts: OldCarts.severity,
    text: "Have you fainted, felt severely dizzy, or lost consciousness?",
  ),
  ".ewrs": SuggestedQuestion(
    oldCarts: OldCarts.aggravator,
    text: "What activities or environments make the symptom worse? ",
  ),
  ".trd": SuggestedQuestion(
    oldCarts: OldCarts.reliever,
    text: "Have you tried any medications, treatments, or positions that provided relief?",
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
