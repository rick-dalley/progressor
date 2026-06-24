// Toxidrome Flags
enum SymptomFlag {
  none,
  salivation,
  lacrimation,
  urination,
  defecation,
  emesis,
  hyperactive,
  hypoactive,
  hyperactiveBowels,
  hypoactiveBowels,
  bronchospasm,
  bronchorrhea,
  bradycardia,
  anhidrosis,
  diaphoresis,
  piloerection,
  flushing,
  mydriasis,
  miosis,
  delirium,
  hallucination,
  hyperthermia,
  urinaryRetention,
  tachycardia,
  unconscious,
  anuria,
  oliguria,
  publicSafety,
  privateSafety,
  fasciculation,
  disappearance,
  suicideNote,
  accessToMeans,
  attempted,
  attempting,
  discovered,
  selfHarmedWithIntention,
  selfHarmingWithIntention,
  researched,
  riskyBehaviour,
  mentioned,
  feeling,
  anhedonia,
  avolition,
}

extension SymptomFlagState on SymptomFlag {
  // Convert Enum to String for JSON
  String toValue() => name;

  // Convert String from JSON to Enum
  static SymptomFlag fromValue(String value) {
    return SymptomFlag.values.firstWhere((e) => e.name == value, orElse: () => SymptomFlag.none);
  }
}
