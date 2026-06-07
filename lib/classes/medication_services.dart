import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import 'database_manager.dart';

enum MedicationSafetyAudit {
  auditNotPerformed, interactionsNotDetected, interactionsDetected
}

// InteractionConflict
class InteractionConflict {
  final String primaryMedName;
  final String conflictingMedName;
  final String interaction;

  InteractionConflict({
    required this.primaryMedName,
    required this.conflictingMedName,
    required this.interaction,
  });

  // Returns a clean string for the Chip UI
  String get conflictDetail => "$conflictingMedName ($interaction)";

  // Basic string getters
  String get primary => primaryMedName;
  String get conflicting => conflictingMedName;
  String get type => interaction;

  // A helper getter for a formatted summary string
  String get description => "$primaryMedName interacts with $conflictingMedName";
  // Boilerplate for equality checks (important for List comparison)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is InteractionConflict &&
              runtimeType == other.runtimeType &&
              primaryMedName == other.primaryMedName &&
              conflictingMedName == other.conflictingMedName &&
              interaction == other.interaction;

  bool hasInteraction(String medicationName ) => ((primaryMedName == medicationName)  && (primaryMedName != conflictingMedName));
  @override
  int get hashCode =>
      primaryMedName.hashCode ^
      conflictingMedName.hashCode ^
      interaction.hashCode;

  // Handy for debugging in the console
  @override
  String toString() => 'Conflict: $primaryMedName <-> $conflictingMedName on $interaction';
}

class Medication {
  final String setId;
  final String genericName;
  final String brandName;
  final bool hasLocalDataSheet;
  final Map<String, String> datasheetSections;
  final bool hasInteractionAlert;

  Medication({
    required this.setId,
    required this.genericName,
    required this.brandName,
    required this.hasLocalDataSheet,
    required this.datasheetSections,
    this.hasInteractionAlert = false,
  });

  factory Medication.fromFdaJson(Map<String, dynamic> json, {String classString = "", bool alert = false}) {
    final openFda = json['openfda'] ?? {};

    String getSection(String key) {
      List<dynamic>? section = json[key];
      return (section != null && section.isNotEmpty) ? section.join('\n\n') : "";
    }

    return Medication(
      setId: json['set_id'] ?? '',
      genericName: (openFda['generic_name'] as List?)?.first ?? 'Unknown Medication',
      brandName: (openFda['brand_name'] as List?)?.first ?? '',
      hasLocalDataSheet: json['has_local_dataset']==1,
      hasInteractionAlert: alert,
      datasheetSections: {
        'Boxed Warning': getSection('boxed_warning'),
        'Indications': getSection('indications_and_usage'),
        'Contraindications': getSection('contraindications'),
        'Dosage': getSection('dosage_and_administration'),
        'Interactions': getSection('drug_interactions'),
        'Precautions': getSection('warnings_and_cautions'),
        'Side Effects': getSection('adverse_reactions'),
      }..removeWhere((key, value) => value.isEmpty),
    );
  }

  String get interactionsText {
    return (datasheetSections['Interactions'] ?? "").toLowerCase();
  }

  // Helper for your bilateral scan logic
  bool containsClass(String className) {
    return interactionsText.contains(className.toLowerCase());
  }

}

class MedicationService {
  // Helper to pull the ID out of the messy FDA structure
  static String? _extractRxcui(Map<String, dynamic> fdaMap) {
    try {
      final openFda = fdaMap['openfda'] ?? {};
      final List? rxcuiList = openFda['rxcui'] as List?;
      return rxcuiList?.first?.toString();
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDrugDataSheet(String medicationId, String name, String setId) async {
    final db = DatabaseManager();

    // --- 1. THE SYNC CHECK ---
    // Check if we already have the datasheet row in the local DB.
    Map<String, dynamic>? localData = setId.isNotEmpty
        ? await db.getStoredDatasheet(setId)
        : null;

    if (localData == null) {
      debugPrint('Local record missing for $name. Syncing from FDA...');

      // Inline FDA Search Logic
      String query = RegExp(r'^\d+$').hasMatch(name)
          ? 'openfda.rxcui:"$name"'
          : '(openfda.generic_name:"$name"+openfda.brand_name:"$name")';

      final url = Uri.parse('https://api.fda.gov/drug/label.json?search=$query&limit=1');

      try {
        final response = await http.get(url).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final Map<String, dynamic> result = data['results'][0];

          // Resolve IDs
          final String newSetId = result['set_id'] ?? result['id'] ?? "";

          // Resolve Classes (Pharmacologic Classes)
          final String? rxcui = _extractRxcui(result);
          String classTags = "";
          if (rxcui != null && rxcui.isNotEmpty) {
            classTags = await fetchClassesByRxcui(rxcui);
          }
          if (classTags.isEmpty) {
            classTags = await fetchClassesFromRxNav(name);
          }

          // --- 2. THE PERSISTENCE ---
          // Save the datasheet blob and the classes string to the datasheet table
          await db.saveDatasheet(result, classTags);

          // Update the medication table to link the setId and flip has_local_datasheet to 1
          await db.updateMedicationSetId(medicationId, newSetId);

          // Update localData by pulling the newly saved row
          localData = await db.getStoredDatasheet(newSetId);
        } else {
          debugPrint("FDA API returned ${response.statusCode}");
          return null;
        }
      } catch (e) {
        debugPrint("Network failure during sync: $e");
        return null;
      }
    }

    // --- 3. THE RETRIEVAL (Source of Truth) ---
    // We return the raw database map.
    // The widget will handle the jsonDecode of the blob and the split() of the classes string.
    return localData;
  }

  static Future<List<String>> getPotentialMatches(String partialName) async {
    if (partialName.isEmpty) return [];

    final url = Uri.parse(
        "https://rxnav.nlm.nih.gov/REST/approximateTerm.json?term=$partialName&maxEntries=5"
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List? candidates = data['approximateGroup']?['candidate'];

        if (candidates != null) {
          return candidates
              .map((c) => c['name']?.toString()) // Use null-safe access
              .where((name) => name != null && name.isNotEmpty) // Filter out nulls/empties
              .cast<String>() // Cast to a non-nullable String list
              .toSet() // Remove duplicates
              .toList();
        }
      }
    } catch (e) {
      debugPrint("RxNav Suggestion Error: $e");
    }
    return [];
  }

  static Future<String> fetchClassesFromRxNav(String medicationName) async {
    final url = Uri.parse("https://rxnav.nlm.nih.gov/REST/rxclass/class/byDrugName.json?drugName=$medicationName");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List infoList = data['rxclassDrugInfoList']?['rxclassDrugInfo'] ?? [];
        return infoList
            .where((item) => (item['rxclassMinConceptItem']?['classType'] ?? "").contains("EPC"))
            .map((item) => (item['rxclassMinConceptItem']?['className']?.toString() ?? "").replaceAll(RegExp(r'\[.*?\]'), '').trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .join(', ');
      }
    } catch (e) { debugPrint("RxNav Parse Error: $e"); }
    return "";
  }

  static Future<String> fetchClassesByRxcui(String rxcui) async {
    if (rxcui.isEmpty) return "";
    final url = Uri.parse("https://rxnav.nlm.nih.gov/REST/rxclass/class/byRxcui.json?rxcui=$rxcui");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List infoList = data['rxclassDrugInfoList']?['rxclassDrugInfo'] ?? [];
        return infoList
            .where((item) => item['rxclassMinConceptItem']?['classType'] == "EPC")
            .map((item) => (item['rxclassMinConceptItem']?['className']?.toString() ?? "").replaceAll(RegExp(r'\[.*?\]'), '').trim())
            .where((name) => name.isNotEmpty && name.toLowerCase() != "other")
            .toSet()
            .join(', ');
      }
    } catch (e) { debugPrint("RxNav API Error: $e"); }
    return "";
  }


}