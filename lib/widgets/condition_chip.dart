import 'package:flutter/material.dart';
import 'package:triage/classes/database_manager.dart';

import '../app_theme.dart';
import '../classes/patient_condition.dart';

class ConditionChip extends StatefulWidget {
  final String patientUuid;
  final ConditionReference condition;
  final PatientCondition? currentPatientCondition;
  final Function(int) onDeleteCondition;

  // final Function (ConditionReference) onTapCondition;

  const ConditionChip({
    super.key,
    required this.patientUuid,
    required this.condition,
    this.currentPatientCondition,
    required this.onDeleteCondition,
    // required this.onTapCondition,
  });

  @override
  State<ConditionChip> createState() => ConditionChipState();
}

class ConditionChipState extends State<ConditionChip> {
  @override
  Widget build(BuildContext context) {
    return RawChip(
      label: Text(widget.condition.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      labelStyle: const TextStyle(color: Colors.white),
      backgroundColor: AppTheme.deepLogicViolet,
      deleteIcon: const Icon(Icons.cancel, size: 14, color: Colors.white70),
      onDeleted: () {
        widget.onDeleteCondition(widget.condition.id);
      },
      onPressed: () {
        _showDetailsDialog(context);
      },
    );
  }

  void _showDetailsDialog(BuildContext context) {
    final PatientCondition record =
        widget.currentPatientCondition ??
        PatientCondition(patientUuid: widget.patientUuid, conditionId: widget.condition.id);

    final TextEditingController notesController = TextEditingController(text: record.treatmentNotes);
    DateTime tempOnset = record.onset;
    int tempActive = record.isActive;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.clinicalWhite,
              title: Text("Configure ${widget.condition.name}"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "CURRENT STATUS",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text("Active")),
                            selected: tempActive == 1,
                            onSelected: (_) => setDialogState(() => tempActive = 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text("Historical")),
                            selected: tempActive == 0,
                            onSelected: (_) => setDialogState(() => tempActive = 0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "ONSET DATE",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempOnset,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setDialogState(() => tempOnset = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.clinicalWhite,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${tempOnset.year}-${tempOnset.month.toString().padLeft(2, '0')}-${tempOnset.day.toString().padLeft(2, '0')}",
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "TREATMENT NOTES",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.clinicalWhite,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepLogicViolet),
                  onPressed: () async {
                    record.treatmentNotes = notesController.text;
                    record.isActive = tempActive;
                    record.onset = tempOnset;
                    record.recovery = tempActive == 0 ? DateTime.now() : null;

                    if (record.patientConditionId == null) {
                      await DatabaseManager().insertPatientCondition(record);
                    } else {
                      await DatabaseManager().updatePatientCondition(record);
                    }

                    if (context.mounted) Navigator.pop(dialogContext);
                  },
                  child: const Text("Confirm", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
