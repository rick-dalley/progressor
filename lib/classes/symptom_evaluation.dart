import 'package:triage/classes/patient_sentiment.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:triage/classes/symptom_flag.dart';

enum Hypothesis {
  cholinergic,
  opioids,
  sympathomimetic,
  anticholinergic,
  hallucinogenic,
  sedativeHypnotics,
  psychoticBreak,
  suicide,
  nicotinePoisoning,
  alcoholPoisoning,
  none,
  unknown,
}

enum TriggerDirection { isGreaterThan, isLessThan, none }

class Symptom {
  final SymptomFlag symptomFlag;
  final Sentiment sentiment;
  final String name;
  final String description;
  final double triggerPoint;
  final String uom;
  final TriggerDirection triggerIf;
  final bool checkTrigger;
  final List<String> descriptors;
  Symptom({
    required this.symptomFlag,
    required this.sentiment,
    required this.name,
    required this.description,
    required this.triggerIf,
    required this.triggerPoint,
    required this.uom,
    required this.checkTrigger,
    required this.descriptors,
  });

  factory Symptom.fromMap(Map<String, dynamic> item) {
    int itemSymptomFlag = item["symptom_flag"] ?? 0;
    int itemSentiment = item["sentiment"] ?? 0;
    String itemSymptomName = item["name"];
    String itemDescription = item["description"];
    num itemLowerBound = item["trigger_point"] ?? 0;
    int itemTriggerIf = item["trigger_if"] ?? 0;
    String itemUom = item["trigger_uom"];
    bool itemCheckTrigger = item["trigger_check"];
    List<String> itemDescriptors = item["keywords"];

    return Symptom(
      symptomFlag: SymptomFlag.values[itemSymptomFlag],
      sentiment: Sentiment.values[itemSentiment],
      name: itemSymptomName,
      description: itemDescription,
      triggerPoint: itemLowerBound.toDouble(),
      triggerIf: itemTriggerIf > 0
          ? TriggerDirection.isGreaterThan
          : itemTriggerIf < 0
          ? TriggerDirection.isLessThan
          : TriggerDirection.none,
      uom: itemUom,
      checkTrigger: itemCheckTrigger,
      descriptors: itemDescriptors,
    );
  }

  bool isTriggeredBy(double value) {
    switch (triggerIf) {
      case TriggerDirection.isGreaterThan:
        return value >= triggerPoint;
      case TriggerDirection.isLessThan:
        return value <= triggerPoint;
      case TriggerDirection.none:
        return false;
    }
  }

  bool hasDescriptor(String descriptor) {
    return (descriptors.contains(descriptor));
  }
}

class SymptomFactory {
  // We use a Map for O(1) lookups by SymptomFlag
  static Map<SymptomFlag, Symptom> _registry = {};

  // Load the JSON once from assets
  static Future<void> loadFromAssets(String path) async {
    final String jsonString = await rootBundle.loadString(path);
    final List<dynamic> data = json.decode(jsonString);

    _registry = {for (var item in data) SymptomFlag.values[item["symptom_flag"]]: Symptom.fromMap(item)};
  }

  // Access the registry
  static Symptom? getSymptomByName(String name) {
    SymptomFlag symptomFlag = SymptomFlagState.fromValue(name);
    return _registry[symptomFlag];
  }

  static Symptom? getSymptom(SymptomFlag flag) => _registry[flag];

  static Symptom? findSymptomByDescriptor(String inputDescriptor) {
    String normalizedInput = inputDescriptor.trim().toLowerCase();

    // Look through every registered symptom
    for (var symptom in _registry.values) {
      if (symptom.hasDescriptor(normalizedInput)) {
        return symptom;
      }
    }
    return null; // No match found
  }

  static List<Symptom> get allSymptoms => _registry.values.toList();
}

final Map<Hypothesis, List<SymptomFlag>> symptomRegistry = {
  Hypothesis.cholinergic: [
    SymptomFlag.salivation,
    SymptomFlag.lacrimation,
    SymptomFlag.urination,
    SymptomFlag.defecation,
    SymptomFlag.hyperactiveBowels,
    SymptomFlag.emesis,
  ],
  Hypothesis.opioids: [SymptomFlag.miosis, SymptomFlag.bradycardia, SymptomFlag.unconscious],
  Hypothesis.sympathomimetic: [
    SymptomFlag.delirium,
    SymptomFlag.diaphoresis,
    SymptomFlag.piloerection,
    SymptomFlag.mydriasis,
    SymptomFlag.hyperactiveBowels,
  ],
  Hypothesis.anticholinergic: [],
  Hypothesis.hallucinogenic: [],
  Hypothesis.sedativeHypnotics: [],
  Hypothesis.nicotinePoisoning: [
    SymptomFlag.bronchospasm,
    SymptomFlag.bronchorrhea,
    SymptomFlag.bradycardia,
    SymptomFlag.fasciculation,
    SymptomFlag.miosis,
  ],
  Hypothesis.suicide: [
    SymptomFlag.disappearance,
    SymptomFlag.suicideNote,
    SymptomFlag.accessToMeans,
    SymptomFlag.attempted,
    SymptomFlag.attempting,
    SymptomFlag.discovered,
    SymptomFlag.selfHarmedWithIntention,
    SymptomFlag.selfHarmingWithIntention,
    SymptomFlag.researched,
    SymptomFlag.riskyBehaviour,
    SymptomFlag.mentioned,
    SymptomFlag.feeling,
    SymptomFlag.anhedonia,
    SymptomFlag.avolition,
  ],
  Hypothesis.none: [],
  Hypothesis.unknown: [],
};

class HypothesisClassification {
  final Hypothesis hypothesis;
  late int score;
  late List<SymptomFlag> sharedSymptoms;
  HypothesisClassification({required this.hypothesis}) {
    score = 0;
    sharedSymptoms = [];
  }
  bool hasSymptomFromFlag(SymptomFlag symptomFlag) {
    return false;
  }

  bool hasSymptomFromString(String symptomName) {
    return false;
  }

  void addSymptom(SymptomFlag flag) {
    // Check if this symptom is part of the "clinical signature" for this hypothesis
    if (symptomRegistry[hypothesis]!.contains(flag)) {
      if (!sharedSymptoms.contains(flag)) {
        sharedSymptoms.add(flag);
        score += 1; // You can make this a weighted value later
      }
    }
  }

  void addSymptomFromPatientDescription(String symptomDescription) {
    Symptom? symptom = SymptomFactory.findSymptomByDescriptor(symptomDescription);
    if (symptom != null) {
      sharedSymptoms.add(symptom.symptomFlag);
      score += 1;
    }
  }
}

class EvaluateSymptoms {
  double hr = 0.0;
  int sys = 0;
  int dia = 0;
  double spO2 = 0.0;
  double temp = 0.0;
  int rr = 0;

  EvaluateSymptoms();

  List<HypothesisClassification> hypotheses = Hypothesis.values
      .map((h) => HypothesisClassification(hypothesis: h))
      .toList();

  List<HypothesisClassification> hypothesesFromNewSymptom(String input) {
    // 1. Try to find the flag via exact name match or via descriptor keyword search
    Symptom? symptom = SymptomFactory.getSymptomByName(input) ?? SymptomFactory.findSymptomByDescriptor(input);

    // If no match exists in the registry, return current list
    if (symptom == null || symptom.symptomFlag == SymptomFlag.none) {
      return hypotheses;
    }

    SymptomFlag flag = symptom.symptomFlag;

    // 2. Update hypotheses
    for (var h in hypotheses) {
      h.addSymptom(flag);
    }

    // 3. Sort by score descending
    hypotheses.sort((a, b) => b.score.compareTo(a.score));
    return hypotheses;
  }
}
