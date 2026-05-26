
class ProcessStep {
  final int id;
  final String name;
  final String longName;
  final List<String> requirement;
  final List<String> record;
  final List<String> source;
  final String description;
  final List<int> requiredNext;
  final List<int> possibleNext;
  final int timeLimit;

  // The composite nested children (empty for terminal leaf steps)
  final Map<int, ProcessStep> children;

  ProcessStep({
    required this.id,
    required this.name,
    required this.longName,
    required this.requirement,
    required this.record,
    required this.source,
    required this.description,
    required this.requiredNext,
    required this.possibleNext,
    required this.timeLimit,
    required this.children,
  });

  factory ProcessStep.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawChildren = (json['steps'] as List<dynamic>?) ??
        (json['phases'] as List<dynamic>?) ??
        const [];

    final Map<int, ProcessStep> childrenMap = {
      for (var child in rawChildren)
      // 👈 THE FIX: Cast the child element to a Map FIRST so Dart can read the 'id' int
        (child as Map<String, dynamic>)['id'] as int: ProcessStep.fromJson(child)
    };

    return ProcessStep(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? json['process_blueprint'] ?? '') as String,
      longName: (json['long_name'] ?? '') as String,
      requirement: _castToStringList(json['requirement']),
      record: _castToStringList(json['record']),
      source: _castToStringList(json['source']),
      description: (json['description'] ?? '') as String,
      requiredNext: List<int>.from(json['required_next'] ?? const []),
      possibleNext: List<int>.from(json['possible_next'] ?? const []),
      timeLimit: json['time_limit'] as int? ?? 0,
      children: childrenMap,
    );
  }

  // Pure type-safe cast guards to eliminate runtime dynamic list parsing type errors
  static List<String> _castToStringList(dynamic dynamicList) {
    if (dynamicList == null || dynamicList is! List) return const [];
    return dynamicList.map((e) => e.toString()).toList();
  }

  static List<int> _castToIntList(dynamic dynamicList) {
    if (dynamicList == null || dynamicList is! List) return const [];
    return dynamicList.map((e) => int.tryParse(e.toString()) ?? 0).toList();
  }
}

