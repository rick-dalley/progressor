import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../classes/symptom_evaluation.dart';
import '../classes/symptom_flag.dart';

class SymptomInputWidget extends StatefulWidget {
  final Function(SymptomFlag) onSymptomAdded;

  const SymptomInputWidget({super.key, required this.onSymptomAdded});

  @override
  State<SymptomInputWidget> createState() => _SymptomInputWidgetState();
}

class _SymptomInputWidgetState extends State<SymptomInputWidget> {
  final TextEditingController _controller = TextEditingController();

  void _handleInput(String input) {
    if (input.isEmpty) return;

    // Use your existing Factory logic
    final symptom = SymptomFactory.findSymptomByDescriptor(input);

    if (symptom != null) {
      widget.onSymptomAdded(symptom.symptomFlag);
      _controller.clear(); // Reset for next input
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(labelText: "Add Symptom/Keyword", suffixIcon: Icon(Symbols.search)),
      onSubmitted: _handleInput,
    );
  }
}
