import 'package:material_symbols_icons/symbols.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/medication_services.dart';
import '../classes/patient.dart';
import '../widgets/medication_card.dart';
import '../widgets/text_scanner.dart';

enum BannerType { acknowledged, advisory, critical, none, unknown }

class BannerData {
  final Color color;
  final String message;
  final IconData icon;

  const BannerData({required this.color, required this.message, required this.icon});

  Color get bannerColor => color.withAlpha(128);
}

// Fixed map syntax using standard key: value pairs
final Map<BannerType, BannerData> banners = {
  BannerType.critical: const BannerData(
    color: Color(0xFFD32F2F),
    message: "CRITICAL: Contraindication Detected",
    icon: Symbols.join_inner,
  ),
  BannerType.advisory: const BannerData(
    color: Color(0xFFFF8F00),
    message: "ADVISORY: Precautions Required",
    icon: Symbols.warning_amber_rounded,
  ),
  BannerType.acknowledged: const BannerData(
    color: Color(0xFF673AB7),
    message: "All Risks Acknowledged & Accepted",
    icon: Icons.check_circle_outline,
  ),
  BannerType.none: const BannerData(
    color: Color(0xFF2E7D32),
    message: "No Interactions Detected",
    icon: Symbols.verified,
  ),
  BannerType.unknown: const BannerData(
    color: Color(0xFF888888),
    message: "Not yet checked",
    icon: Symbols.unknown_document,
  ),
};

class MedicationScreen extends StatefulWidget {
  final Patient patient;

  const MedicationScreen({super.key, required this.patient});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  // Mocking the current baseline list
  bool _isLoading = false;
  bool _hasContraIndications = false;
  final bool _acceptedIndications = false;
  List<Map<String, dynamic>> _meds = [];
  final List<InteractionConflict> _currentConflicts = []; // The source of truth for the UI
  bool _auditRun = false;

  // These are derived flags
  final bool _hasPrecautions = false; // Set this based on your separate logic
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  late int _dataSheetCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMedsForPatient();
    _runSafetyAudit();
  }

  int _countDataSheets() {
    int count = 0;
    if (_meds.isNotEmpty) {
      for (dynamic m in _meds) {
        if (m["has_local_datasheet"] > 0) {
          count++;
        }
      }
    }
    return count;
  }

  Future<void> _loadMedsForPatient() async {
    try {
      // 1. Call the database instead of the JSON asset
      final List<Map<String, dynamic>> dbMeds = await DatabaseManager().getMedicationsForPatient(
        widget.patient.patientUuid,
      );

      setState(() {
        // 2. We need to create a mutable copy because db results are read-only
        _meds = dbMeds.map((m) => Map<String, dynamic>.from(m)).toList();
        _runSafetyAudit();

        // 3. Inject your UI-specific state (Severity)
        for (var med in _meds) {
          med['severity'] = med['severity'] ?? 'Neutral';
        }
      });
    } catch (e) {
      debugPrint("Error loading medications from DB: $e");
    }
  }

  void _runSafetyAudit() async {
    _dataSheetCount = _countDataSheets();
    // Guard clause: Don't spend processing cycles if the list hasn't loaded yet
    if (_meds.isEmpty || _dataSheetCount < 2) return;

    setState(() {
      _isLoading = true;
      _currentConflicts.clear();
    });

    for (var primaryMed in _meds) {
      // 1. Defend against null values coming from SQLite mapping
      final String nameA = primaryMed['name'] ?? '';
      primaryMed['has_interaction'] = 0;

      if (nameA.isEmpty) continue; // 2. Skip audit logic if it has no FDA set_id synced yet

      for (var otherMed in _meds) {
        final String nameB = otherMed['name'] ?? '';
        if (nameB.isEmpty || nameA == nameB) continue;
        final String? interaction = await DatabaseManager().getInteractions(nameA, nameB);


        if (interaction != null) {
          _currentConflicts.add(
            InteractionConflict(
              primaryMedName: primaryMed['name'],
              conflictingMedName: otherMed['name'],
              interaction: interaction,
            ),
          );

          setState(() => primaryMed['has_interaction'] = 1);
        }
      }
    }

    setState(() {
      _isLoading = false;
      _auditRun = true;
      _hasContraIndications = _currentConflicts.isNotEmpty;
    });
  }

  Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _confirmAndSave() {
    // 1. Calculate the audit result index
    int auditResultIndex;

    if (!_auditRun) {
      // User didn't trigger the safety check
      auditResultIndex = MedicationSafetyAudit.auditNotPerformed.index;
    } else if (_currentConflicts.isNotEmpty) {
      // Audit ran and found issues
      auditResultIndex = MedicationSafetyAudit.interactionsDetected.index;
    } else {
      // Audit ran and cleared
      auditResultIndex = MedicationSafetyAudit.interactionsNotDetected.index;
    }

    // 2. Return the data map back to the Roster
    Navigator.pop(context, {'medications': _meds.length, 'medication_safety_audit': auditResultIndex});
  }

  // Logic-driven Banner Widget
  Widget _buildStatusBanner() {
    _dataSheetCount = _countDataSheets();
    if (_meds.isEmpty || _dataSheetCount < 2) {
      return SizedBox(height: 0);
    }
    // Determine state based on your list logic
    BannerData bannerData;
    // Example Logic check:
    if (!_auditRun) {
      bannerData = banners[BannerType.unknown]!;
    } else if (_hasContraIndications) {
      bannerData = banners[BannerType.critical]!;
    } else if (_hasPrecautions) {
      bannerData = banners[BannerType.advisory]!;
    } else if (_acceptedIndications) {
      bannerData = banners[BannerType.acknowledged]!;
    } else {
      bannerData = banners[BannerType.none]!;
    }

    return Container(
      width: double.infinity,
      color: AppTheme.lightTheme.canvasColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          if (_meds.length > 1) Icon(bannerData.icon, color: bannerData.color, size: 20),
          if (_meds.length > 1) const SizedBox(width: 12),
          if (_meds.length > 1)
            Expanded(
              child: Text(
                bannerData.message,
                style: TextStyle(color: bannerData.color, fontWeight: FontWeight.bold),
              ),
            ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: OutlinedButton.icon(
                onPressed: _runSafetyAudit,
                icon: const Icon(Symbols.fact_check, color: Colors.white),
                label: const Text("RE-CHECK"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.lightTheme.primaryColor,
                ),
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
        "patient_uuid": widget.patient.patientUuid,
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
        _refreshMedInUI(medId, drugDataSheet['set_id']);
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

  void _startBarcodeScanner() async {
    // Use a simple full-screen modal or a dedicated camera route
    final String? scannedResult = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BarcodeScannerModal(),
    );

    if (scannedResult != null) {
      // We found something!
      setState(() {
        // For now, let's assume the result is the DIN
        // In the future, this is where you'd trigger your API lookup
        _nameController.text = "Loading Med for $scannedResult...";
        _doseController.text = ""; // Placeholder until sync/lookup finishes
      });

      // Auto-trigger your existing lookup logic
      // This matches the background sync you already have in _addMedication
      _lookupAndAdd(scannedResult);
    }
  }

  // A helper to handle the lookup after scanning
  void _lookupAndAdd(String barcodeValue) {
    // Check if it's a known DIN (like your Amlodipine example)
    if (barcodeValue == "02331292") {
      setState(() {
        _nameController.text = "Amlodipine";
        _doseController.text = "10 MG Oral Tablet";
      });
    } else {
      // If not in your "local" demo cache, use your existing name field
      // to start the background sync process you've already built
      _nameController.text = barcodeValue;
      _addMedication();
    }
  }

  void _showAddMedicationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Crucial to keep keyboard from covering fields
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // Moves with keyboard
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // Modal only takes as much space as needed
          children: [
            // OPTION 1: THE SCANNER "HOOK"
            InkWell(
              onTap: () {
                Navigator.pop(context); // Close modal
                _startBarcodeScanner(); // Trigger your camera logic
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.deepLogicViolet.withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.deepLogicViolet),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, color: AppTheme.deepLogicViolet),
                    SizedBox(width: 12),
                    Text(
                      "SCAN BOTTLE BARCODE",
                      style: TextStyle(color: AppTheme.deepLogicViolet, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text("OR ENTER MANUALLY", style: TextStyle(fontSize: 10, color: Colors.white38)),
            const SizedBox(height: 12),

            // OPTION 2: YOUR ORIGINAL FORM FIELDS
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Medication Name"),
            ),
            TextField(
              controller: _doseController,
              decoration: const InputDecoration(labelText: "Dosage (e.g. 10mg)"),
            ),
            const SizedBox(height: 20),

            // RE-USING YOUR _addMedication LOGIC
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _addMedication(); // Your existing function
                  Navigator.pop(context); // Close modal
                },
                child: const Text("ADD TO LIST"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = "${widget.patient.firstName} ${widget.patient.lastName}";
    return Scaffold(
      appBar: AppBar(
        title: Text("Medications: $name"),
        actions: [
          TextButton(
            // 1. Call the function directly.
            // Do NOT pop here; let _confirmAndSave handle the navigation.
            onPressed: _isLoading ? null : _confirmAndSave,
            child: const Text("SAVE", style: TextStyle(color: Colors.white)),
          ),
        ],
        backgroundColor: AppTheme.clinicalWhite, // Your Navy brand color
        foregroundColor: AppTheme.deepLogicViolet,
      ),
      // The Floating Action Button replaces the top form
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMedicationSheet(),
        label: const Text("ADD MEDICATION"),
        icon: const Icon(Symbols.pill),
        backgroundColor: AppTheme.deepLogicViolet,
        foregroundColor: AppTheme.clinicalWhite,
      ),

      body: Column(
        children: [
          _buildStatusBanner(),
          // CURRENT LIST: The Baseline
          Expanded(
            child: ListView.builder(
              itemCount: _meds.length,
              itemBuilder: (context, index) {
                final med = _meds[index];

                // We swap the old ListTile for our new smart card
                return MedicationCard(
                  key: ValueKey(med['id']),
                  interactions: _currentConflicts,
                  medData: med,
                  onDelete: () async {
                    final String medIdToDelete = med['id'];

                    // 1. Remove from the local database
                    await DatabaseManager().deleteMedication(medIdToDelete);

                    // 2. Remove from the UI state
                    setState(() {
                      _meds.removeAt(index);
                      _dataSheetCount = _countDataSheets();
                    });
                  },
                  onExpansionChanged: (isExpanded) {
                    setState(() {
                      med["has_local_datasheet"] = 1;
                      _dataSheetCount = _countDataSheets();
                    });
                  },
                );
              },
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

class _BarcodeScannerModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      color: Colors.black,
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            "ALIGN BARCODE",
            style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Your existing scanner logic, configured for Barcodes
                TextScanner(
                  onTextDetected: (text) {
                    // Search for an 8-digit sequence (DIN) in the OCR
                    final dinRegex = RegExp(r'\b\d{8}\b');
                    final match = dinRegex.firstMatch(text.text);
                    if (match != null) {
                      Navigator.pop(context, match.group(0));
                    }
                  },
                ),
                // Visual "Scope" to help the clinician
                Container(
                  width: 280,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
