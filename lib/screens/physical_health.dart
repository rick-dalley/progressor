import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/patient_condition.dart';
import '../widgets/condition_chip.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../widgets/halo_ripple_chip.dart';

class MedicalCategory {
  final IconData iconData;
  final Color color;
  final Color textColor;
  MedicalCategory({required this.iconData, required this.color, required this.textColor});
}

Map<String, MedicalCategory> categoryIcons = {
  "Cardiovascular": MedicalCategory(iconData: Symbols.cardiology, color: Color(0xFFBA0000), textColor: Colors.white),
  "Dermatological": MedicalCategory(iconData: Symbols.dermatology, color: Color(0xFFBA5D00), textColor: Colors.white),
  "Gastrointestinal": MedicalCategory(iconData: Symbols.gastroenterology, color: Color(0xFF64008C), textColor: Colors.white),
  "Infectious and Immunological":MedicalCategory(iconData: Symbols.microbiology, color: Color(0xFFBA8002), textColor: Colors.white),
  "Mental and Behavioral Health": MedicalCategory(iconData: Symbols.psychiatry, color: Color(0xFF187303), textColor: Colors.white),
  "Metabolic & Endocrine": MedicalCategory(iconData: Symbols.metabolism, color: Color(0xFF730350), textColor: Colors.white),
  "Musculoskeletal": MedicalCategory(iconData: Symbols.orthopedics, color: Color(0xFF636363), textColor: Colors.white),
  "Neurological": MedicalCategory(iconData: Symbols.neurology, color: Color(0xFF215A8A), textColor: Colors.white),
  "Respiratory": MedicalCategory(iconData: Symbols.pulmonology, color: Color(0xFF0298BA), textColor: Colors.white),
  "Urological and Reproductive": MedicalCategory(iconData: Symbols.urology, color: Color(0xFF8A346C), textColor: Colors.white),
};

class PhysicalHealthAssessment extends StatefulWidget {
  final String patientUuid;
  final ScrollController scrollController;

  const PhysicalHealthAssessment({super.key, required this.patientUuid, required this.scrollController});

  @override
  State<PhysicalHealthAssessment> createState() => _PhysicalHealthAssessmentState();
}

class _PhysicalHealthAssessmentState extends State<PhysicalHealthAssessment> {
  final TextEditingController _otherController = TextEditingController();
  late Future<Map<String, List<ConditionReference>>> _catalogFuture;
  late Future<List<PatientCondition>> _patientConditions;

  // We will store a flat list of references once loaded to quickly render the top dock
  List<ConditionReference> _allConditionsFlat = [];

  @override
  void initState() {
    super.initState();
    _patientConditions = DatabaseManager().getConditionsForPatient(widget.patientUuid);

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
    return FutureBuilder<List<PatientCondition>>(
      future: _patientConditions,
      builder: (context, patientSnapshot) {
        // 1. Unpack our live database conditions (default to an empty list while waiting)
        final List<PatientCondition> livePatientConditions = patientSnapshot.data ?? [];

        // Calculate active condition status cleanly based on our unpacked database records
        final bool hasActiveConditions = livePatientConditions.isNotEmpty;

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

            //Anchored Active Conditions Top Panel
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: !hasActiveConditions ? EdgeInsets.zero : const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: !hasActiveConditions ? Colors.transparent : AppTheme.clinicalCyanCanvas,
                borderRadius: BorderRadius.circular(12),
                border: !hasActiveConditions ? null : Border.all(color: AppTheme.clinicalCyanCanvas, width: 1),
              ),
              child: !hasActiveConditions
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
                          children: livePatientConditions.map((PatientCondition currentCondition) {
                            // Find the matching master reference metadata in memory for this row
                            final selectedCurrentRef = _allConditionsFlat.firstWhere(
                              (ref) => ref.id == currentCondition.conditionId,
                              orElse: () => ConditionReference(
                                id: currentCondition.conditionId,
                                name: currentCondition.name,
                                category: "",
                              ),
                            );
                            currentCondition.name = selectedCurrentRef.name;
                            return ConditionChip(
                              patientUuid: widget.patientUuid,
                              icon: categoryIcons[selectedCurrentRef.category]!.iconData,
                              color: categoryIcons[selectedCurrentRef.category]!.color,
                              patientCondition: currentCondition,
                              onDeleteCondition: (int id) async {
                                await DatabaseManager().deletePatientCondition(id);
                                setState(() {
                                  _patientConditions = DatabaseManager().getConditionsForPatient(widget.patientUuid);
                                });
                              },
                              onUpdateCondition: () {
                                // When a chip updates, trigger the exact same parent refresh query!
                                setState(() {
                                  _patientConditions = DatabaseManager().getConditionsForPatient(widget.patientUuid);
                                });
                              },
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
                    builder: (context, catalogSnapshot) {
                      if (catalogSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (catalogSnapshot.hasError || !catalogSnapshot.hasData) {
                        return const Text(
                          "Failed to load clinical conditions catalog from disk.",
                          style: TextStyle(color: Colors.red),
                        );
                      }

                      final catalogMap = catalogSnapshot.data!;

                      return Container(
                        width: double.infinity,
                        alignment: Alignment.topLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // Pass down livePatientConditions so your individual sub-group chips know their selection state synchronously
                          children: catalogMap.entries
                              .map((group) => _buildGroup(group.key, group.value, livePatientConditions))
                              .toList(),
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
      },
    );
  }

  Widget _buildGroup(String category, List<ConditionReference> conditions, List<PatientCondition> liveRecords) {
    MedicalCategory categoryIcon = categoryIcons[category]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HaloRippleChip(
              iconData: categoryIcon.iconData,
              text: category,
              color: categoryIcon.color,
              backgroundColor: Color(0xFF000000),
              animate: false,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: conditions.map((condition) {
            // Check selection instantly against our active database row cache
            final bool isSelected = liveRecords.any((pc) => pc.conditionId == condition.id);

            return FilterChip(
              label: Text(condition.name),
              // 1. Customize the Text Style and Font Color
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : categoryIcon.color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              // 2. Customize the Border Color and Thickness
              side: BorderSide(
                color: isSelected ? Colors.transparent : categoryIcon.color.withAlpha(128),
                width: 1.5,
              ),
              // 3. Customize Background Fill dynamically to match
              color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return categoryIcon.color; // Solid category color when active
                }
                return categoryIcon.color.withAlpha(20); // Soft tint when inactive
              }),
              selected: isSelected,
              onSelected: (bool selected) async {
                if (selected) {
                  final newIncomplete = PatientCondition.fromCondition(widget.patientUuid, condition);
                  await DatabaseManager().insertPatientCondition(newIncomplete);
                } else {
                  final recordToRemove = liveRecords.firstWhere((pc) => pc.conditionId == condition.id);
                  if (recordToRemove.id != null) {
                    await DatabaseManager().deletePatientCondition(recordToRemove.id!);
                  }
                }

                // Re-read from SQLite and trigger UI sync
                setState(() {
                  _patientConditions = DatabaseManager().getConditionsForPatient(widget.patientUuid);
                });
              },
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
