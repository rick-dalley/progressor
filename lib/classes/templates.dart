
// Helper for the POC to provide the "Gauge" configuration
import 'dart:convert';

import 'package:flutter/services.dart';

class Templates {
  static Future<Map<String, dynamic>> getTemplate(String fileName) async {
    try {
      // Load the JSON string from the assets folder
      final String response = await rootBundle.loadString('assets/questionnaires/$fileName');

      // Decode the string into a Map
      final data = await json.decode(response);

      return data as Map<String, dynamic>;
    } catch (e) {
      // Basic error handling for the demo
      return {};
    }
  }

}