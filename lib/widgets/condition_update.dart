import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/patient_condition.dart';

class ConfigureConditionDialog extends StatefulWidget {
  final PatientCondition patientCondition;

  const ConfigureConditionDialog({
    super.key,
    required this.patientCondition,
  });

  @override
  State<ConfigureConditionDialog> createState() => _ConfigureConditionDialogState();
}

class _ConfigureConditionDialogState extends State<ConfigureConditionDialog> {
  // 1. Fully encapsulate variables inside an isolated state lifecycle
  late TextEditingController _notesController;
  late int _isActive;
  late DateTime _onset;

  @override
  void initState() {
    super.initState();
    // 2. Initialize exactly once when the dialog pops open
    _notesController = TextEditingController(text: widget.patientCondition.treatmentNotes);
    _isActive = widget.patientCondition.isActive;
    _onset = widget.patientCondition.onset!;
  }

  @override
  void dispose() {
    // 3. Clean up the controller immediately when leaving
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double availableWidth = MediaQuery.of(context).size.width;
    final double fixedDialogWidth = availableWidth - 64;

    return Dialog(
      backgroundColor: AppTheme.clinicalWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: fixedDialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 8, 16), // Tighter right padding for the icon
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0), // Eyeballs the title text baseline with the button
                        child: Text(
                          widget.patientCondition.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
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
                            selected: _isActive == 1,
                            // 1. If switched to Active, wipe out any recovery date
                            onSelected: (_) => setState(() {
                              _isActive = 1;
                              widget.patientCondition.recovery = null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text("Historical")),
                            selected: _isActive == 0,
                            // 2. If switched to Historical, default the recovery date to today if empty
                            onSelected: (_) => setState(() {
                              _isActive = 0;
                              widget.patientCondition.recovery ??= DateTime.now();
                            }),
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
                          initialDate: _onset,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _onset = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.clinicalWhite,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${_onset.year}-${_onset.month.toString().padLeft(2, '0')}-${_onset.day.toString().padLeft(2, '0')}",
                        ),
                      ),
                    ),

                    // 3. CONDITIONAL RECOVERY DATE SECTION
                    if (_isActive == 0) ...[
                      const SizedBox(height: 16),
                      const Text(
                        "RECOVERY DATE",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            // Default picker view to current recovery date value, or today
                            initialDate: widget.patientCondition.recovery ?? DateTime.now(),
                            firstDate: _onset, // 💡 Clinical Safeguard: Recovery cannot happen before onset date!
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => widget.patientCondition.recovery = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.clinicalWhite,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.patientCondition.recovery != null
                                ? "${widget.patientCondition.recovery!.year}-${widget.patientCondition.recovery!.month.toString().padLeft(2, '0')}-${widget.patientCondition.recovery!.day.toString().padLeft(2, '0')}"
                                : "Select Recovery Date",
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Text(
                      "TREATMENT NOTES",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.deepCharcoal),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
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

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepLogicViolet,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      widget.patientCondition.treatmentNotes = _notesController.text;
                      widget.patientCondition.isActive = _isActive;
                      widget.patientCondition.onset = _onset;
                      widget.patientCondition.recovery = _isActive == 0 ? DateTime.now() : null;

                      final navigator = Navigator.of(context);

                      if (widget.patientCondition.id == null) {
                        await DatabaseManager().insertPatientCondition(widget.patientCondition);
                      } else {
                        await DatabaseManager().updatePatientCondition(widget.patientCondition);
                      }

                      if (mounted) {
                        navigator.pop(true);
                      }
                    },
                    child: const Text("Confirm Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}