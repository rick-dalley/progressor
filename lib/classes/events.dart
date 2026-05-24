abstract class Event {
  int get stepId;
  int? get previousStepId;
  int? get nextStepId;
  String get label;
  bool get isStarted;
  bool? get isCompleted;
  DateTime? get started;
  DateTime? get completed;
  Duration? get elapsedTime;
  Event();
}