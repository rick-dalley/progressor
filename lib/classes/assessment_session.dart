class AssessmentSession {
  // 1. Core State
  double _acuityScore = 0.0;
  final List<String> _differentialDiagnosis = [];
  final List<String> _resuscitationSteps = [];
  final List<String> _clinicalNotes = [];

  // Getters for UI binding
  double get acuityScore => _acuityScore;
  List<String> get differentialDiagnosis => List.unmodifiable(_differentialDiagnosis);
  List<String> get resuscitationSteps => List.unmodifiable(_resuscitationSteps);
  List<String> get clinicalNotes => List.unmodifiable(_clinicalNotes);

  /// Processes the 'meta' object from your JSON nodes
  /// Called whenever the wizard advances or jumps
  void processNodeResponse(Map<String, dynamic>? meta) {
    if (meta == null) return;

    // Update acuity if defined in JSON
    if (meta.containsKey('acuity_impact')) {
      _acuityScore += (meta['acuity_impact'] as num).toDouble();
    }

    // Accumulate clinical insights
    if (meta.containsKey('diagnosis')) {
      _differentialDiagnosis.add(meta['diagnosis'] as String);
    }

    // Accumulate action items
    if (meta.containsKey('steps')) {
      _resuscitationSteps.add(meta['steps'] as String);
    }
  }

  /// Reset the session (useful when user starts a new triage)
  void reset() {
    _acuityScore = 0.0;
    _differentialDiagnosis.clear();
    _resuscitationSteps.clear();
    _clinicalNotes.clear();
  }
}
