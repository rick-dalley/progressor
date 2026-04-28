import 'dart:convert';
import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../classes/database_manager.dart';
import '../classes/medication_services.dart';
import '../widgets/medication_card.dart';

class MedicationScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const MedicationScreen({super.key, required this.patient});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  // Mocking the current baseline list
  bool _isLoading = false;

  List<Map<String, dynamic>> _meds = [];

  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  bool _auditRun = false;
  bool _hasContraIndications = false;
  bool _hasPrecautions = false;
  bool _acceptedIndications = false;

  void _addMedication() async {
    if (_nameController.text.isNotEmpty) {
      var uuid = const Uuid();
      final String uniqueId = uuid.v4(); // Generates a random version 4 UUID

      final newMed = {
        "id": uniqueId,
        "patient_uuid": widget.patient["patient_uuid"],
        "name": _nameController.text,
        "dose": _doseController.text,
        "freq": "PRN",
        "set_id": "",
      };

      // Save to DB (returns the UUID we just generated)
      await DatabaseManager().insertMedication(newMed);

      setState(() {
        _meds.add(newMed);
        _nameController.clear();
        _doseController.clear();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMedsForPatient();
  }
  Future<void> _loadMedsForPatient() async {
    try {
      // 1. Call the database instead of the JSON asset
      final List<Map<String, dynamic>> dbMeds = await DatabaseManager()
          .getMedicationsForPatient(widget.patient['patient_uuid']);

      setState(() {
        // 2. We need to create a mutable copy because db results are read-only
        _meds = dbMeds.map((m) => Map<String, dynamic>.from(m)).toList();

        // 3. Inject your UI-specific state (Severity)
        for (var med in _meds) {
          med['severity'] = med['severity'] ?? 'Neutral';
        }
      });

      debugPrint("Loaded ${_meds.length} meds from DB for ${widget.patient['patient_uuid']}");
    } catch (e) {
      debugPrint("Error loading medications from DB: $e");
    }
  }

  // Helper to show the Bottom Sheet
  void _showClinicalModal(String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictList(List items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        // Cast the item to a Map for safe access
        final data = item as Map<String, dynamic>;
        final bool isCritical = data['severity'] == 'Red';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isCritical ? Icons.block : Icons.warning_amber_rounded,
                color: isCritical ? Colors.red : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['pair'] ?? "Unknown Interaction",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      data['desc'] ?? "No description provided.",
                      style: TextStyle(color: Colors.grey[800], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSafeMessage() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.verified, color: Colors.green, size: 48),
        const SizedBox(height: 16),
        const Text(
          "Medication List Safe",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          "The safety audit detected no contraindications or precautions for the current regimen.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[700]),
        ),
      ],
    );
  }

  // Multi-Drug Audit
  void _runSafetyAudit() async {
    List<String> classIds = [];
    for (var med in _meds) {
      final info = await MedicationService.getDrugDataSheet(med['id'], med['name']!, med['set_id']);

    }

    final warning = MedicationService.checkInteractions(classIds);
    setState(() {
      _isLoading = false;
      _auditRun = true;
      _hasContraIndications = false;
      _hasPrecautions = false;
      _acceptedIndications = false;
    });

      // 1. Get the names from your _meds list
      final List<String> drugNames = _meds.map((m) => m['name'] as String).toList();

      // 2. Hit the "Clean Pipe" service we designed
      final result = await MedicationService.checkInteractions(drugNames);
    final List conflicts = (result != null && result['interactions'] != null)
        ? result['interactions'] as List
        : [];
      setState(() {
        _isLoading = false;
        _auditRun = true;
        //_sortMedsByRisk(); // Re-sort based on NIH findings
      });

    bool hasRed = conflicts.any((item) => item['severity'] == 'Red' || item['severity'] == 'high');
    bool hasAmber = conflicts.any((item) => item['severity'] == 'Amber' || item['severity'] == 'moderate'); //or 'Orange' depending on your API

    setState(() {
      _auditRun = true;
      if (hasRed) {
        _hasContraIndications = hasRed; // Red
      } else if (hasAmber) {
        _hasPrecautions = hasAmber; // Amber
      }
      //_sortMedsByRisk(); // Moves the highest level risks to the top
    });

    _showClinicalModal(
      "Safety Audit Results",
      conflicts.isNotEmpty
          ? _buildConflictList(conflicts) // Pass the already-extracted list
          : _buildSafeMessage(), // The "Clearance" path
    );
  }

  Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _confirmAndSave() async {
    setState(() => _isLoading = true);

    List<String> classIds = [];

    // 1. Audit every drug in the list live
    for (var med in _meds) {
      final data = await MedicationService.getDrugDataSheet(med['id'],med['name']!, med['set_id']);

    }

    setState(() => _isLoading = false);

    // 2. Run the interaction check
    final risk = MedicationService.checkInteractions(classIds);

    if (risk != null) {
      // If a risk is found, force an interruption modal
      _showSafetyAlert(risk as Map<String, dynamic>);
    } else {
      // All clear - return the list to the previous screen
      Navigator.pop(context, _meds);
    }
  }

  void _showSafetyAlert(Map<String, dynamic> risk) {
    final alertColor = fromHex(risk['color']);
    showDialog(
      context: context,
      barrierDismissible: false, // Force interaction
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: alertColor),
            const SizedBox(width: 10),
            const Text("SAFETY ALERT"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "SEVERITY: ${risk['severity']}",
              style: TextStyle(fontWeight: FontWeight.bold, color: alertColor),
            ),
            const SizedBox(height: 10),
            Text(risk['warning']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Go back to edit meds
            child: const Text("GO BACK & EDIT"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, _meds); // Proceed with save
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
            ),
            child: const Text("ACKNOWLEDGE & SAVE ANYWAY"),
          ),
        ],
      ),
    );
  }

  // Logic-driven Banner Widget
  Widget _buildStatusBanner() {
    // Determine state based on your list logic
    Color bannerColor;
    String message;
    IconData icon;

    // Example Logic check:
    if (!_auditRun) {
      bannerColor = Colors.grey[600]!;
      message = "Safety Audit: Status Unknown";
      icon = Icons.help_outline;
    } else if (_hasContraIndications) {
      bannerColor = const Color(0xFFD32F2F); // Red
      message = "CRITICAL: Contraindication Detected";
      icon = Icons.block;
    } else if (_hasPrecautions) {
      bannerColor = const Color(0xFFFF8F00); // Amber
      message = "ADVISORY: Precautions Required";
      icon = Icons.warning_amber_rounded;
    } else if (_acceptedIndications) {
      bannerColor = const Color(0xFF673AB7); // Purple
      message = "All Risks Acknowledged & Accepted";
      icon = Icons.check_circle_outline;
    } else {
      bannerColor = const Color(0xFF2E7D32); // Green
      message = "No Interactions Detected";
      icon = Icons.verified_user_outlined;
    }

    return Container(
      width: double.infinity,
      color: bannerColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = "${widget.patient['first_name']} ${widget.patient['last_name']}";

    return Scaffold(
      appBar: AppBar(
        title: Text("Medications: $name"),
        backgroundColor: const Color(0xFF1A365D), // Your Navy brand color
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildStatusBanner(),
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
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1A365D),
                  ),
                ),
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

                // We swap the old ListTile for our new smart card
                return MedicationCard(
                  medData: med,
                  onDelete: () {
                    setState(() {
                      _meds.removeAt(index);
                    });
                  },
                );
              },
            ),
          ),
          if (_meds.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: OutlinedButton.icon(
                onPressed: _runSafetyAudit,
                icon: const Icon(Icons.security, color: Colors.orange),
                label: const Text("RUN SAFETY AUDIT"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                ),
              ),
            ),
          // SAVE BAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              // 1. Call the function directly.
              // Do NOT pop here; let _confirmAndSave handle the navigation.
              onPressed: _isLoading ? null : _confirmAndSave,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFF1A365D),
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("CONFIRM BASELINE"),
            ),
          ),
        ],
      ),
    );
  }

}

class SafetyAudit {
  static const String severityMajor = "MAJOR / CONTRAINDICATED";
  static const String severityModerate = "MODERATE";

  // Using ATC Class IDs for robust logic
  static Map<String, dynamic>? run(List<String> classIds) {
    // 1. SSRI (N06AB) + Opioid (N02AX) -> Serotonin Syndrome
    if (classIds.contains("N06AB") && classIds.contains("N02AX")) {
      return {
        "severity": severityMajor,
        "warning":
            "Risk of Serotonin Syndrome: Potentially life-threatening interaction between SSRI and specific opioids.",
        "color": Colors.red,
      };
    }

    // 2. Sertraline (N06AB) + Quetiapine (N05AH) -> QT Prolongation
    if (classIds.contains("N06AB") && classIds.contains("N05AH")) {
      return {
        "severity": severityModerate,
        "warning":
            "Risk of QT Prolongation: Both medications can affect heart rhythm. Monitoring (ECG) may be required.",
        "color": Colors.orange,
      };
    }

    return null;
  }
}
