
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
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

class VitalsCaptureScreen extends StatefulWidget {
  final void Function(int systolic, int diastolic, int pulse, double spo2, double temperature) onAddVitals;

  const VitalsCaptureScreen({super.key, required this.onAddVitals});

  @override
  VitalsCaptureScreenState createState() => VitalsCaptureScreenState();
}

class VitalsCaptureScreenState extends State<VitalsCaptureScreen> {

  bool _isScannerLoaded = false;
  String assetPath = 'assets/screen_captures/WelchAllynConnex6000SpotProfileScreen.png';

  final Map<String, TextEditingController?> _controllers = {
    'sys': null,
    'dia': null,
    'hr': null,
    'o2': null,
    'temp': null,
  };

  TextEditingController getController(String key) {
    _controllers[key] ??= TextEditingController();
    return _controllers[key]!;
  }

  @override
  void initState() {
    super.initState();
    // Delay scanner startup until the UI is idle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isScannerLoaded = true);
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      if (controller!=null) {
        controller.dispose();
      }
    }
    super.dispose();
  }
  Key _scannerKey = UniqueKey();

  void _rescan() {
    setState(() {
      // Changing the key forces Flutter to dispose of the old
      // scanner and build a brand-new one from scratch
      _scannerKey = UniqueKey();
    });
  }

  // String assetPath = 'assets/screen_captures/Omron.png';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Vitals"),
      actions: [
        IconButton(
          icon: const Icon(Symbols.frame_reload),
          onPressed: _rescan, // Trigger the rescan
          tooltip: "Rescan Vitals",
        )
      ],),
      body: Column(
        children: [
          // 1. CAMERA / OCR PLACEHOLDER SECTION
          !_isScannerLoaded
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            :  VitalsScannerWidget(
            key: _scannerKey,
            assetPath: assetPath,
            onScanCompleted: (results) {
              if (mounted && results.isNotEmpty) {
                setState(() {
                  for (var entry in results) {
                    switch (entry.key) {
                      case 'SYS':
                        getController('sys').text = entry.value;
                        break;
                      case 'DIA':
                        getController('dia').text = entry.value;
                        break;
                      case 'PULSE':
                      // Maps OCR "PULSE" to your controller "hr" (Heart Rate)
                        getController('hr').text = entry.value;
                        break;
                      case 'SPO2':
                      // Maps OCR "SPO2" to your controller "o2"
                        getController('o2').text = entry.value;
                        break;
                      case 'TEMP':
                        getController('temp').text = entry.value;
                        break;
                      case 'PATIENT_ID':
                      // If you add a controller for Patient ID, update it here
                      //   debugPrint("Captured Patient ID: ${entry.value}");
                        break;
                    }
                  }
                });
              }
            },
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // First, we call the unique BP widget
                _buildBloodPressureInput(),
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
          const Divider(height: 32),

          // 3. SUBMIT ACTION
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _submitVitals,
              child: const Text("SAVE"),
            ),
          ),
        ],
      ),
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
    int sys = int.tryParse(_controllers['sys']?.text ?? '') ?? 0;
    int dia = int.tryParse(_controllers['dia']?.text ?? '') ?? 0;
    int hr  = int.tryParse(_controllers['hr']?.text ?? '') ?? 0;

    double o2   = double.tryParse(_controllers['o2']?.text ?? '') ?? 0.0;
    double temp = double.tryParse(_controllers['temp']?.text ?? '') ?? 0.0;

    // 2. SYNTAX: Invoke the parent callback via the 'widget.' prefix
    // This sends the integers and doubles running back up to your Patient List Screen
    widget.onAddVitals(sys, dia, hr, o2, temp);
  }
}