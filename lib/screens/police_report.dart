import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PoliceReportScreen extends StatefulWidget {
  const PoliceReportScreen({super.key});

  @override
  State<PoliceReportScreen> createState() => _PoliceReportScreenState();
}

class _PoliceReportScreenState extends State<PoliceReportScreen> {
  final _badgeController = TextEditingController();
  final _fileNumberController = TextEditingController();
  final _narrativeController = TextEditingController();
  String _selectedAgency = 'RCMP';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Police Handoff / Sec. 28")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section 1: Agency Information
          const Text("Officer & Agency Details", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedAgency,
            items: ['RCMP', 'VPD', 'Transit Police', 'Other'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (val) => setState(() => _selectedAgency = val!),
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Agency"),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _badgeController,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Badge Number"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _fileNumberController,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "File/GO Number"),
                ),
              ),
            ],
          ),
          const Divider(height: 40),

          // Section 2: Narrative & Summary
          const Text("Officer's Verbal Narrative", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _narrativeController,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: "Summary of events leading to apprehension, behaviors noted by officer...",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // Section 3: Document Attachment
          OutlinedButton.icon(
            onPressed: () { /* Logic for Camera/File Picker discussed earlier */ },
            icon: const Icon(Icons.camera_alt),
            label: const Text("Scan Physical Report or Form 10"),
          ),

          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: _savePoliceReport,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text("Save Handoff Record"),
          ),
        ],
      ),
    );
  }

  void _savePoliceReport() {
    // Logic to save to your local state or database
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Police handoff record saved.")),
    );
  }
}