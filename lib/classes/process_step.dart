
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
  final List<ProcessStep> children;

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

  /// Unified processor for parsing the document recursively
  factory ProcessStep.fromJson(Map<String, dynamic> json) {
    // Collect child elements if they exist under 'phases' or 'steps' keys
    final List<dynamic>? rawChildren = json['steps'] as List<dynamic>? ?? json['phases'] as List<dynamic>?;

    final List<ProcessStep> parsedChildren = rawChildren != null
        ? rawChildren.map((item) => ProcessStep.fromJson(item as Map<String, dynamic>)).toList()
        : const [];

    return ProcessStep(
      id: json['id'] as int? ?? 0,
      // Use fallback properties for root schema initialization if parsing the outer wrapper
      name: (json['name'] ?? json['process_blueprint'] ?? '') as String,
      longName: (json['long_name'] ?? '') as String,
      requirement: _castToStringList(json['requirement']),
      record: _castToStringList(json['record']),
      source: _castToStringList(json['source']),
      description: (json['description'] ?? '') as String,
      requiredNext: _castToIntList(json['required_next']),
      possibleNext: _castToIntList(json['possible_next']),
      timeLimit: json['time_limit'] as int? ?? 0,
      children: parsedChildren,
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

extension StepTaversal on ProcessStep {
  /// Crawls all sub-layers recursively to construct a single flat O(1) tracking dictionary
  Map<int, ProcessStep> generateRegistry() {
    final Map<int, ProcessStep> registry = {};

    // Only map valid step or phase IDs (skipping root structural wrappers)
    if (id != 0) {
      registry[id] = this;
    }

    for (final child in children) {
      registry.addAll(child.generateRegistry());
    }

    return registry;
  }

  /// Traverses downstream branches to find a node pattern cleanly without external indices
  ProcessStep? findNode(int targetId) {
    if (id == targetId) return this;

    for (final child in children) {
      final ProcessStep? match = child.findNode(targetId);
      if (match != null) return match;
    }

    return null;
  }

}
