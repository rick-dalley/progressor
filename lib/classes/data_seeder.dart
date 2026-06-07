import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class DataSeeder {
  /// Entry point for seeding data.
  /// Only executes in debug mode to prevent data pollution in release builds.
  static Future<void> seed(Database db) async {
    if (!kDebugMode) return;

    debugPrint('--- Starting Database Seeding ---');

    await _seedPatientData(db);
    await _seedObservations(db);
    await _seedConditionsCatalog(db);
    await _seedStaff(db);
    await _seedInteractions(db);
    debugPrint('--- Seeding Complete ---');
  }

  static Future<void> _seedInteractions(Database db) async {
    final rawData = await rootBundle.loadString('assets/interactions/db_drug_interactions.csv');

    //Parse the CSV (assumes first row is header)
    List<List<dynamic>> rows = const CsvToListConverter(
      fieldDelimiter: ',', // Double check this: is it actually a comma?
      eol: '\n', // Or '\r\n' for Windows-style files
      shouldParseNumbers: false,
    ).convert(rawData);

    //Batch insert using a transaction
    await db.transaction((txn) async {
      // Skip the header row (index 0)
      for (int i = 1; i < rows.length; i++) {
        var row = rows[i];
        await txn.insert('interaction', {
          // 'id': row[0].toString(),
          // 'rx_norm_id': '',
          'name_a': row[0].toString(),
          'name_b': row[1].toString(),
          'explanation': row[2].toString(),
          // 'local_datasheet_id': row[5].toString(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  static Future<void> _seedStaff(Database db) async {
    // 1. Verify if the master table has already been populated
    final List<Map<String, dynamic>> existingRecords = await db.rawQuery("SELECT COUNT(*) as total FROM staff");

    if (existingRecords.first['total'] as int > 0) {
      return; // Catalog is already successfully configured!
    }

    try {
      // 2. Read raw condition data groups from json asset bundle
      final String jsonString = await rootBundle.loadString('assets/staff/staff.json');
      final List<dynamic> data = jsonDecode(jsonString);

      Batch batch = db.batch();
      for (var entry in data) {
        batch.insert('staff', {
          'id': entry['id'],
          'first_name': entry['first_name'],
          'last_name': entry['last_name'],
          'email': entry['email'],
          'position': entry['position'],
          'gender': entry['gender'],
          'is_specialist': 0,
          'on_call': entry['on_call'] ? 1 : 0,
          'pager': entry['pager'],
          'phone': entry['phone'],
        });
      }

      await batch.commit(noResult: true);
    } catch (error) {
      debugPrint("Critical failure executing master condition data migration: $error");
    }
  }

  static Future<void> _seedConditionsCatalog(Database db) async {
    // 1. Verify if the master table has already been populated
    final List<Map<String, dynamic>> existingRecords = await db.rawQuery("SELECT COUNT(*) as total FROM condition");

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
          for (var ailment in ailmentList) {
            if (ailment is Map) {
              // Pass only name and category. SQLite generates the integer ID automatically!
              migrationBatch.insert('condition', {
                'name': ailment["name"],
                'category': categoryKey,
              }, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
          }
        }
      });

      // 4. Commit rows down to the storage engine
      await migrationBatch.commit(noResult: true);
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
        'patient_uuid': entry['patient_uuid'],
        'content': entry['content'],
        'author_name': entry['author_name'],
        'author_role': entry['author_role'],
      });
    }
    await batch.commit(noResult: true);
    debugPrint('Observations seeded.');
  }

  static String normalize(String? timestamp) {
    if (timestamp == null) return DateTime.now().toString();
    // If it's already a string, parse it then format it
    final dt = DateTime.tryParse(timestamp) ?? DateTime.now();
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
  }

  //Seed Patient Personal, Prescription and Vitals information
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
          'acuity': item['acuity'],
          'phn': item['phn'],
          'phase_step_id': item['phase_step_id'],
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
          'police_reports': item['police_reports'],
          'assessments': item['assessments'],
          'status': item['status'],
          'path': item['path'],
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
        await txn.insert('patient', patientRow, conflictAlgorithm: ConflictAlgorithm.replace);

        // Extract and Seed the Nested Medications ('prescription' array)
        if (item['prescription'] != null && item['prescription'] is List) {
          final List<dynamic> prescriptions = item['prescription'];
          for (var med in prescriptions) {
            // Clean out the ghost formula string error gracefully on insert
            String frequency = med['freq'] ?? 'PRN';
            if (frequency.contains('Syntax error')) {
              frequency = 'PRN'; // Default fallback until the UI toggle is saved
            }

            await txn.insert('medication', {
              'id': '${patientUuid}_med_${med['id']}', // Unique compound string key
              'patient_uuid': patientUuid, // Links cleanly back to parent
              'set_id': med['set_id'],
              'name': med['name'],
              'dose': med['dose'],
              'freq': frequency,
              'has_local_datasheet': med['has_local_datasheet'] ?? 0,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        if (item['vitals'] != null && item['vitals'] is List) {
          final List<dynamic> vitalsList = item['vitals'];

          for (var vital in vitalsList) {
            // Define the map of metrics to insert
            int vitalId = vital['id'] ?? 1;

            final Map<String, dynamic> metrics = {
              'pulse': (vital['pulse'] as num?)?.toInt() ?? 0.0,
              'systolic': (vital['systolic'] as num?)?.toInt() ?? 0.0,
              'diastolic': (vital['diastolic'] as num?)?.toInt() ?? 0.0,
              'spo2': (vital['spo2'] as num?)?.toDouble() ?? 0.0,
              'temp': (vital['temp'] as num?)?.toDouble() ?? 0.0,
            };
            // Insert each metric as its own row
            for (var entry in metrics.entries) {
              await txn.insert('patient_metrics', {
                'id': '${item['patient_uuid']}_${entry.key}_$vitalId',
                'reading_id': vitalId,
                'patient_uuid': patientUuid,
                'metric_type': entry.key,
                'metric_value': entry.value,
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }
    });
  }
}
