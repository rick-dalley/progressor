import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../app_theme.dart';
import '../widgets/text_scanner.dart';

class IntakeScreen extends StatefulWidget {
  final String? frontOfId;
  final String? backOfId;
  const IntakeScreen({super.key, this.backOfId, this.frontOfId});

  @override
  IntakeScreenState createState() => IntakeScreenState();
}

class IntakeScreenState extends State<IntakeScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phnController = TextEditingController();
  final _dobController = TextEditingController();
  bool _isScanningFront = false; // Is the camera/scanner active right now?
  bool _isScanningBack = false;
  bool _frontAttached = false; // New: track front completion
  bool _backAttached = false;  // New: track back completion
  bool _cardAttached = false; // Did we successfully scan a card?
  bool _isSimulator = false;

  void _onTextDetected(RecognizedText recognizedText) {
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
      }

      // 3. SEQUENCE LOGIC
      if (_isScanningFront) {
        _isScanningFront = false;
        _frontAttached = true;
        if (widget.backOfId != null || !_isSimulator) {
          _isScanningBack = true;
        }
      } else if (_isScanningBack) {
        _isScanningBack = false;
        _backAttached = true;
        _cardAttached = true;
      }
    });
  }

  Widget _buildScannerHero() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45, // Slightly taller for vertical stack
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // FRONT SLOT (Top)
          Expanded(
            child: _buildCardSlot(
              label: "FRONT OF ID",
              isScanning: _isScanningFront,
              isAttached: _frontAttached,
              imagePath: widget.frontOfId,
              onTap: () => setState(() {
                _isScanningFront = true;
                _isScanningBack = false;
              }),
            ),
          ),
          const SizedBox(height: 12),
          // BACK SLOT (Bottom)
          Expanded(
            child: _buildCardSlot(
              label: "BACK OF ID",
              isScanning: _isScanningBack,
              isAttached: _backAttached,
              imagePath: widget.backOfId,
              onTap: () => setState(() {
                _isScanningBack = true;
                _isScanningFront = false;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSlot({
    required String label,
    required bool isScanning,
    required bool isAttached,
    String? imagePath,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        width: double.infinity, // Forces the container to fill the Column's width
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isScanning ? Colors.cyanAccent : Colors.white10,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: isScanning
              ? TextScanner(
            onTextDetected: _onTextDetected,
            mockImagePath: imagePath,
          )
              : isAttached && imagePath != null
              ? Image.asset(imagePath, fit: BoxFit.contain)
              : InkWell(
            onTap: onTap,
            child: SizedBox.expand( // This makes the ENTIRE box clickable
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined,
                      color: Colors.white24, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    // Simple check: most desktop/web builds for mobile dev act like the simulator
    // for camera purposes. If you're on iOS/Android, we check if it's a real device.
    // For now, let's stick to a manual flag or a basic check:
    _isSimulator = !kIsWeb && (Platform.isMacOS || Platform.isWindows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Intake")),
      body: Column(
        children: [
          // 1. The Scanner Hero Section (35% of screen height)
          // The New Dual-Slot Scanner Hero
          _buildScannerHero(),

          // 2. The Form Fields Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                SizedBox(height: 16.0,),
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: "First Name"),
                ),
                SizedBox(height: 16.0,),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: "Last Name"),
                ),
                SizedBox(height: 16.0,),
                TextField(
                  controller: _dobController,
                  decoration: const InputDecoration(labelText: "Date of Birth (YYYY-MMM-DD)"),
                ),
                SizedBox(height: 16.0,),
                TextField(
                  controller: _phnController,
                  decoration: const InputDecoration(labelText: "PHN"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppTheme.deepLogicViolet,
                      foregroundColor: AppTheme.clinicalWhite ),
                  child: const Text("CREATE PATIENT RECORD"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // Helper to switch between Prompt, Scanner, and Preview


}

