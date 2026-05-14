import 'package:flutter/material.dart';

class PhysicalHealthAssessment extends StatefulWidget {
  final String patientUuid;

  const PhysicalHealthAssessment({super.key, required this.patientUuid});

  @override
  State<PhysicalHealthAssessment> createState() => _PhysicalHealthAssessmentState();
}

class _PhysicalHealthAssessmentState extends State<PhysicalHealthAssessment> {
  final Map<String, List<String>> _conditionGroups = {
    "Psychiatric / Neurodivergent": [
      "Schizoid PD", "Schizoaffective", "Bipolar I", "Bipolar II",
      "PTSD", "ADHD", "ASD", "Major Depression"
    ],
    "Cardiovascular": ["Hypertension", "AFib", "CAD", "CHF"],
    "Respiratory": ["Sleep Apnea", "COPD", "Asthma", "Emphysema"],
    "Gastrointestinal": ["IBS", "Crohn's Disease", "GERD", "Liver Disease"],
    "Renal/Metabolic": ["CKD", "Diabetes Type 1", "Diabetes Type 2", "Thyroid Disorder"],
  };

  // Tracks which chips are selected
  final Set<String> _selectedConditions = {};
  final TextEditingController _otherController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Physical Health History"),
        actions: [
          TextButton(
            onPressed: _saveAssessment,
            child: const Text("SAVE", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Select all pre-existing or pre-diagnosed conditions identified during intake.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ..._conditionGroups.entries.map((group) => _buildGroup(group.key, group.value)),

          const Divider(height: 40),

          const Text("OTHER CONDITIONS / NOTES",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 10),
          TextField(
            controller: _otherController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Enter any conditions not listed above...",
              filled: true,
              fillColor: Colors.grey.shade900,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(String title, List<String> conditions) {
    // Use a specific color for Psychiatric conditions to make them stand out
    final Color groupColor = title.contains("Psychiatric")
        ? Colors.purpleAccent
        : Colors.cyan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
              title.toUpperCase(),
              style: TextStyle(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: groupColor
              )
          ),
        ),
        Wrap(
          spacing: 8,
          children: conditions.map((condition) {
            final isSelected = _selectedConditions.contains(condition);
            return FilterChip(
              label: Text(condition),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  val ? _selectedConditions.add(condition) : _selectedConditions.remove(condition);
                });
              },
              selectedColor: groupColor.withAlpha(64),
              checkmarkColor: groupColor,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _saveAssessment() async {
    // Logic to batch insert _selectedConditions into 'patient_condition'
    // and include the text from _otherController as a narrative entry.
    Navigator.pop(context);
  }
}