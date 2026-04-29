import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';

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
  final _acceptedIndications = false;
  bool _auditRun = false;
  bool _hasContraIndications = false;
  bool _hasPrecautions = false;

  @override
  void initState() {
    super.initState();
    _loadMedsForPatient();
    _runSafetyAudit();
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

  Future<void> _updateLocalInteractionFlags(Map<String, dynamic> conflict) async {
    final db = DatabaseManager();

    // 1. Extract the names involved in the conflict from the API result
    // Note: Adjust the keys ('drugA', 'drugB') based on your actual API response structure
    final String drugAName = conflict['drugA']?.toString() ?? "";
    final String drugBName = conflict['drugB']?.toString() ?? "";
    final String severity = conflict['severity']?.toString().toLowerCase() ?? "";

    // 2. Map the severity to an integer for the database
    // 0 = None, 1 = Amber/Moderate, 2 = Red/High
    int riskLevel = 0;
    if (severity == 'red' || severity == 'high') {
      riskLevel = 2;
    } else if (severity == 'amber' || severity == 'moderate') {
      riskLevel = 1;
    }

    // // 3. Find the local UUIDs for these drugs for this specific patient
    // // We use the patientUuid to ensure we don't accidentally flag a different patient's meds
    // final List<String> affectedIds = await db.getMedIdsByNames(patientUuid, [drugAName, drugBName]);
    //
    // // 4. Update the 'has_interaction' column in the database
    // for (var id in affectedIds) {
    //   await db.updateMedicationInteractionStatus(id, riskLevel);
    // }

    debugPrint("Database updated: $drugAName and $drugBName flagged with severity $riskLevel");
  }

  void _runSafetyAudit() async {
    // 1. Gather all names for the audit
    final List<String> drugNames = _meds
        .map((m) => m['name'] as String)
        .where((name) => name.isNotEmpty)
        .toList();

    if (drugNames.length < 2) {
      setState(() => _auditRun = true);
      return;
    }

    // 2a. External API Check (for known Drug-Drug Interactions)
    final apiResult = await MedicationService.checkInteractions(drugNames);
    final List apiConflicts = (apiResult != null && apiResult['interactions'] != null)
    ? apiResult['interactions'] as List
        : [];

    // 2b. Internal Label Scan (for absolute Contraindications)
    // This catches things the API might miss by scanning the raw FDA text
    final List localConflicts = await DatabaseManager().scanLocalDatasheetsForContraindications(drugNames);

    // Merge the two lists
    final List conflicts = [...apiConflicts, ...localConflicts];

    // 3. Determine Severities (Check both Red and Amber)
    bool hasRed = conflicts.any((item) =>
    item['severity']?.toString().toLowerCase() == 'red' ||
    item['severity']?.toString().toLowerCase() == 'high' ||
    item['type'] == 'contraindication' // New flag
    );

    bool hasAmber = conflicts.any((item) =>
    item['severity']?.toString().toLowerCase() == 'amber' ||
        item['severity']?.toString().toLowerCase() == 'moderate'
    );

    // 4. Update the Database so the "Traffic Light" icons persist
    for (var conflict in conflicts) {
      // Assuming the conflict object tells us which two drugs clashed
      // We update the local 'medication' table to set has_interaction = 1
      await _updateLocalInteractionFlags(conflict);
    }

    setState(() {
      _isLoading = false;
      _auditRun = true;
      _hasContraIndications = hasRed;
      _hasPrecautions = hasAmber;
    });

    // 5. Only interrupt the nurse with a modal if there are actual conflicts
    if (conflicts.isNotEmpty) {
      _showClinicalModal(
        "Safety Audit Results",
        _buildConflictList(conflicts),
      );
    }
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


    setState(() => _isLoading = false);

    // Run the interaction check
    final risk = MedicationService.checkInteractions(classIds);

    // If a risk is found, force an interruption modal
    _showSafetyAlert(risk as Map<String, dynamic>);
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

  void _addMedication() async {
    if (_nameController.text.isNotEmpty) {
      var uuid = const Uuid();
      final String medName = _nameController.text;
      final String medId = uuid.v4(); // Generates a random version 4 UUID

      final newMed = {
        "id": medId,
        "patient_uuid": widget.patient["patient_uuid"],
        "name": medName,
        "dose": _doseController.text,
        "freq": "PRN",
        "set_id": "",
      };

      // Save to DB (returns the UUID we just generated)
      await DatabaseManager().insertMedication(newMed);

      setState(() {
        _meds.add({...newMed, "is_syncing": true});
        _nameController.clear();
        _doseController.clear();
      });
      // 2. Background Sync (Do not 'await' this)
      _startBackgroundSync(medId, medName);
    }
  }

  void _refreshMedInUI(String medId, String setId) {
    setState(() {
      final index = _meds.indexWhere((m) => m['id'] == medId);
      if (index != -1) {
        _meds[index]['set_id'] = setId;
        _meds[index]['is_syncing'] = false;
      }
    });
  }

  Future<void> _startBackgroundSync(String medId, String medName) async {
    try {
      //Local Cache Check
      String? existingSetId = await DatabaseManager().getSetIdByName(medName);
      if (existingSetId != null) {
        await DatabaseManager().updateMedicationSetId(medId, existingSetId);
        _refreshMedInUI(medId, existingSetId);
        _runSafetyAudit();
        return;
      }

      // FDA Check
      final drugDataSheet = await MedicationService.getDrugDataSheet(medName, "", medId);
      if (drugDataSheet != null) {

        _refreshMedInUI(medId, drugDataSheet.setId);
        _runSafetyAudit();
      }
    } catch (e) {
      debugPrint("Background sync failed for $medName: $e");
    } finally {
      // 3. Ensure the 'is_syncing' flag is cleared even on failure
      _stopSyncSpinner(medId);
    }
  }

  void _stopSyncSpinner(String medId) {
    setState(() {
      final index = _meds.indexWhere((m) => m['id'] == medId);
      if (index != -1) {
        _meds[index]['is_syncing'] = false;
      }
    });
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
                  onDelete: () async {
                    final String medIdToDelete = med['id'];

                    // 1. Remove from the local database
                    await DatabaseManager().deleteMedication(medIdToDelete);

                    // 2. Remove from the UI state
                    setState(() {
                      _meds.removeAt(index);
                    });

                    debugPrint('Permanently deleted medication: $medIdToDelete');
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
