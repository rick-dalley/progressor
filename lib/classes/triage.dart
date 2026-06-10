import 'acuity.dart';

enum Severity { low, moderate, high, critical }

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
    if (isMissingCritical || suicideRiskSeverity == Severity.critical) {
      return AcuityLevel.resuscitation; // Highest level
    }
    if (psychosisSeverity == Severity.high || toxidromeSeverity == Severity.high) {
      return AcuityLevel.urgent;
    }
    return AcuityLevel.notUrgent;
  }
}