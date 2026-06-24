import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/scanned_data.dart';
import 'package:triage/widgets/scanner_widget.dart';
import '../app_theme.dart';

class IntakeScreen extends StatefulWidget {
  final bool? isSimulation;
  final Function(ScannedData data)? onScannedData;
  const IntakeScreen({super.key, this.isSimulation, this.onScannedData});

  @override
  IntakeScreenState createState() => IntakeScreenState();
}

class IntakeScreenState extends State<IntakeScreen> {
  late String frontOfId = 'assets/screen_captures/license_front.png';
  late String backOfId = 'assets/screen_captures/license_back.png';
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phnController = TextEditingController();
  final _dobController = TextEditingController();
  late ScannedData scannedData = ScannedData();
  late bool _isSimulator = widget.isSimulation ?? false;

  @override
  void initState() {
    super.initState();
    // Simple check: most desktop/web builds for mobile dev act like the simulator
    // for camera purposes. If you're on iOS/Android, we check if it's a real device.
    // For now, let's stick to a manual flag or a basic check:
    _isSimulator = !kIsWeb && (Platform.isMacOS || Platform.isWindows);
  }

  void onTextDetected(RecognizedText recognizedText) {
    final String fullText = recognizedText.text;
    final List<String> lines = fullText.split('\n').map((e) => e.trim()).toList();

    setState(() {
      // 1. PHN (Regex is robust, keep it)
      final phnRegex = RegExp(r'\d{4} \d{3} \d{3}');
      final match = phnRegex.firstMatch(fullText);
      if (match != null) _phnController.text = match.group(0)!;

      // 2. SWEEP FOR DOB & NAME
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i].toUpperCase();

        // Handle DOB (Checking for "OB:" to catch "DOB" or "ĐOB")
        if (line.contains("OB:")) {
          _dobController.text = lines[i].split(':').last.trim();
        }

        // Handle Name: Look for "DALLEY" (or use a generic "Surname" check)
        // Since we know the Surname has a comma:
        if (line.contains(',')) {
          // Line with comma is likely: DALLEY,
          _lastNameController.text = lines[i].replaceAll(',', '').trim().toUpperCase();

          // The very next line is likely the First Name
          if (i + 1 < lines.length) {
            _firstNameController.text = lines[i + 1].trim().toUpperCase();
          }
        }
        scannedData.firstName = _firstNameController.text;
        scannedData.lastName = _lastNameController.text;
        scannedData.phn = _phnController.text;
        scannedData.dob = _dobController.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Intake")),
      body: Column(
        children: [
          ScannerWidget(scanFront: true, scanBack: true, isSimulationOnly: true, onTextDetected: onTextDetected),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                SizedBox(height: 16.0),
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: "First Name"),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: "Last Name"),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: _dobController,
                  decoration: const InputDecoration(labelText: "Date of Birth (YYYY-MMM-DD)"),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: _phnController,
                  decoration: const InputDecoration(labelText: "PHN"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (widget.onScannedData != null) {
                            widget.onScannedData!(scannedData);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size.fromHeight(50),
                          backgroundColor: AppTheme.deepLogicViolet,
                          foregroundColor: AppTheme.clinicalWhite,
                        ),
                        child: const Icon(Symbols.save, size: 32),
                      ),
                    ),
                    const SizedBox(width: 16), // Spacing
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size.fromHeight(50),
                          backgroundColor: AppTheme.deepLogicViolet,
                          foregroundColor: AppTheme.clinicalWhite,
                        ),
                        child: const Icon(Symbols.domino_mask, size: 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
