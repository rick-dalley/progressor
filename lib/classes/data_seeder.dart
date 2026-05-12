import 'dart:convert';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class DataSeeder {
  /// Entry point for seeding data.
  /// Only executes in debug mode to prevent data pollution in release builds.
  static Future<void> seed(Database db) async {
    if (!kDebugMode) return;

    debugPrint('--- Starting Database Seeding ---');

    await _seedProcessMaps(db);
    await _seedPatientData(db);
    await _seedMedicationData(db);
    await _seedVitalsData(db);
    await _seedPatientCondition(db);

    debugPrint('--- Seeding Complete ---');
  }

  static Future<void> _seedPatientData(Database db) async {
    final String response = await rootBundle.loadString('assets/patients/patients.json');
    final List<dynamic> data = json.decode(response);

    Batch batch = db.batch();
    for (var entry in data) {
      batch.insert('patient', {
        'patient_uuid': entry['patient_uuid'],
        'first_name': entry['first_name'] ?? 'Unknown',
        'last_name': entry['last_name'] ?? 'Subject',
        'phn': entry['phn'],
        'dob': entry['dob'],
        'current_acuity': entry['current_acuity'] ?? 3,
        'status': entry['status'] ?? 'Active',
        'path': entry['path'],
        'narrative_hint': entry['narrative_hint'],
        'current_bp': entry['current_bp'],
        'current_spo2': entry['current_spo2'],
        'current_temp': entry['current_temp'],
        'current_pulse': entry['current_pulse'],
      });
    }
    await batch.commit(noResult: true);
    debugPrint('Patients seeded.');
  }

  static Future<void> _seedMedicationData(Database db) async {
    final String response = await rootBundle.loadString('assets/medications/meds.json');
    final List<dynamic> data = json.decode(response);

    Batch batch = db.batch();
    for (var patientEntry in data) {
      String patientUuid = patientEntry['patient_uuid'];
      for (var med in patientEntry['prescription']) {
        batch.insert('medication', {
          "id": med['id'],
          "patient_uuid": patientUuid,
          "name": med['name'],
          "dose": med['dose'],
          "freq": med['freq'],
          "has_local_datasheet": med['has_local_datasheet'],
          "set_id": "",
        });
      }
    }
    await batch.commit(noResult: true);
    debugPrint('Medications seeded.');
  }

  static Future<void> _seedProcessMaps(Database db) async {
    final String response = await rootBundle.loadString('assets/process/process.json');
    final List<dynamic> data = json.decode(response);

    for (var entry in data) {
      await db.insert(
        'process_maps',
        {
          "process_key": entry['process_key'],
          "label": entry['label'],
          "steps_json": entry['steps_json'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    debugPrint('Process maps seeded.');
  }
  static Future<void> _seedVitalsData(Database db) async {
    final String response = await rootBundle.loadString('assets/patients/readings.json');
    final List<dynamic> data = json.decode(response);

    Batch batch = db.batch();
    for (var entry in data) {
      batch.insert(
        'vitals', // Ensure this matches your CREATE TABLE name exactly
        {
          "id": entry['id'],
          "patient_uuid": entry['patient_uuid'],
          "pulse": entry['pulse'],
          "systolic": entry['systolic'],
          "diastolic": entry['diastolic'],
          "temperature": entry['temperature'],
          "o2": entry['o2'],
          "recorded_at": entry['recorded_at'],
        },
        // ADD THIS LINE:
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    debugPrint('Vitals seeded.');
  }

  //_seedPatientConditions
  static Future<void> _seedPatientCondition(Database db) async {
    try {
      final String response = await rootBundle.loadString(
        'assets/patients/conditions.json',
      );
      final List<dynamic> data = json.decode(response);

      Batch batch = db.batch();

      for (var entry in data) {
        batch.insert('patient_condition', {
          'patient_uuid': entry['patient_uuid'],
          'condition_name': entry['condition_name'],
          'treatment_notes': entry['treatment_notes'],
          'is_active': entry['is_active'] ?? 1,
          // Let the DB handle the recorded_at default
        });
      }

      await batch.commit(noResult: true);
      debugPrint('Patient conditions seeded from JSON.');
    } catch (e) {
      debugPrint('Error seeding patient conditions: $e');
    }
  }
}