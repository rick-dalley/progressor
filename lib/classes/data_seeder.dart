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
    await _seedObservations(db);
    await _seedConditionsCatalog(db);

    debugPrint('--- Seeding Complete ---');
  }

  static Future<void> _seedConditionsCatalog(Database db) async {
    // 1. Verify if the master table has already been populated
    final List<Map<String, dynamic>> existingRecords = await db.rawQuery(
      "SELECT COUNT(*) as total FROM condition",
    );

    if (existingRecords.first['total'] as int > 0) {
      return; // Catalog is already successfully configured!
    }

    try {
      // 2. Read raw condition data groups from json asset bundle
      final String jsonString = await rootBundle.loadString('assets/conditions/conditions.json');
      final Map<String, dynamic> parsedJson = jsonDecode(jsonString);

      // 3. Open an atomic batch block for high-performance writing
      final Batch migrationBatch = db.batch();

      parsedJson.forEach((categoryKey, ailmentList) {
        if (ailmentList is List) {
          for (var ailmentName in ailmentList) {
            if (ailmentName is String) {

              // 🟢 Pass only name and category. SQLite generates the integer ID automatically!
              migrationBatch.insert(
                'condition',
                {
                  'name': ailmentName,
                  'category': categoryKey,
                },
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }
        }
      });

      // 4. Commit rows down to the storage engine
      await migrationBatch.commit(noResult: true);
      debugPrint("Successfully seeded master condition table with auto-increment keys.");
    } catch (error) {
      debugPrint("Critical failure executing master condition data migration: $error");
    }
  }

  static Future<void> _seedObservations(Database db) async {
    final String response = await rootBundle.loadString('assets/observations/observations.json');
    final List<dynamic> data = json.decode(response);

    Batch batch = db.batch();
    for (var entry in data) {
      batch.insert('observations', {
        // 'id':entry['id'],
        // 'timestamp': entry['timestamp'],
        'patient_uuid': entry['patient_uuid'],
        'content': entry['content'],
        'author_name': entry['author_name'],
        'author_role':entry['author_role'],
      });
    }
    await batch.commit(noResult: true);
    debugPrint('Observations seeded.');
  }

 static Future<void> _seedPatientData(Database db) async {
    // Parse the master JSON array
    // 1. Read the raw data directly from your local asset storage
    final String rawJsonString = await rootBundle.loadString('assets/patients/patients.json');
    final List<dynamic> decodedData = jsonDecode(rawJsonString);

    // Use a batch transaction block for optimal safety and insert velocity
    await db.transaction((txn) async {
      for (var item in decodedData) {
        if (item is! Map<String, dynamic>) continue;

        final String patientUuid = item['patient_uuid'];

        // 1. Build the clean Patient record map for insertion
        // We explicitly pull the top-level keys matching your core schema
        final Map<String, dynamic> patientRow = {
          'patient_uuid': patientUuid, // maps patient_uuid to local primary key id
          'first_name': item['first_name'],
          'last_name': item['last_name'],
          'phn': item['phn'],
          'email': item['email'],
          'ssn': item['ssn'],
          'title': item['title'],
          'city': item['city'],
          'country': item['country'],
          'street_address': item['street_address'],
          'province': item['province'],
          'postal_code': item['postal_code'],
          'dob': item['dob'],
          'admitted': item['admitted'],
          'current_acuity': item['current_acuity'],
          'police_reports': item['police_reports'],
          'assessments': item['assessments'],
          'status': item['status'],
          'path': item['path'],
          'current_pulse': item['current_pulse'],
          'current_systolic': item['current_systolic'],
          'current_diastolic': item['current_diastolic'],
          'current_temp': item['current_temp'],
          'current_spo2': item['current_spo2'],
          'phone': item['phone'],
          'family_doctor_phone': item['family_doctor_phone'],
          'contact_phone': item['contact_phone'],
          'pharmacy_phone': item['pharmacy_phone'],
          'pharmacy_fax': item['pharmacy_fax'],
          'family_doctor_name': item['family_doctor_name'],
          'contact_name': item['contact_name'],
          'relation': item['relation'],
          'narrative_hint': item['narrative_hint'],
        };

        // Write parent row down first to satisfy foreign key constraints
        await txn.insert(
          'patient',
          patientRow,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 2. Extract and Seed the Nested Medications ('prescription' array)
        if (item['prescription'] != null && item['prescription'] is List) {
          final List<dynamic> prescriptions = item['prescription'];
          for (var med in prescriptions) {
            // Clean out the ghost formula string error gracefully on insert
            String frequency = med['freq'] ?? 'PRN';
            if (frequency.contains('Syntax error')) {
              frequency = 'PRN'; // Default fallback until the UI toggle is saved
            }

            await txn.insert(
              'medication',
              {
                'id': '${patientUuid}_med_${med['id']}', // Unique compound string key
                'patient_uuid': patientUuid,            // Links cleanly back to parent
                'set_id': med['set_id'],
                'name': med['name'],
                'dose': med['dose'],
                'freq': frequency,
                'has_local_datasheet': med['has_local_datasheet'] ?? 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        // 3. Extract and Seed the Nested Vitals History
        if (item['vitals'] != null && item['vitals'] is List) {
          final List<dynamic> vitalsList = item['vitals'];
          for (var vital in vitalsList) {
            await txn.insert(
              'vitals',
              {
                'id': '${patientUuid}_vital_${vital['id']}', // Unique compound string key
                'patient_uuid': patientUuid,               // Links cleanly back to parent
                'pulse': vital['pulse'],
                'systolic': vital['systolic'],
                'diastolic': vital['diastolic'],
                'o2': vital['spo2'],
                'temperature': vital['temp'],
                'recorded_at': vital['recorded_at'],       // ISO timestamp string
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }
    });
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
    // try {
    //   final String response = await rootBundle.loadString(
    //     'assets/patients/conditions.json',
    //   );
    //   final List<dynamic> data = json.decode(response);
    //
    //   Batch batch = db.batch();
    //
    //   for (var entry in data) {
    //     batch.insert('patient_condition', {
    //       'patient_uuid': entry['patient_uuid'],
    //       'treatment_notes': entry['treatment_notes'],
    //       'is_active': entry['is_active'] ?? 1,
    //       // Let the DB handle the recorded_at default
    //     });
    //   }
    //
    //   await batch.commit(noResult: true);
    //   debugPrint('Patient conditions seeded from JSON.');
    // } catch (e) {
    //   debugPrint('Error seeding patient conditions: $e');
    // }
  }
}