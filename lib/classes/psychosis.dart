
import 'package:triage/classes/date_time_utilities.dart';

enum PsychosisFlag{hallucinating, delusional, muddled, behaving, withdrawn, avolition, anhedonia, sleepDisruption, paranoia, cannotFocus, inappropriate, severeMood}
enum PsychosisPhase{acute, prodromal, recovery}
enum RiskLevel { high, likely, possible, low }

class AssessmentResult {
  final RiskLevel risk;
  final String statusMessage;
  final String safetyInstruction;

  AssessmentResult(this.risk, this.statusMessage, this.safetyInstruction);
}

class PsychosisIndicator{
  final PsychosisFlag flag;
  final PsychosisPhase level;
  final String description;
  const PsychosisIndicator({required this.flag, required this.description, required this.level});
}

Map<PsychosisFlag, PsychosisIndicator> psychosisIndicators = {
  PsychosisFlag.hallucinating:PsychosisIndicator(flag: PsychosisFlag.hallucinating, level: PsychosisPhase.acute, description: "Experiencing sensory events that others cannot perceive. This most commonly involves hearing voices, but can also include seeing, smelling, or feeling things that do not exist."),
  PsychosisFlag.delusional:PsychosisIndicator(flag: PsychosisFlag.delusional, level: PsychosisPhase.acute, description: " Holding intense, false beliefs that persist despite logical evidence to the contrary. Common examples include paranoia (believing they are being watched or poisoned) or believing they have special, grandiose powers."),
  PsychosisFlag.muddled:PsychosisIndicator(flag: PsychosisFlag.muddled, level: PsychosisPhase.acute, description: "Disorganized Thinking: Muddled thinking that shows up in their speech. They might change topics mid-sentence, speak rapidly, make up words, or produce 'word salad' that is impossible to follow."),
  PsychosisFlag.behaving:PsychosisIndicator(flag: PsychosisFlag.behaving, level: PsychosisPhase.acute, description: " Laughing, crying, or becoming angry for no visible reason, or showing a complete lack of emotional response."),
  PsychosisFlag.withdrawn:PsychosisIndicator(flag: PsychosisFlag.withdrawn, level: PsychosisPhase.prodromal, description: "Severe social withdrawal and sudden isolation from friends or family."),
  PsychosisFlag.avolition:PsychosisIndicator(flag: PsychosisFlag.avolition, level: PsychosisPhase.prodromal, description: "Significant decline in self-care and personal hygiene"),
  PsychosisFlag.anhedonia:PsychosisIndicator(flag: PsychosisFlag.anhedonia, level: PsychosisPhase.prodromal, description: "Sudden loss of interest in daily activities"),
  PsychosisFlag.paranoia:PsychosisIndicator(flag: PsychosisFlag.paranoia, level: PsychosisPhase.prodromal, description: "Sudden disruption in sleep and eating patterns"),
  PsychosisFlag.sleepDisruption:PsychosisIndicator(flag:PsychosisFlag.sleepDisruption , level: PsychosisPhase.prodromal, description: "Extreme, sudden suspiciousness or unprovoked paranoia toward loved ones."),
  PsychosisFlag.cannotFocus:PsychosisIndicator(flag: PsychosisFlag.cannotFocus, level: PsychosisPhase.prodromal, description: "Inability to focus or a sudden drop in job/school performance. Frequent or current absence"),
  PsychosisFlag.inappropriate:PsychosisIndicator(flag: PsychosisFlag.cannotFocus, level: PsychosisPhase.prodromal, description: "Intense focus on ideas that may seem odd or disturbing to others."),
  PsychosisFlag.severeMood:PsychosisIndicator(flag: PsychosisFlag.cannotFocus, level: PsychosisPhase.prodromal, description: "irritability, anxiety, depressed mood.")

};

class ObservedIndicator{
  final PsychosisFlag flag;
  String? observance;
  ObservedIndicator({required this.flag, this.observance});
}

class  PsychosisAssessment{
  final String subject;
  final String? reportedBy;
  final bool personalSafety;
  final bool publicSafety;

  final int reportedOn = DTUtilities.now();
  List<ObservedIndicator> indicators = [];
  PsychosisAssessment({required this.subject, this.reportedBy, required this.personalSafety, required this.publicSafety});

  void addIndicator({required PsychosisFlag flag, String? observance}){
    indicators.add(ObservedIndicator(flag: flag, observance: observance));
  }

  AssessmentResult assessment() {
    final acuteCount = indicators.where((i) => psychosisIndicators[i.flag]!.level == PsychosisPhase.acute).length;
    final prodromalCount = indicators.where((i) => psychosisIndicators[i.flag]!.level == PsychosisPhase.prodromal).length;

    // Safety Override Logic
    if (personalSafety || publicSafety) {
      return AssessmentResult(
          RiskLevel.high,
          "Safety Alert: Personal or public safety is compromised. Prioritize scene stabilization.",
          "Immediate intervention required. Maintain distance, utilize de-escalation tactics, and prioritize containment until additional resources arrive."
      );
    }

    // Clinical Logic
    if (acuteCount >= 1) {
      return AssessmentResult(
          RiskLevel.high,
          "High probability of acute psychotic episode. Immediate professional assessment required.",
          "Stay calm and non-confrontational. Validate their emotions, not their delusions: 'I hear that you are scared.'"
      );
    } else if (prodromalCount >= 2) {
      return AssessmentResult(
          RiskLevel.likely,
          "Likely early-stage psychotic symptoms observed.",
          "Maintain a supportive stance. Observe for escalation toward acute symptoms."
      );
    } else if (prodromalCount == 1) {
      return AssessmentResult(
          RiskLevel.possible,
          "Possible early-stage indicators. Monitor closely.",
          "Keep distance and maintain a non-threatening environment."
      );
    } else {
      return AssessmentResult(RiskLevel.low, "No clinical indicators identified.", "");
    }
  }

}