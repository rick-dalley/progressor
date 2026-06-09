import 'package:flutter/material.dart';
import 'package:triage/widgets/pupil_selector.dart';

import '../classes/toxidrome.dart';

class ToxidromeAssessmentWidget extends StatefulWidget {
  const ToxidromeAssessmentWidget({super.key});

  @override
  State<ToxidromeAssessmentWidget> createState() => _ToxidromeAssessmentWidgetState();
}

class _ToxidromeAssessmentWidgetState extends State<ToxidromeAssessmentWidget> {
  // Assessment State
  PupilState _pupilState = PupilState.normal;
  DeliriumState _deliriumState = DeliriumState.normal;
  bool _bowelSounds = false;
  TempAssessment _tempAssessment = TempAssessment.normal;

  // Result
  ToxidromeRisk _result = const ToxidromeRisk(risk: ToxidromeRiskState.notIndicated, toxidrome: ToxidromeState.none);

  void _calculate() {
    final assessment = Toxidrome(
      bowelSounds: _bowelSounds,
      pupilState: _pupilState,
      deliriumState: _deliriumState,
      tempAssessment: _tempAssessment,
    );
    setState(() => _result = assessment.getToxidromeState());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle("Pupil State"),
        PupilSelector(
            selected: _pupilState,
            onSelected: (val) => setState(() { _pupilState = val; _calculate(); })
        ),

          _buildSectionTitle("Delirium / Activity"),
          _buildSegmentedControl<DeliriumState>(
            segments: DeliriumState.values,
            selected: _deliriumState,
            onSelectionChanged: (val) => setState(() { _deliriumState = val; _calculate(); }),
          ),

          _buildSectionTitle("Temperature Impression"),
          _buildSegmentedControl<TempAssessment>(
            segments: TempAssessment.values,
            selected: _tempAssessment,
            onSelectionChanged: (val) => setState(() { _tempAssessment = val; _calculate(); }),
          ),

          SwitchListTile(
            title: const Text("Bowel Sounds Present"),
            value: _bowelSounds,
            onChanged: (val) => setState(() { _bowelSounds = val; _calculate(); }),
          ),

          const SizedBox(height: 20),
          _buildResultCard(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)));

  Widget _buildSegmentedControl<T extends Enum>({
    required List<T> segments,
    required T selected,
    required Function(T) onSelectionChanged,
  }) {
    return SegmentedButton<T>(
      segments: segments.map((e) => ButtonSegment<T>(value: e, label: Text(e.name.toUpperCase()))).toList(),
      selected: {selected},
      onSelectionChanged: (Set<T> newSelection) => onSelectionChanged(newSelection.first),
    );
  }

  Widget _buildResultCard() {
    return Card(
      color: _result.risk == ToxidromeRiskState.dangerous ? Colors.red.shade900 : Colors.blue.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("RISK: ${_result.risk.name.toUpperCase()}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("SYNDROME: ${_result.toxidrome.name.toUpperCase()}", style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}