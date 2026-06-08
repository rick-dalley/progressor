
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../app_theme.dart';
import '../classes/medication_services.dart';

class MedicationCard extends StatefulWidget {
  final Map<String, dynamic> medData;
  final List<InteractionConflict> interactions;
  final VoidCallback onDelete;
  final ValueChanged<bool>? onExpansionChanged;
  const MedicationCard({
    super.key,
    required this.medData,
    required this.interactions,
    required this.onDelete,
    this.onExpansionChanged,
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
    final String medicationName = widget.medData['name'] ?? "Unknown Medication";
    final List<InteractionConflict> medicationInteractions = widget.interactions
        .where((conflict) => conflict.hasInteraction(medicationName))
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        key: ValueKey("tile_$medicationId"),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(hasDatasheet ? Symbols.prescriptions :Symbols.cloud_download,
          color: hasDatasheet ? Colors.green : AppTheme.lightTheme.disabledColor,
        ),
        title: Text(
          medicationName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Your existing Dose/Freq info
            Text(
              "Dose: ${widget.medData['dose'] ?? 'N/A'} — Freq: ${widget.medData['freq'] ?? 'N/A'}",
            ),

            // Row 2: The "Entanglement" / Interaction Row
            // We check for a list of interactions (we'll build the logic for this tomorrow)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: InteractionsChip(medicationName: medicationName, interactions: medicationInteractions),
            ),
          ],
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
          widget.onExpansionChanged?.call(expanded);
        },
        children: [
          if (_isFetching)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else if (_datasheet != null && _datasheet!.isNotEmpty) ...[
            ClassChips(dataSheet: _datasheet),
            ..._buildFdaSections(),
          ] else
            const ListTile(title: Text("No datasheet details found.")),
        ],
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
        shape: const Border(),
        // Remove the top and bottom borders when collapsed
        collapsedShape: const Border(),
        // Keep it explicit and simple to avoid the 'bool vs double' theme leak
        title: Text(
          entry.value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
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


class ClassChips extends StatelessWidget {
  final Map<String, dynamic>? dataSheet;
  const ClassChips({super.key, required this.dataSheet});

  @override
  Widget build(BuildContext context) {
    final String classesRaw = dataSheet!['classes']?.toString() ?? "";
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
        children: classList
            .map(
              (tagName) => Chip(
                label: Text(
                  tagName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.blue.shade50,
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: Colors.blue.shade100),
              ),
            )
            .toList(),
      ),
    );
  }
}

class InteractionsChip extends StatefulWidget {
  final List<InteractionConflict> interactions;
  final String medicationName;
  const InteractionsChip({
    super.key,
    required this.interactions,
    required this.medicationName,
  });

  @override
  State<InteractionsChip> createState() => InteractionsChipState();
}

class InteractionsChipState extends State<InteractionsChip> {
  // This is where you'll eventually track toggle states
  // bool _isIgnored = false;

  @override
  Widget build(BuildContext context) {
    // Keep the "Blank Row" placeholder for consistency when no problems exist
    if (widget.interactions.isEmpty) {
      return const SizedBox(height: 32);
    }

    final int count = widget.interactions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Badge(
        // The notification badge on the top right
        label: Text('$count'),
        // Only show the count badge if there's more than one interaction
        isLabelVisible: count > 1,
        backgroundColor: Colors.red.shade900,
        largeSize: 18,
        child: ActionChip(
          avatar: const Icon(
              Symbols.join_inner,
              size: 16,
              color: Colors.white
          ),
          label: Text(
            count == 1
                ? "Interacts with: ${widget.interactions.first.conflicting}"
                : "Multiple Interactions",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold
            ),
          ),
          backgroundColor: Colors.redAccent,
          shape: StadiumBorder(
              side: BorderSide(color: Colors.red.shade700)
          ),
          onPressed: () => _showInteractionDetails(context),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  void _showInteractionDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
              const SizedBox(width: 10),
              const Text("Interactions Found"),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.interactions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = widget.interactions[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    item.description,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(item.interaction),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}