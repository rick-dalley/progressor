
import 'package:flutter/material.dart' show IconData, Icons, StatefulWidget, State, TextEditingController, BuildContext, Widget, Text, EdgeInsets, SizedBox, Row, Center, Icon, TextStyle, OutlineInputBorder, AppBar, Colors, BorderRadius, BoxDecoration, AnimatedContainer, ListView, Expanded, ElevatedButton, Padding, Column, Scaffold, MainAxisAlignment, FontWeight, InkWell, TextAlign, IconButton, Positioned, debugPrint, Stack, TextInputType, InputDecoration, TextField, Navigator, CrossAxisAlignment, Divider;
import 'package:triage/widgets/vitals_scanner.dart';

class VitalEntry {
  final String label;
  final String unit;
  final String key;
  final IconData icon;

  VitalEntry(this.label, this.unit, this.key, this.icon);
}

final List<VitalEntry> vitalsList = [
  VitalEntry("Heart Rate", "bpm", "hr", Icons.favorite),
  VitalEntry("O2 Saturation", "%", "o2", Icons.bloodtype),
  VitalEntry("Temperature", "°C", "temp", Icons.thermostat),
];

class VitalsScreen extends StatefulWidget {

  const VitalsScreen({super.key});

  @override
  VitalsScreenState createState() => VitalsScreenState();
}

class VitalsScreenState extends State<VitalsScreen> {
  final Map<String, TextEditingController> _controllers = {
    'sys': TextEditingController(),
    'dia': TextEditingController(),
    'hr': TextEditingController(),
    'o2': TextEditingController(),
    'temp': TextEditingController(),
  };

  bool _isCameraOpen = false;
  String assetPath = 'assets/screen_captures/Omron.png';
  // String assetPath = 'assets/screen_captures/WelchAllynConnex6000SpotProfileScreen.png';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Vitals")),
      body: Column(
        children: [
          // 1. CAMERA / OCR PLACEHOLDER SECTION
          VitalsScannerWidget(
            assetPath: assetPath,
            onScanCompleted: (results) {
              if (mounted && results.isNotEmpty) {
                setState(() {
                  for (var entry in results) {
                    switch (entry.key) {
                      case 'SYS':
                        _controllers['sys']?.text = entry.value;
                        break;
                      case 'DIA':
                        _controllers['dia']?.text = entry.value;
                        break;
                      case 'PULSE':
                      // Maps OCR "PULSE" to your controller "hr" (Heart Rate)
                        _controllers['hr']?.text = entry.value;
                        break;
                      case 'SPO2':
                      // Maps OCR "SPO2" to your controller "o2"
                        _controllers['o2']?.text = entry.value;
                        break;
                      case 'TEMP':
                        _controllers['temp']?.text = entry.value;
                        break;
                      case 'PATIENT_ID':
                      // If you add a controller for Patient ID, update it here
                        debugPrint("Captured Patient ID: ${entry.value}");
                        break;
                    }
                  }
                });
              }
            },
          ),

          // 2. MANUAL ENTRY LIST
          // 1. MANUAL ENTRY LIST (This replaces your previous ListView.separated block)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // First, we call the unique BP widget
                _buildBloodPressureInput(),

                const Divider(height: 32),

                // Then, we "spread" the generic vitals (HR, O2, Temp) into the list
                // The ... (spread operator) takes the list created by .map and
                // places each item directly into the children of the ListView.
                ...vitalsList.map((vital) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildVitalInput(vital),
                )),
              ],
            ),
          ),

          // 3. SUBMIT ACTION
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _submitVitals,
              child: const Text("Save Vitals"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraExpandButton() {
    return InkWell(
      onTap: () => setState(() => _isCameraOpen = true),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, color: Colors.white),
          SizedBox(width: 12),
          Text("Scan Device (OCR)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      children: [
        const Center(
          child: Text(
              "Camera Preview Placeholder\n(Future OCR Area)",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54)
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() => _isCameraOpen = false),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                // Future OCR trigger
                debugPrint("Snapshot taken for OCR processing");
              },
              child: const Text("Take Photo"),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildBloodPressureInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: Colors.redAccent, size: 30),
          const SizedBox(width: 16),
          const Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Blood Pressure",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text("mmHg",
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          // Systolic
          Expanded(
            flex: 1,
            child: TextField(
              controller: _controllers['sys'],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: "Sys",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text("/", style: TextStyle(fontSize: 20, color: Colors.black26)),
          ),
          // Diastolic
          Expanded(
            flex: 1,
            child: TextField(
              controller: _controllers['dia'],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: "Dia",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalInput(VitalEntry vital) {
    return Row(
      children: [
        Icon(vital.icon, color: Colors.blueGrey, size: 30),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Text(vital.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          flex: 2,
          child: TextField(
            controller: _controllers[vital.key],
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: "0.0",
              suffixText: vital.unit,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _submitVitals() {
    // Collect data for database/API
    final data = _controllers.map((key, controller) => MapEntry(key, controller.text));
    print("Saving Vitals: $data");
    Navigator.pop(context, data);
  }
}