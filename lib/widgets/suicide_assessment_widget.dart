import 'package:flutter/material.dart';

import '../classes/suicide_risk.dart';

class SuicideAssessmentWidget extends StatefulWidget {
  final String subjectName;
  const SuicideAssessmentWidget({super.key, required this.subjectName});

  @override
  State<SuicideAssessmentWidget> createState() => _SuicideAssessmentWidgetState();
}

class _SuicideAssessmentWidgetState extends State<SuicideAssessmentWidget> {
  // Local state to manage the self-contained assessment
  bool _personalSafety = false;
  bool _accessToMeans = false;
  final Set<IdeationFlag> _selectedFlags = {};

  // Formulate the assessment
  SuicideRiskAssessment _getAssessment() {
    final assessment = SuicideRiskAssessment(
      subject: widget.subjectName,
      reportedBy: "Officer", // Or dynamic user
      personalSafety: _personalSafety,
      accessToMeans: _accessToMeans,
    );
    for (var flag in _selectedFlags) {
      assessment.addIndicator(flag: flag);
    }
    return assessment;
  }

  @override
  Widget build(BuildContext context) {
    final assessment = _getAssessment();
    final result = assessment.assessment();

    return Column(
      children: [
        // 1. Tactical Size-Up (Safety Toggles)
        _buildTacticalSection(),

        const SizedBox(height: 16),

        // 2. Ideation Indicators
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: IdeationFlag.values.map((flag) => FilterChip(
            label: Text(flag.name.toUpperCase()),
            selected: _selectedFlags.contains(flag),
            onSelected: (bool selected) {
              setState(() => selected ? _selectedFlags.add(flag) : _selectedFlags.remove(flag));
            },
          )).toList(),
        ),

        const SizedBox(height: 24),

        // 3. Result Display
        _buildResultCard(result),
      ],
    );
  }

  Widget _buildTacticalSection() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text("Personal Safety Compromised", style: TextStyle(fontWeight: FontWeight.bold)),
          value: _personalSafety,
          onChanged: (v) => setState(() => _personalSafety = v),
        ),
        SwitchListTile(
          title: const Text("Access to Lethal Means", style: TextStyle(fontWeight: FontWeight.bold)),
          value: _accessToMeans,
          onChanged: (v) => setState(() => _accessToMeans = v),
        ),
      ],
    );
  }

  Widget _buildResultCard(SuicideRiskAssessmentResult result) {
    // Map risk levels to intuitive colors
    final Map<RiskLevel, Color> colorMap = {
      RiskLevel.imminent: Colors.red.shade900,
      RiskLevel.high: Colors.red.shade700,
      RiskLevel.likely: Colors.orange.shade800,
      RiskLevel.possible: Colors.amber.shade700,
      RiskLevel.low: Colors.blue.shade800,
    };

    return Card(
      color: colorMap[result.risk],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.risk.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(result.statusMessage, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text(result.safetyInstruction, style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}