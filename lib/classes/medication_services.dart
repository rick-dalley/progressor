import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import 'database_manager.dart';
class Medication {
  final String setId;
  final String genericName;
  final String brandName;
  final List<String> classes; // New field for semantic categories
  final Map<String, String> datasheetSections;
  final bool hasInteractionAlert;

  Medication({
    required this.setId,
    required this.genericName,
    required this.brandName,
    required this.classes,
    required this.datasheetSections,
    this.hasInteractionAlert = false,
  });

  factory Medication.fromFdaJson(Map<String, dynamic> json, {String classString = "", bool alert = false}) {
    final openFda = json['openfda'] ?? {};

    String getSection(String key) {
      List<dynamic>? section = json[key];
      return (section != null && section.isNotEmpty) ? section.join('\n\n') : "";
    }

    // Convert the comma-separated string from the DB into a clean list
    List<String> classList = classString.isNotEmpty
        ? classString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : [];

    return Medication(
      setId: json['set_id'] ?? '',
      genericName: (openFda['generic_name'] as List?)?.first ?? 'Unknown Medication',
      brandName: (openFda['brand_name'] as List?)?.first ?? '',
      classes: classList, // Populated from our RxNav/DB pipeline
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

  static Future<Medication?> getDrugDataSheet(String medicationId, String name, String setId) async {
    final db = DatabaseManager();

    // 1. Check local DB first
    if (setId.isNotEmpty) {
      final localData = await db.getStoredDatasheet(setId);
      if (localData != null) {
        String? savedClasses = localData['classes'];
        final Map<String, dynamic> rawJson = jsonDecode(localData['raw_json_blob']);

        if (savedClasses == null || savedClasses.isEmpty) {
          debugPrint('Repairing local record: Fetching missing classes for $name');

          // Use RXCUI if available, otherwise fallback to name
          final String? rxcui = _extractRxcui(rawJson);
          if (rxcui != null && rxcui.isNotEmpty) {
            savedClasses = await fetchClassesByRxcui(rxcui);
          }

          if (savedClasses == null || savedClasses.isEmpty) {
            savedClasses = await fetchClassesFromRxNav(name);
          }

          await db.updateDatasheetClasses(setId, savedClasses);
        }

        return Medication.fromFdaJson(rawJson, classString: savedClasses);
      }
    }

    // 2. Build the URL
    final String query = setId.isNotEmpty
        ? 'set_id:"$setId"'
        : 'openfda.generic_name:"$name"+AND+openfda.product_type:"HUMAN+PRESCRIPTION+DRUG"';

    final url = Uri.parse('https://api.fda.gov/drug/label.json?search=$query&limit=1');

    try {
      final response = await http.get(url, headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          String newSetId = result['set_id'];

          await db.saveDatasheet(result);
          await db.updateMedicationSetId(medicationId, newSetId);

          // Use RXCUI if available, otherwise fallback to name
          final String? rxcui = _extractRxcui(result);
          String classTags = "";

          if (rxcui != null && rxcui.isNotEmpty) {
            classTags = await fetchClassesByRxcui(rxcui);
          }

          if (classTags.isEmpty) {
            classTags = await fetchClassesFromRxNav(name);
          }

          await db.updateDatasheetClasses(newSetId, classTags);
          return Medication.fromFdaJson(result, classString: classTags);
        }
      }
    } catch (e) {
      debugPrint('Connection Error: $e');
    }
    return null;
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

  static Future<Map<String, dynamic>?> checkInteractions(List<String> names) async {
    return null;
  }
}