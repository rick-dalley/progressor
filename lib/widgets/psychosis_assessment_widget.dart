import 'package:flutter/material.dart';
import '../classes/psychosis.dart';

class PsychosisAssessmentWidget extends StatefulWidget {
  final String subjectName; // Required to initialize the assessment
  const PsychosisAssessmentWidget({super.key, required this.subjectName});

  @override
  State<PsychosisAssessmentWidget> createState() => _PsychosisAssessmentWidgetState();
}

class _PsychosisAssessmentWidgetState extends State<PsychosisAssessmentWidget> {
  // Encapsulated assessment logic
  late PsychosisAssessment _assessment;
  bool _personalSafety = false;
  bool _publicSafety = false;

  @override
  void initState() {
    super.initState();
    _assessment = PsychosisAssessment(
      subject: widget.subjectName,
      personalSafety: _personalSafety,
      publicSafety: _publicSafety,
    );
  }

  void _updateAssessment() {
    // Recreate the assessment object with current state to get fresh result
    setState(() {
      _assessment = PsychosisAssessment(
        subject: widget.subjectName,
        personalSafety: _personalSafety,
        publicSafety: _publicSafety,
      );
      // Re-add indicators from the local UI state
      for (var indicator in _selectedFlags) {
        _assessment.addIndicator(flag: indicator);
      }
    });
  }

  final Set<PsychosisFlag> _selectedFlags = {};

  @override
  Widget build(BuildContext context) {
    // Calculate result on the fly
    final result = _assessment.assessment();

    return Column(
      children: [
        // 1. Scene Size-Up (Safety Overrides)
        SwitchListTile(
          title: const Text("Personal Safety Compromised"),
          value: _personalSafety,
          onChanged: (v) { setState(() { _personalSafety = v; _updateAssessment(); }); },
        ),
        SwitchListTile(
          title: const Text("Public Safety Compromised"),
          value: _publicSafety,
          onChanged: (v) { setState(() { _publicSafety = v; _updateAssessment(); }); },
        ),

        // 2. Indicators Grid
        Wrap(
          children: PsychosisFlag.values.map((flag) => FilterChip(
            label: Text(flag.name),
            selected: _selectedFlags.contains(flag),
            onSelected: (bool selected) {
              setState(() {
                selected ? _selectedFlags.add(flag) : _selectedFlags.remove(flag);
                _updateAssessment();
              });
            },
          )).toList(),
        ),

        // 3. Result Display
        _buildResultCard(result),
      ],
    );
  }

  Widget _buildResultCard(AssessmentResult result) {
    // Logic for visual feedback based on risk level
    return Card(
      color: result.risk == RiskLevel.high ? Colors.red : Colors.blue,
      child: ListTile(
        title: Text(result.statusMessage, style: const TextStyle(color: Colors.white)),
        subtitle: Text(result.safetyInstruction, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}