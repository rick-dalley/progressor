import 'date_time_utilities.dart';

enum IdeationFlag{selfHarmedWithIntention, attempted, attempting, discovered, mentioned, feeling, riskyBehaviour, researched, anhedonia, avolition, disappeared, selfHarmingWithIntention}
enum IdeationPhase{ attempting, planning, ideating, recovery}
enum RiskLevel { imminent, high, likely, possible, low }

class SuicideRiskAssessmentResult {
  final RiskLevel risk;
  final String statusMessage;
  final String safetyInstruction;

  SuicideRiskAssessmentResult(this.risk, this.statusMessage, this.safetyInstruction);
}

class IdeationIndicator{
  final IdeationFlag flag;
  final IdeationPhase phase;
  final String description;
  const IdeationIndicator({required this.flag, required this.description, required this.phase});
}

class ObservedSuicideIndicator {
  IdeationFlag flag;
String?observation;
  ObservedSuicideIndicator({required this.flag, this.observation});

}

Map<IdeationFlag, IdeationIndicator> suicideIndicators = {
  IdeationFlag.attempted:IdeationIndicator(flag: IdeationFlag.attempted, phase: IdeationPhase.attempting, description: "Has attempted suicide at one or more points in the past."),
  IdeationFlag.attempting:IdeationIndicator(flag: IdeationFlag.attempting, phase: IdeationPhase.attempting, description: "Is currently on the way to, or in the process of, committing suicide."),
  IdeationFlag.discovered:IdeationIndicator(flag: IdeationFlag.discovered, phase: IdeationPhase.attempting, description: "THe person has recently been discovered attempting suicide."),
  IdeationFlag.disappeared:IdeationIndicator(flag: IdeationFlag.disappeared, phase: IdeationPhase.attempting, description: "Has left without providing information about their where abouts."),
  IdeationFlag.selfHarmedWithIntention:IdeationIndicator(flag: IdeationFlag.selfHarmedWithIntention, phase: IdeationPhase.attempting, description: "The person had recently hurt themselves with the intention of killing themselves."),
  IdeationFlag.selfHarmingWithIntention:IdeationIndicator(flag: IdeationFlag.selfHarmingWithIntention, phase: IdeationPhase.attempting, description: "Is currently in the process of hurting or physically abusing themselves with the intent of killing themselves."),
  IdeationFlag.researched:IdeationIndicator(flag: IdeationFlag.researched, phase: IdeationPhase.planning, description: "Person has recently researched or is researching ways to kill themselves."),
  IdeationFlag.riskyBehaviour:IdeationIndicator(flag: IdeationFlag.riskyBehaviour, phase: IdeationPhase.planning, description: "The person has recently been taking foolish risks such as driving extremely fast."),
  IdeationFlag.mentioned:IdeationIndicator(flag: IdeationFlag.mentioned, phase: IdeationPhase.planning, description: "The person has recently been discussing suicide or the methods of committing it."),
  IdeationFlag.feeling:IdeationIndicator(flag: IdeationFlag.feeling, phase: IdeationPhase.ideating, description: "The person has been depressed or deeply sad."),
  IdeationFlag.anhedonia:IdeationIndicator(flag: IdeationFlag.anhedonia, phase: IdeationPhase.ideating, description: "Sudden loss of interest in daily activities"),
  IdeationFlag.avolition:IdeationIndicator(flag: IdeationFlag.avolition, phase: IdeationPhase.ideating, description: "Significant decline in self-care and personal hygiene"),

};

class SuicideRiskAssessment{
  final String subject;
  final String reportedBy;
  final bool personalSafety;
  final bool accessToMeans;
  final int reportedOn = DTUtilities.now();
  SuicideRiskAssessment({required this.subject, required this.reportedBy, required this.personalSafety, required this.accessToMeans});
  List<ObservedSuicideIndicator> indicators = [];


  void addIndicator({required IdeationFlag flag, String? observation}){
    indicators.add(ObservedSuicideIndicator(flag: flag, observation: observation));
  }

  SuicideRiskAssessmentResult assessment() {
    // 1. Safety & Imminence Checks (Highest Priority)
    bool isAttempting = indicators.any((i) => suicideIndicators[i.flag]!.phase == IdeationPhase.attempting);

    if (personalSafety || accessToMeans && isAttempting) {
      return SuicideRiskAssessmentResult(
          RiskLevel.imminent,
          "IMMINENT RISK: Active attempt or immediate threat detected.",
          "Secure the scene and remove all lethal means. Do not leave the subject alone. Call for emergency medical support immediately."
      );
    }

    // 2. High Risk (Planning + Means)
    bool isPlanning = indicators.any((i) => suicideIndicators[i.flag]!.phase == IdeationPhase.planning);

    if (isPlanning && accessToMeans) {
      return SuicideRiskAssessmentResult(
          RiskLevel.high,
          "HIGH RISK: Subject has a plan and access to lethal means.",
          "Constant supervision is required. Escalate for immediate mental health professional transport."
      );
    }

    // 3. Likely/Possible Based on Phase
    if (isPlanning) {
      return SuicideRiskAssessmentResult(
          RiskLevel.likely,
          "LIKELY RISK: Subject is actively planning.",
          "Remove potential means. Do not leave the subject unattended. Provide support and reassurance."
      );
    }

    bool isIdeating = indicators.any((i) => suicideIndicators[i.flag]!.phase == IdeationPhase.ideating);
    if (isIdeating) {
      return SuicideRiskAssessmentResult(
          RiskLevel.possible,
          "POSSIBLE RISK: Subject is experiencing ideation.",
          "Engage in supportive conversation. Listen actively and assess for escalating symptoms."
      );
    }

    return SuicideRiskAssessmentResult(
        RiskLevel.low,
        "LOW RISK: No immediate clinical indicators identified.",
        "Continue monitoring and provide information on support resources if necessary."
    );
  }

}

