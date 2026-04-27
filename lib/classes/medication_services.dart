import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

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

  static Future<Medication?> getDrugDataSheet(String name) async {
    // We use quotes around the name to handle multi-word generic names
    final url = Uri.parse(
        'https://api.fda.gov/drug/label.json?search=openfda.generic_name:"$name"+AND+openfda.product_type:"HUMAN+PRESCRIPTION+DRUG"&limit=1'
    );

    try {
      final response = await http.get(url, headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['results'] != null && data['results'].isNotEmpty) {
          // Pass the first result to our factory
          return Medication.fromFdaJson(data['results'][0]);
        }
      } else {
        debugPrint('FDA API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection Error: $e');
    }

    return null; // Return null if not found or error occurred
  }


  static Future<Map<String, dynamic>?> checkInteractions(List<String> names) async {

  }


}
