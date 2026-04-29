import 'package:flutter/material.dart';

class IntakeScreen extends StatefulWidget {

  const IntakeScreen({super.key});

  @override
  IntakeScreenState createState() => IntakeScreenState();
}

class IntakeScreenState extends State<IntakeScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phnController = TextEditingController();

  void _fakeOCRScan() {
    // Simulating the "Aha!" moment of OCR
    setState(() {
      _firstNameController.text = "Julian";
      _lastNameController.text = "Lage";
      _phnController.text = "987-654-321";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("OCR Data Populated from ID Scan")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Intake")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _fakeOCRScan,
              icon: const Icon(Icons.camera_alt),
              label: const Text("SCAN IDENTITY CARD (OCR)"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blueGrey.shade50,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: "First Name"),
            ),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: "Last Name"),
            ),
            TextField(
              controller: _phnController,
              decoration: const InputDecoration(labelText: "PHN (Personal Health Number)"),
              keyboardType: TextInputType.number,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // For now, just pop back. Later, we'll return the new patient object.
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text("CREATE PATIENT RECORD"),
            ),
          ],
        ),
      ),
    );
  }
}