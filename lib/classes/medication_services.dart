import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import 'database_manager.dart';

class Medication {
  final String setId;
  final String genericName;
  final String brandName;
  final Map<String, String> datasheetSections;
  final bool hasInteractionAlert;

  Medication({
    required this.setId,
    required this.genericName,
    required this.brandName,
    required this.datasheetSections,
    this.hasInteractionAlert = false,
  });

  factory Medication.fromFdaJson(Map<String, dynamic> json, {bool alert = false}) {
    final openFda = json['openfda'] ?? {};

    // Helper to join FDA arrays into a single string
    String getSection(String key) {
      List<dynamic>? section = json[key];
      return (section != null && section.isNotEmpty) ? section.join('\n\n') : "";
    }

    return Medication(
      setId: json['set_id'] ?? '',
      genericName: (openFda['generic_name'] as List?)?.first ?? 'Unknown Medication',
      brandName: (openFda['brand_name'] as List?)?.first ?? '',
      hasInteractionAlert: alert,
      datasheetSections: {
        'Boxed Warning': getSection('boxed_warning'),
        'Indications': getSection('indications_and_usage'),
        'Dosage': getSection('dosage_and_administration'),
        'Interactions': getSection('drug_interactions'),
        'Precautions': getSection('warnings_and_cautions'),
        'Side Effects': getSection('adverse_reactions'),
      }..removeWhere((key, value) => value.isEmpty), // Only keep non-empty sections
    );
  }
}

class MedicationService {

  static Future<Medication?> getDrugDataSheet(String medication_id, String name, String set_id) async {
    final db = DatabaseManager();

    // 1. Check local DB first
    if (set_id.isNotEmpty) {
      final localData = await db.getStoredDatasheet(set_id);
      if (localData != null) {
        debugPrint('Found local datasheet for: $name ($set_id)');
        return Medication.fromFdaJson(localData);
      }
    }

    // 2. Build the URL - Prefer set_id search over name search for accuracy
    final String query = set_id.isNotEmpty
        ? 'set_id:"$set_id"'
        : 'openfda.generic_name:"$name"+AND+openfda.product_type:"HUMAN+PRESCRIPTION+DRUG"';

    final url = Uri.parse('https://api.fda.gov/drug/label.json?search=$query&limit=1');

    try {
      final response = await http.get(url, headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          String newSetId = result['set_id'];
          // 3. Save to DB - The saveDatasheet method will peel off your
          // metadata columns (version, rxcui, etc.) and store the blob.
          await db.saveDatasheet(result);
          await db.updateMedicationSetId(medication_id, newSetId);
          return Medication.fromFdaJson(result);
        }
      } else {
        debugPrint('FDA API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection Error: $e');
    }

    return null;
  }


  static Future<Map<String, dynamic>?> checkInteractions(List<String> names) async {

  }


}
