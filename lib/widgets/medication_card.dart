import 'package:flutter/material.dart';
import '../classes/medication_services.dart';

class MedicationCard extends StatefulWidget {
  final Map<String, dynamic> medData; // The simple map from your JSON
  final VoidCallback onDelete;

  const MedicationCard({super.key, required this.medData, required this.onDelete});

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
  Future<Medication?>? _datasheetFuture;

  void _fetchDetails() {
    if (_datasheetFuture == null) {
      setState(() {
        // Fetch only when requested
        String setId = widget.medData['set_id'] ?? "";
        String medicationId = widget.medData['id'] ?? "";
        String medicationName = widget.medData['name'] ?? "";
        _datasheetFuture = MedicationService.getDrugDataSheet(medicationId, medicationName,setId );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded) _fetchDetails();
        },
        leading: const Icon(Icons.medication_liquid, color: Colors.blueGrey),
        title: Text(widget.medData['name'] ?? "Unknown",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Dose: ${widget.medData['dose']} — Freq: ${widget.medData['freq']}"),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: widget.onDelete,
        ),
        children: [
          FutureBuilder<Medication?>(
            future: _datasheetFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(), // Visual feedback for loading
                );
              }

              if (snapshot.hasError || snapshot.data == null) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Could not retrieve FDA datasheet."),
                );
              }

              final med = snapshot.data!;
              return Column(
                children: [
                  const Text("PHARMACOLOGIC CLASSES",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  // Use a Wrap for the Chips
                  Wrap(
                    spacing: 8,
                    children: med.classes.map((c) => Chip(
                      label: Text(c, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.white,
                    )).toList(),
                  ),
                  ...med.datasheetSections.entries.map((entry) {
                    return ExpansionTile(
                      title: Text(entry.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(entry.value),
                        ),
                      ],
                    );
                  }),
                ]
              );
            },
          ),
        ],
      ),
    );
  }
}