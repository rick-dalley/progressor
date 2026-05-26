import 'process_step.dart';

/// Represents a bitmask of process flags with zero runtime overhead.
extension type const ProcessFlags(int mask) {
  // Position / Timeline Flags
  static const int none = 0;
  static const int firstInPhase = 1 << 0;     // 1
  static const int lastInPhase = 1 << 1;      // 2
  static const int terminal = 1 << 2;  // 4
  static const int firstInProcess = 1 << 3;   // 8

  // Dependency Rule Flags
  static const int required = 1 << 4;  // 16
  static const int possible = 1 << 5;  // 32
  // Topology / Architecture Flags
  static const int fansOut = 1 << 6;    // 64

  /// Factory constructor to build the mask from a ProcessStep
  factory ProcessFlags.fromProcessStep(ProcessStep step) {
    int currentMask = none;

    final hasRequiredNext = step.requiredNext.isNotEmpty;
    final hasPossibleNext = step.possibleNext.isNotEmpty;

    // Topology / Architecture Logic
    if (step.requiredNext.length > 1) {
      currentMask |= fansOut;
    }
    // Dependency Rule Logic
    if (hasRequiredNext) {
      currentMask |= required;
    }
    if (hasPossibleNext) {
      currentMask |= possible;
    }

    // Position / Timeline Logic
    if (step.id == 101) {
      currentMask |= firstInProcess;
    }
    if (step.id % 100 == 1) {
      currentMask |= firstInPhase;
    }
    if (step.requiredNext.isEmpty || step.requiredNext.contains(0)) {
      currentMask |= terminal;
    }

    return ProcessFlags(currentMask);
  }

  /// Helper methods to check flag status safely
  bool has(int flag) => (mask & flag) == flag;
  bool get isTerminal => has(terminal);
  bool get isFirst => has(firstInPhase);
  bool get isPrimary => has(firstInProcess);
  bool get branches => has(fansOut);
}