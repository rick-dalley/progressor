import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/patient_condition.dart';
import '../widgets/condition_chip.dart';

class PhysicalHealthAssessment extends StatefulWidget {
  final String patientUuid;
  final ScrollController scrollController;

  const PhysicalHealthAssessment({super.key, required this.patientUuid, required this.scrollController});

  @override
  State<PhysicalHealthAssessment> createState() => _PhysicalHealthAssessmentState();
}

class _PhysicalHealthAssessmentState extends State<PhysicalHealthAssessment> {
  final Set<int> _selectedConditions = {};
  final TextEditingController _otherController = TextEditingController();
  late Future<Map<String, List<ConditionReference>>> _catalogFuture;

  // 🟢 We will store a flat list of references once loaded to quickly render the top dock
  List<ConditionReference> _allConditionsFlat = [];

  @override
  void initState() {
    super.initState();
    _catalogFuture = DatabaseManager().getConditionsCatalog().then((data) {
      // Flatten the incoming catalog map data structure for fast summary lookups
      setState(() {
        _allConditionsFlat = data.values.expand((list) => list).toList();
      });
      return data;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter out exactly which references are currently checked active
    final activeConditions = _allConditionsFlat.where((c) => _selectedConditions.contains(c.id)).toList();

    return Column(
      children: [
        // Title bar block
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Physical Health History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        // 🟢 NEW: Anchored Active Conditions Top Panel
        // AnimatedContainer smoothly collapses/expands height depending on active selections
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: activeConditions.isEmpty ? EdgeInsets.zero : const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: activeConditions.isEmpty ? Colors.transparent : AppTheme.clinicalCyanCanvas,
            borderRadius: BorderRadius.circular(12),
            border: activeConditions.isEmpty ? null : Border.all(color: AppTheme.clinicalCyanCanvas, width: 1),
          ),
          child: activeConditions.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.assignment_late_outlined, size: 16, color: AppTheme.clinicalCyan),
                        SizedBox(width: 6),
                        Text(
                          "PATIENT ACTIVE PROFILE SUMMARY",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.clinicalCyan,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: activeConditions.map((condition) {
                        return ConditionChip(
                          patientUuid: widget.patientUuid,
                          condition: condition,
                          onDeleteCondition: (int id) {
                            setState(() {
                              _selectedConditions.remove(id);
                            });
                          },
                          // onTapCondition: (ConditionReference ref) {
                          //   _showConditionDetailsDialog(context, ref);
                          // },
                        );
                      }).toList(),
                    ),
                  ],
                ),
        ),

        // The main scrollable data input catalog
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              const Text(
                "Select all pre-existing or pre-diagnosed conditions identified during intake.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 14),

              FutureBuilder<Map<String, List<ConditionReference>>>(
                future: _catalogFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text(
                      "Failed to load clinical conditions catalog from disk.",
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  final catalogMap = snapshot.data!;

                  return Container(
                    width: double.infinity,
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: catalogMap.entries.map((group) => _buildGroup(group.key, group.value)).toList(),
                    ),
                  );
                },
              ),
              const Divider(height: 40),

              const Text("OTHER CONDITIONS / NOTES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 10),
              TextField(
                controller: _otherController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Enter any conditions not listed above...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // Anchored bottom control panel
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.clinicalWhite,
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
                  backgroundColor: AppTheme.deepLogicViolet,
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

  Widget _buildGroup(String title, List<ConditionReference> conditions) {
    final Color groupColor = title.contains("Psychiatric") ? Colors.purpleAccent : Colors.cyan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.bold, fontSize: 12, color: groupColor),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: conditions.map((condition) {
            final isSelected = _selectedConditions.contains(condition.id);
            return FilterChip(
              label: Text(condition.name),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  val ? _selectedConditions.add(condition.id) : _selectedConditions.remove(condition.id);
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
    // Your _selectedConditions set continues to hold structural SQLite row IDs cleanly
    Navigator.pop(context);
  }
}
