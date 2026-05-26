import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/patient_condition.dart';
import 'condition_update.dart';

class ConditionChip extends StatefulWidget {
  final String patientUuid;
  final IconData icon;
  final Color color;
  final PatientCondition patientCondition;
  final Function(int) onDeleteCondition;
  final VoidCallback onUpdateCondition;

  const ConditionChip({
    super.key,
    required this.patientUuid,
    required this.icon,
    required this.color,
    required this.patientCondition,
    required this.onDeleteCondition,
    required this.onUpdateCondition,
  });

  @override
  State<ConditionChip> createState() => ConditionChipState();
}
class ConditionChipState extends State<ConditionChip> {
  @override
  Widget build(BuildContext context) {
    return RawChip(
      avatar: Icon(
        widget.icon, // Pass your Material Symbol or Icon here
        size: 16,
        color: AppTheme.clinicalWhite,
      ),
      label: Text(widget.patientCondition.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      labelStyle: const TextStyle(color: Colors.white),
      backgroundColor: widget.color,
      deleteIcon: const Icon(Icons.cancel, size: 14, color: AppTheme.clinicalWhite),
      onDeleted: () {
        int? id = widget.patientCondition.id;
        if (id != null) {
          widget.onDeleteCondition(id);
        }
      },
      onPressed: () {
        _showDetailsDialog(context);
      },
    );
  }

  Future<void> _showDetailsDialog(BuildContext context) async {
    // 1. Notice we don't need 'notesController' here anymore!
    // Our new ConfigureConditionDialog handles its own controller inside its own initState.

    final wasUpdated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfigureConditionDialog(patientCondition: widget.patientCondition),
    );

    // 2. If the user hit 'Confirm' and saved changes to the DB:
    if (wasUpdated == true) {
      // Tell the parent screen to re-run its query and refresh the layout!
      widget.onUpdateCondition();
    }
  }
}
