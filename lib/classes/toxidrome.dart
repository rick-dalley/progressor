enum PupilState { normal, dilated, pinpoint }

enum ToxidromeState { cholinergic, opioids, sympathomimetic, anticholinergic, hallucinogenic, sedativeHypnotics, none, unknown }

enum DeliriumState { hyperActive, hypoActive, normal }

enum ToxidromeRiskState { dangerous, high, likely, possible, notIndicated, unknown }

enum TempAssessment { normal, warm, hot, burning, unknown }

class ToxidromeRisk {
  final ToxidromeState toxidrome;
  final ToxidromeRiskState risk;

  const ToxidromeRisk({required this.risk, required this.toxidrome});
}

class Toxidrome {
  final bool bowelSounds;
  final PupilState pupilState;
  final DeliriumState deliriumState;
  double? temperature;
  TempAssessment? tempAssessment;

  static final double vergingHighTemp = 37.9;
  static final double highTemp = 38.9;
  static final double dangerousTemp = 40.5;

  Toxidrome({
    required this.bowelSounds,
    required this.pupilState,
    required this.deliriumState,
    this.temperature = 36.9,
    this.tempAssessment
  });

  ToxidromeRisk getToxidromeState() {
    if ((tempAssessment == null) && (temperature == null)){
      return ToxidromeRisk(risk: ToxidromeRiskState.unknown, toxidrome: ToxidromeState.unknown);
    }
    double assessedTemperature = 36.9;
    if(temperature == null){
      switch (tempAssessment){
        case null:
          assessedTemperature = 36.9;
        case TempAssessment.normal:
          assessedTemperature = 36.9;
        case TempAssessment.warm:
          assessedTemperature = 37.2;
        case TempAssessment.hot:
          assessedTemperature = 38.0;
        case TempAssessment.burning:
          assessedTemperature = 40.0;
        case TempAssessment.unknown:
          assessedTemperature = 36.9;
      }
    } else {
      assessedTemperature = temperature!;
    }

    ToxidromeState toxidromeState = ToxidromeState.none;
    ToxidromeRiskState risk = ToxidromeRiskState.notIndicated;
    if (pupilState == PupilState.pinpoint) {
      if (deliriumState == DeliriumState.hyperActive) {
        risk = ToxidromeRiskState.high;
        toxidromeState = ToxidromeState.cholinergic;
      } else if (deliriumState == DeliriumState.hypoActive) {
        toxidromeState = ToxidromeState.opioids;
        risk = ToxidromeRiskState.high;
      }
    } else if (pupilState == PupilState.normal || pupilState == PupilState.dilated) {
      risk = ToxidromeRiskState.possible;
      if (assessedTemperature > vergingHighTemp) {
        if (bowelSounds) {
          toxidromeState = ToxidromeState.sympathomimetic;
          risk = assessedTemperature > highTemp ? ToxidromeRiskState.high : ToxidromeRiskState.likely;
        } else {
          toxidromeState = ToxidromeState.anticholinergic;
          risk = assessedTemperature > highTemp ? ToxidromeRiskState.high : ToxidromeRiskState.likely;
        }
      } else if (bowelSounds) {
        toxidromeState = ToxidromeState.hallucinogenic;
        risk = assessedTemperature > highTemp ? ToxidromeRiskState.high : ToxidromeRiskState.likely;
      } else {
        toxidromeState = ToxidromeState.sedativeHypnotics;
        risk = assessedTemperature > highTemp ? ToxidromeRiskState.high : ToxidromeRiskState.likely;
      }
    }
    risk = (assessedTemperature > dangerousTemp) ? ToxidromeRiskState.dangerous : risk;
    return ToxidromeRisk(risk: risk, toxidrome: toxidromeState);
  }
}
