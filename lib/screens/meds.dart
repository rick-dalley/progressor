import 'package:flutter/material.dart';

class MedicationScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const MedicationScreen({super.key, required this.patient});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  // Mocking the current baseline list
  final List<Map<String, String>> _meds = [
    {"name": "Sertraline", "dose": "50mg", "freq": "QD"},
    {"name": "Quetiapine", "dose": "25mg", "freq": "QHS"},
  ];

  final _nameController = TextEditingController();
  final _doseController = TextEditingController();

  void _addMedication() {
    if (_nameController.text.isNotEmpty) {
      setState(() {
        _meds.add({
          "name": _nameController.text,
          "dose": _doseController.text,
          "freq": "PRN", // Defaulting to PRN for quick entry
        });
        _nameController.clear();
        _doseController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.patient['name']?['last'] ?? "Patient";

    return Scaffold(
      appBar: AppBar(
        title: Text("Meds: $name"),
        backgroundColor: const Color(0xFF1A365D), // Your Navy brand color
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // INTAKE AREA: High-speed entry
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Medication Name",
                      hintText: "e.g. Lithium",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _doseController,
                    decoration: const InputDecoration(
                      labelText: "Dose",
                      hintText: "mg",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addMedication,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF1A365D)),
                )
              ],
            ),
          ),
          const Divider(),
          // CURRENT LIST: The Baseline
          Expanded(
            child: ListView.builder(
              itemCount: _meds.length,
              itemBuilder: (context, index) {
                final med = _meds[index];
                return ListTile(
                  leading: const Icon(Icons.medication_liquid, color: Colors.blueGrey),
                  title: Text(med['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Dose: ${med['dose']} — Freq: ${med['freq']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      setState(() => _meds.removeAt(index));
                    },
                  ),
                );
              },
            ),
          ),
          // SAVE BAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFF1A365D),
                foregroundColor: Colors.white,
              ),
              child: const Text("CONFIRM BASELINE"),
            ),
          ),
        ],
      ),
    );
  }
}