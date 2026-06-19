class AssessmentWizard {
  final Map<String, dynamic> triageFlow; // Your loaded JSON
  String currentNodeId;
  List<Map<String, dynamic>> history = [];

  AssessmentWizard({required this.triageFlow, required this.currentNodeId});

  Map<String, dynamic> get currentNode => triageFlow[currentNodeId];

  void advance(String optionLabel) {
    var options = currentNode['options'] as List;
    var selectedOption = options.firstWhere((o) => o['label'] == optionLabel);

    // Log for the professional handover
    history.add({'node': currentNodeId, 'answer': optionLabel});

    // Move to next node
    currentNodeId = selectedOption['next'];
  }

  void goBack() {
    if (history.isNotEmpty) {
      currentNodeId = history.removeLast()['node'];
    }
  }

  void jumpToStep(int index) {}
}
