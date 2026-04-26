import 'dart:convert';
import 'package:http/http.dart' as http;

class MedicationService {
  static const String _baseUrl = "https://rxnav.nlm.nih.gov/REST";

  // 1. Get RxCUI and ATC Class in one go
  static Future<Map<String, dynamic>> getDrugClass(String name) async {
    final url = Uri.parse("$_baseUrl/rxclass/class/byDrugName.json?drugName=$name&relaSource=ATC");
    final response = await http.get(url, headers: {"Accept": "application/json"});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['rxclassDrugInfoList']?['rxclassDrugInfo'];
      if (list != null && list.isNotEmpty) {
        return {
          "rxcui": list[0]['minConcept']['rxcui'],
          "className": list[0]['rxclassMinConceptItem']['className'],
          "classId": list[0]['rxclassMinConceptItem']['classId'],
        };
      }
    }
    return {};
  }

  // 2. Local Rules Engine (The "Slam Dunk" replacement for the dead DDI API)
  static String? checkInteraction(List<String> classIds) {
    // Logic: SSRI (N06AB) + Specific Opioids (N02AX) = Serotonin Syndrome
    if (classIds.contains("N06AB") && classIds.contains("N02AX")) {
      return "⚠️ Serotonin Syndrome Risk: Interaction detected between SSRI and specific Opioid classes.";
    }
    // Add other rules here as needed for your demo
    return null;
  }

  static Map<String, dynamic>? checkInteractions(List<String> classIds) {
    // Logic: SSRI (N06AB) + Opioid (N02AX) = Serotonin Syndrome
    if (classIds.contains("N06AB") && classIds.contains("N02AX")) {
      return {
        "severity": "CRITICAL",
        "warning": "Potential Serotonin Syndrome: High risk when combining SSRIs with specific opioids. Monitor for neuromuscular hyperactivity.",
        "color": "#D32F2F",
      };
    }

    // Logic: SSRI (N06AB) + Antipsychotic (N05AH) = QT Prolongation
    if (classIds.contains("N06AB") && classIds.contains("N05AH")) {
      return {
        "severity": "MODERATE",
        "warning": "Risk of QT Prolongation: Both medications can impact cardiac rhythm. Baseline ECG recommended.",
        "color": "#EF6C00",
      };
    }

    return null; // The "All Clear" signal
  }

}
