import 'package:flutter/material.dart';

import '../app_theme.dart';

class PhysicalHealthAssessment extends StatefulWidget {
  final String patientUuid;
  final ScrollController scrollController;

  const PhysicalHealthAssessment({super.key, required this.patientUuid, required this.scrollController});

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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Title bar block that naturally matches the styling of your other sheets
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Physical Health History",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // We can place a text button or explicit action item here if preferred
            ],
          ),
        ),

        // 2. The main body wrapped in an Expanded to give the list proper depth context
        Expanded(
          child: ListView(
            // ✅ Wire up the modal's tracking controller here
            controller: widget.scrollController,
            // ✅ Force uniform scrolling physics
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              const SizedBox(height: 20),
            ],
          ),
        ),

        // 3. Anchored bottom control panel containing your submission trigger
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.clinicalWhite, // Match your local backdrop theme
            border: Border(top: BorderSide(color: Colors.grey.shade800, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveAssessment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.clinicalWhite, // Use your app accent theme color
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  "SAVE ASSESSMENT",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ),
      ],
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