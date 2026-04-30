import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:triage/classes/database_manager.dart';
import '../classes/medication_services.dart';

class MedicationCard extends StatefulWidget {
  final Map<String, dynamic> medData;
  final VoidCallback onDelete;

  const MedicationCard({
    super.key,
    required this.medData,
    required this.onDelete
  });

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
  Map<String, dynamic>? _datasheet;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    // If we already know the datasheet is local, get it immediately
    if (widget.medData['has_local_datasheet'] == 1) {
      _triggerFetch();
    }
  }

  void _triggerFetch() async {
    if (_isFetching) return;

    setState(() => _isFetching = true);

    final row = await MedicationService.getDrugDataSheet(
      widget.medData['id']?.toString() ?? "",
      widget.medData['name'] ?? "",
      widget.medData['set_id'] ?? "",
    );

    if (mounted) {
      setState(() {
        _datasheet = row; // This is our in-memory "Source of Truth"
        _isFetching = false;

        // Update the map immediately here if you want,
        // but only if the row actually came back with data.
        if (row != null) {
          widget.medData['has_local_datasheet'] = 1;
          widget.medData['set_id'] = row['set_id'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDatasheet = widget.medData['has_local_datasheet'] == 1;
    final String medicationId = widget.medData['id']?.toString() ?? 'unknown';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        key: ValueKey("tile_$medicationId"),
        leading: Icon(
          hasDatasheet ? Icons.assignment_turned_in : Icons.assignment_late,
          color: hasDatasheet ? Colors.green : Colors.blueGrey,
        ),        title: Text(
          widget.medData['name'] ?? "Unknown Medication",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Dose: ${widget.medData['dose'] ?? 'N/A'} — Freq: ${widget.medData['freq'] ?? 'N/A'}",
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                  widget.onDelete();
              },
            ),
            const Icon(Icons.expand_more), // Re-adding the expansion arrow
          ],
        ),
        onExpansionChanged: (expanded) {
          if (expanded && _datasheet == null) {
            _triggerFetch();
          }
        },
        children: [
          if (_isFetching)
            const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
          else if (_datasheet != null && _datasheet!.isNotEmpty) ...[
            _buildClassChips(),
            ..._buildFdaSections(),
          ] else
            const ListTile(title: Text("No datasheet details found."))
        ],
      ),
    );
  }

  Widget _buildClassChips() {
    if (_datasheet == null) return const SizedBox.shrink();

    final String classesRaw = _datasheet!['classes']?.toString() ?? "";
    if (classesRaw.isEmpty) return const SizedBox.shrink();

    final List<String> classList = classesRaw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (classList.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: classList.map((tagName) => Chip(
          label: Text(
            tagName.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blue.shade50,
          visualDensity: VisualDensity.compact,
          side: BorderSide(color: Colors.blue.shade100),
        )).toList(),
      ),
    );
  }

  List<Widget> _buildFdaSections() {
    if (_datasheet == null) return [];

    Map<String, dynamic> targetJson = _datasheet!;
    if (_datasheet!.containsKey('results') && _datasheet!['results'] is List) {
      targetJson = _datasheet!['results'][0];
    }

    final Map<String, String> sectionMap = {
      'indications_and_usage': 'Indications',
      'dosage_and_administration': 'Dosage',
      'warnings_and_cautions': 'Warnings',
      'adverse_reactions': 'Adverse Reactions',
      'description': 'Description',
    };

    return sectionMap.entries.map((entry) {
      final data = targetJson[entry.key];
      String text = data?.toString() ?? "";

      if (text.isEmpty || text == "null") return const SizedBox.shrink();

      return ExpansionTile(
        // Keep it explicit and simple to avoid the 'bool vs double' theme leak
        title: Text(entry.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SelectableText(text),
          ),
        ],
      );
    }).toList();
  }

}