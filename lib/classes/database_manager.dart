import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:triage/classes/patient_condition.dart';
import 'package:triage/classes/vitals.dart';
import 'package:uuid/uuid.dart';
import 'acuity.dart';
import 'data_seeder.dart';
import 'metric_value.dart';

class DatabaseManager {
  // Singleton pattern
  static final DatabaseManager _instance = DatabaseManager._internal();
  Database? _db;
  static const uuid = Uuid();

  // The Gatekeeper: This prevents multiple calls to init()
  Completer<Database>? _dbCompleter;

  // Cache the SQL configuration in memory
  Map<String, dynamic>? sqlConfig;

  // DatabaseManager._internal();
  DatabaseManager._internal();

  factory DatabaseManager() => _instance;

  Future<Database> get database async {
    // Double-checked locking
    if (_db != null && _db!.isOpen) return _db!;

    // Return existing future if in progress
    if (_dbCompleter != null) return _dbCompleter!.future;

    // Create the completer immediately
    _dbCompleter = Completer<Database>();

    try {
      // Perform the init
      final db = await _init(overwrite: false);

      // CRITICAL: Assign _db BEFORE completing the future
      _db = db;
      _dbCompleter!.complete(db);

      return db;
    } catch (e) {
      _dbCompleter = null;
      rethrow;
    }
  }

  Future<Database> _init({bool overwrite = false}) async {
    final String response = await rootBundle.loadString('assets/sql/sql.json');
    sqlConfig = json.decode(response);

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'triage_data.db');

    if (overwrite) {
      await deleteDatabase(path);
    }

    // CRITICAL: You must await this call.
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 4. Ensure Foreign Keys are enabled for the session
        await db.execute('PRAGMA foreign_keys = ON;');
        await createSqlObjects(db);
        await DataSeeder.seed(db);
      },
    );
    return db;
  }

  Future<void> createSqlObjects(Database db) async {
    if (sqlConfig == null) return;
    // 2. Extract the CREATE array
    final List<dynamic> createScripts = sqlConfig?['CREATE'];

    // 3. Execute each query in the order provided in the JSON
    for (var entry in createScripts) {
      final String query = entry['query'];
      if (query.isNotEmpty) {
        await db.execute(query);
      }
    }
  }

  // Drugs
  Future<String?> getInteractions(String drugNameA, String drugNameB) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'interaction',
      columns: ['explanation'],
      where: '(name_a = ? AND name_b = ?) OR (name_a = ? AND name_b = ?)',
      whereArgs: [drugNameA, drugNameB, drugNameB, drugNameA],
    );
    // Return the interaction description if found, otherwise the default message
    if (results.isNotEmpty) {
      String explanation = results.first['explanation'] as String;
      return explanation;
    } else {
      return null;
    }
  }

  Future<String?> getTemplateTextForCode(String code) async {
    final db = await database;
    return "";
  }

  Future<void> insertBodyMarker(String patientUuid, Map<String, dynamic> marker) async {
    final db = await database;

    // Create a copy of the marker map to prepare for insertion
    Map<String, dynamic> row = Map<String, dynamic>.from(marker);

    // Add the patient reference
    row['patient_uuid'] = patientUuid;

    // Ensure all 'Chips' lists (JSON arrays) are encoded to strings
    row['descriptions'] = jsonEncode(row['descriptions'] ?? []);
    row['improves_when'] = jsonEncode(row['improves_when'] ?? []);
    row['worsens_when'] = jsonEncode(row['worsens_when'] ?? []);
    row['interventions_tried'] = jsonEncode(row['interventions_tried'] ?? []);

    // Perform the insertion
    await db.insert('markers', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // DatabaseManager now only cares about standard SQL operations
  Future<void> insertMarkersBatch(String tableName, List<Map<String, dynamic>> rows) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var row in rows) {
        await txn.insert(tableName, row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getMarkersForPatient(String patientUuid) async {
    final db = await database;

    // Fetch all markers for the patient, sorted by most recent first
    return await db.query(
      'body_markers',
      where: 'patient_uuid = ?',
      whereArgs: [patientUuid],
      orderBy: 'recorded DESC',
    );
  }

  // Inside your classes/database_manager.dart file
  Future<bool> updatePatientProcessStep({required String uuid, required int targetStepId}) async {
    try {
      // 1. Get a handle to your initialized database engine instance
      final db = await database;

      // 2. Execute a targeted update on the specific patient row matching the UUID
      final int rowsAffected = await db.update(
        'patient',
        {
          'phase_step_id': targetStepId,
          'last_update': DateTime.now().toIso8601String(), // Optional: if you track transaction records
        },
        where: 'patient_uuid = ?',
        whereArgs: [uuid],
      );

      // 3. Return true only if at least one record was successfully modified in the schema
      return rowsAffected > 0;
    } catch (e) {
      debugPrint("Database Engine Error: Failed to write step transition: $e");
      return false; // Safely fail without crashing the app thread
    }
  }

  // The New Patient Retrieval Function
  // The Clean Patient Retrieval Function
  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final db = await database;

    // Directly pull every row from the patient table
    return await db.query('patient');
  }

  Future<List<Map<String, dynamic>>> getAllPatientsWithVitals() async {
    final db = await database;

    // Use a LEFT JOIN to ensure we get the patient even if they have no vitals yet
    return await db.rawQuery('''
    SELECT p.*, m.*
    FROM patient p
    LEFT JOIN patient_current_metrics m ON p.patient_uuid = m.patient_uuid
  ''');
  }

  Future<List<Map<String, dynamic>>> getPatientWithVitals({required String patientUuid}) async {
    final db = await database;

    // Use a LEFT JOIN to ensure we get the patient even if they have no vitals yet
    return await db.rawQuery(
      '''
    SELECT p.*, m.*
    FROM patient p
    LEFT JOIN patient_current_metrics m ON p.patient_uuid = m.patient_uuid
    WHERE p.patient_uuid = ?
  ''',
      [patientUuid],
    );
  }

  Future<List<Map<String, dynamic>>> getPatientVitalsHistory({required String patientUuid}) async {
    final db = await database;

    // Use a LEFT JOIN to ensure we get the patient even if they have no vitals yet
    return await db.rawQuery(
      '''
    SELECT m.*
    FROM patient p
    LEFT JOIN patient_metrics m ON p.patient_uuid = m.patient_uuid
    WHERE p.patient_uuid = ?
    ORDER BY m.reading_id, m.metric_type
  ''',
      [patientUuid],
    );
  }

  // Helper to avoid deadlocks during the open/create cycle
  Future<void> rawInsertVitals(Database db, Map<String, dynamic> data) async {
    await db.insert('vitals', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertAcuity({
    required String patientUuid,
    required AcuityLevel acuityLevel,
    required String rationale,
    required String encounterId,
    required String setBu, // Assuming this is the 'set by user' identifier
  }) async {
    final db = await database;
    await updatePatientAcuity(patientUuid: patientUuid, newAcuityLevel: acuityLevel);

    // Use a UUID package to generate the primary key
    final String id = const Uuid().v4();

    try {
      await db.insert('acuity_log', {
        'id': id,
        'patient_uuid': patientUuid,
        'acuity_level': acuityLevel.index,
        'encounter_id': encounterId,
        'rationale': rationale,
        'set_bu': setBu,
        // 'set_at' is handled by DEFAULT CURRENT_TIMESTAMP in your SQL
      });
    } catch (e) {
      debugPrint("Error logging acuity change: $e");
      // Handle or rethrow based on your app's error policy
    }
  }

  Future<void> updatePatientAcuity({required String patientUuid, required AcuityLevel newAcuityLevel}) async {
    final db = await database; // Or your specific DB instance accessor

    try {
      await db.update(
        'patient', // Replace with your actual table name
        {'acuity': newAcuityLevel.index},
        where: 'patient_uuid = ?',
        whereArgs: [patientUuid],
      );
    } catch (e) {
      debugPrint("Error updating database: $e");
    }
  }

  // Inside your DatabaseManager class:
  Future<Map<String, List<ConditionReference>>> getConditionsCatalog() async {
    final db = await database;

    // Fetch all conditions ordered alphabetically by category and name
    final List<Map<String, dynamic>> maps = await db.query('condition', orderBy: 'category ASC, name ASC');

    // Reconstruct our grouped layout pattern dynamically
    final Map<String, List<ConditionReference>> catalog = {};

    for (final Map<String, dynamic> row in maps) {
      final reference = ConditionReference.fromMap(row);

      // Initialize the list for this category slot if it doesn't exist yet
      if (!catalog.containsKey(reference.category)) {
        catalog[reference.category] = [];
      }

      catalog[reference.category]!.add(reference);
    }

    return catalog;
  }

  Future<void> insertPatientMetric(String patientUuid, double value, String metricType) async {
    final db = await database;
    final sanitizedType = metricType.toLowerCase().trim();
    final String metricEventUuid = const Uuid().v4();
    final int readingId = await getNextReadingId(db, patientUuid);
    // Execute the database write.
    // Note: This insert will instantly trigger your SQLite triggers on the backend
    // to update the flat fast-cache on the patients table automatically
    await db.execute(
      '''
    INSERT INTO patient_metrics (
      id, 
      patient_uuid, 
      reading_id,
      metric_type, 
      metric_value
    ) VALUES (?, ?, ?, ?, ?)
  ''',
      [metricEventUuid, patientUuid, readingId, sanitizedType, value],
    );
  }

  // If you are using the standard 'uuid' package, import it at the top of your database file:
  // import 'package:uuid/uuid.dart';
  Future<int> getNextReadingId(Database db, String patientUuid) async {
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COALESCE(MAX(reading_id), 0) + 1 as next_id FROM patient_metrics WHERE patient_uuid = ?',
      [patientUuid],
    );

    return result.first['next_id'] as int;
  }

  Future<void> insertVitalsBatch({
    required String patientUuid,
    required int systolic,
    required int diastolic,
    required int pulse,
    required double spo2,
    required double temperature,
  }) async {
    final db = await database;

    final int nextReadingId = await getNextReadingId(db, patientUuid);
    // 1. Initialize a highly optimized atomic write batch
    final batch = db.batch();
    final String timestamp = DateTime.now().toIso8601String();

    // A helper map to structure our loop properties cleanly
    final Map<String, double> vitalsMap = {
      'systolic': systolic.toDouble(),
      'diastolic': diastolic.toDouble(),
      'pulse': pulse.toDouble(),
      'spo2': spo2,
      'temp': temperature,
    };

    // 2. Queue all 5 unique metric types into the batch execution buffer
    vitalsMap.forEach((metricType, value) {
      if (value > 0) {
        final String rowId = "${patientUuid}_${metricType}_${DateTime.now().microsecondsSinceEpoch}";

        batch.insert('patient_metrics', {
          'id': rowId, // <-- Supply the required primary key GUID here!
          'reading_id': nextReadingId,
          'patient_uuid': patientUuid,
          'metric_type': metricType,
          'metric_value': value,
          'recorded_at': timestamp,
        });
      }
    });

    // 3. Commit all rows to the phone storage database in one single disk pass
    await batch.commit(noResult: true);
  }

  Future<CurrentVitalsRecord?> getCurrentVitals(String patientUuid) async {
    final db = await database; // Your DB instance

    // Query the sidecar table
    final List<Map<String, dynamic>> results = await db.query(
      'patient_current_metrics',
      where: 'patient_uuid = ?',
      whereArgs: [patientUuid],
    );

    if (results.isEmpty) return null;

    final row = results.first;

    // Convert the flat database row into the format CurrentVitals expects
    final List<Map<String, dynamic>> metricList = [
      {
        'metric_type': 'systolic',
        'metric_value': row['current_systolic'],
        'min_found': row['min_systolic'],
        'max_found': row['max_systolic'],
      },
      {
        'metric_type': 'diastolic',
        'metric_value': row['current_diastolic'],
        'min_found': row['min_diastolic'],
        'max_found': row['max_diastolic'],
      },
      {
        'metric_type': 'pulse',
        'metric_value': row['current_pulse'],
        'min_found': row['min_pulse'],
        'max_found': row['max_pulse'],
      },
      {
        'metric_type': 'spo2',
        'metric_value': row['current_spo2'],
        'min_found': row['min_spo2'],
        'max_found': row['max_spo2'],
      },
      {
        'metric_type': 'temperature',
        'metric_value': row['current_temperature'],
        'min_found': row['min_temperature'],
        'max_found': row['max_temperature'],
      },
    ];

    return CurrentVitalsRecord.fromJson(metricList);
  }

  Future<MetricValue?> getLatestMetric(String patientUuid, String metricType) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'patient_metrics',
      columns: ['metric_value', 'recorded_at'],
      where: 'patient_uuid = ? AND metric_type = ?',
      whereArgs: [patientUuid, metricType],
      orderBy: 'recorded_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null; // Return null if the user has no history yet
    }

    // Instantly map the database row to our strongly typed data model object
    return MetricValue.fromJson(maps.first);
  }

  Future<void> deletePatientCondition(int id) async {
    // Guard clause: If the record doesn't have a database ID, there's nothing to drop
    final db = await database;

    await db.delete('patient_condition', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertPatientCondition(PatientCondition record) async {
    final db = await database;

    await db.insert(
      'patient_condition',
      record.toMap(),
      // ConflictAlgorithm.replace ensures if the record somehow already exists,
      // it overwrites it cleanly without throwing an exception
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePatientCondition(PatientCondition record) async {
    final db = await database;

    await db.update(
      'patient_condition',
      record.toMap(),
      // We target the specific record using its unique ID to avoid accidental overwrites
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<List<PatientCondition>> getConditionsForPatient(String patientUuid) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'patient_condition',
      where: 'patient_uuid = ?',
      whereArgs: [patientUuid],
      // Sort by timestamp descending so the latest data is at the top of the list
      orderBy: 'onset DESC',
    );

    // Convert the List<Map<String, dynamic>> into a List<PatientCondition>
    return List.generate(maps.length, (i) {
      return PatientCondition.fromMap(maps[i]);
    });
  }

  Future<List<Map<String, dynamic>>> getObservationsForPatient(String patientUuid) async {
    final db = await database;

    return await db.query(
      'observations',
      where: 'patient_uuid = ?',
      whereArgs: [patientUuid],
      // Sort by timestamp descending so the latest data is at the top of the list
      orderBy: 'time_stamp DESC',
    );
  }

  Future<int> deleteObservation(int id) async {
    final db = await database;
    return await db.delete(
      'observations', // Your database table name
      where: 'id = ?', // Target row filter
      whereArgs: [id],
    );
  }

  Future<int> insertObservation(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('observations', row);
  }

  Future<int> updateObservation(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('observations', row, where: 'id = ?', whereArgs: [id]);
  }

  // Retrieve all vital readings for a specific patient, newest first
  Future<List<Map<String, dynamic>>> getVitalsForPatient(String patientUuid) async {
    final db = await database;

    return await db.query(
      'vitals',
      where: 'patient_uuid = ?',
      whereArgs: [patientUuid],
      // Sort by timestamp descending so the latest data is at the top of the list
      orderBy: 'recorded_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPatientEvents(String uuid) async {
    final db = await database;
    return await db.query('patient_events', where: 'patient_uuid = ?', whereArgs: [uuid], orderBy: 'timestamp DESC');
  }

  Future<Map<String, dynamic>?> getStoredDatasheet(String setId) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'datasheet',
      where: 'set_id = ?',
      whereArgs: [setId],
      limit: 1,
    );

    if (results.isEmpty) return null;

    // 1. Start with the database row (includes 'classes', 'set_id', etc.)
    final Map<String, dynamic> fullRow = Map<String, dynamic>.from(results.first);

    final String? blob = fullRow['raw_json_blob'];

    if (blob != null && blob.isNotEmpty) {
      try {
        // 2. Decode the FDA JSON
        final Map<String, dynamic> decodedJson = json.decode(blob);

        // 3. MERGE: This puts all keys from the JSON into the fullRow map.
        // If there are duplicate keys, the JSON blob values win.
        fullRow.addAll(decodedJson);
      } catch (e) {
        debugPrint('Error decoding stored blob for $setId: $e');
      }
    }

    // Now returns a map containing BOTH DB columns and FDA JSON keys
    return fullRow;
  }

  // Internal helper to avoid calling 'await database' during initialization
  Future<void> rawInsertMedication(Database db, Map<String, dynamic> medication) async {
    await db.insert('medication', {
      'id': medication['id'],
      'patient_uuid': medication['patient_uuid'],
      'name': medication['name'],
      'dose': medication['dose'],
      'freq': medication['freq'],
      'set_id': medication['set_id'] ?? '',
      'has_local_datasheet': medication['has_local_datasheet'] ?? '',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertMedication(Map<String, dynamic> medication) async {
    final db = await database;

    // Since we generate the UUID in the UI, it's already in the map
    await db.insert('medication', {
      'id': medication['id'], // Our Flutter-generated UUID
      'patient_uuid': medication['patient_uuid'],
      'name': medication['name'],
      'dose': medication['dose'],
      'freq': medication['freq'],
      'set_id': medication['set_id'] ?? '',
      'has_local_datasheet': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // The Tether (Updating the set_id)
  Future<void> updateMedicationSetId(String localUuid, String newSetId) async {
    final db = await database;
    await db.update(
      'medication',
      {'set_id': newSetId, 'has_local_datasheet': 1},
      where: 'id = ?',
      whereArgs: [localUuid],
    );
  }

  Future<int> deleteMedication(String medUuid) async {
    final db = await database;
    return await db.delete('medication', where: 'id = ?', whereArgs: [medUuid]);
  }

  Future<void> saveDatasheet(Map<String, dynamic> fdaJson, String? classes) async {
    final db = await database;

    // Extract metadata for dedicated columns
    final openfda = fdaJson['openfda'] ?? {};

    await db.insert('datasheet', {
      'set_id': fdaJson['set_id'],
      'version': fdaJson['version'],
      'classes': classes,
      // RXCUI is often an array in openfda, grab the first one
      'rxcui': (openfda['rxcui'] != null && openfda['rxcui'].isNotEmpty) ? openfda['rxcui'][0] : null,
      'brand_name': (openfda['brand_name'] != null && openfda['brand_name'].isNotEmpty)
          ? openfda['brand_name'][0]
          : null,
      'generic_name': (openfda['generic_name'] != null && openfda['generic_name'].isNotEmpty)
          ? openfda['generic_name'][0]
          : null,
      'raw_json_blob': json.encode(fdaJson),
      'last_synced_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getDatasheetByName(String name) async {
    final db = await database;

    // We use COLLATE NOCASE to ensure the lookup is case-insensitive
    final List<Map<String, dynamic>> results = await db.query(
      'datasheet',
      where: 'generic_name = ? COLLATE NOCASE OR brand_name = ? COLLATE NOCASE',
      whereArgs: [name, name],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first;
    }

    debugPrint('DatabaseManager: No local datasheet found for $name');
    return null;
  }

  Future<void> updateDatasheetClasses(String setId, String classes) async {
    final db = await database;
    await db.update('datasheet', {'classes': classes}, where: 'set_id = ?', whereArgs: [setId]);
  }

  Future<List<Map<String, dynamic>>> scanLocalDatasheetsForContraindications(List<String> drugNames) async {
    List<Map<String, dynamic>> found = [];
    for (var name in drugNames) {
      // 1. Get the local blob for this drug
      // Ensure getDatasheetByName handles the case-insensitive lookup
      final Map<String, dynamic>? blob = await getDatasheetByName(name);
      if (blob == null) continue;

      // 2. Normalize the haystack (The FDA Label Text)
      // We combine the high-risk fields into one searchable string
      final String contra = blob['contraindications']?.toString() ?? "";
      final String interactions = blob['drug_interactions']?.toString() ?? "";

      final String haystack = (contra + interactions).toLowerCase();

      for (var otherName in drugNames) {
        // Don't compare a drug against itself
        if (name.toLowerCase() == otherName.toLowerCase()) continue;

        // 3. Normalize the needle
        final String needle = otherName.toLowerCase().trim();

        // 4. Perform the Scan
        if (needle.isNotEmpty && haystack.contains(needle)) {
          found.add({
            'drugA': name,
            'drugB': otherName,
            'severity': 'high', // Contraindications are always high risk
            'type': 'contraindication',
            'description': 'Interaction found in $name label regarding $otherName.',
          });
        }
      }
    }
    return found;
  }

  Future<List<Map<String, dynamic>>> getMedicationsForPatient(String patientUuid) async {
    final db = await database;

    return await db.query(
      'medication',
      where: 'patient_uuid = ?',
      whereArgs: [patientUuid],
      // Optional: Sort by name so the list doesn't jump around
      orderBy: 'name ASC',
    );
  }

  Future<String?> getSetIdByName(String medName) async {
    final db = await database;

    // We use LIKE with wildcards to handle minor naming variations
    // (e.g., "Metformin" matching "Metformin Hydrochloride")
    final List<Map<String, dynamic>> results = await db.query(
      'datasheet',
      columns: ['set_id'],
      where: 'generic_name LIKE ? OR brand_name LIKE ?',
      whereArgs: ['%$medName%', '%$medName%'],
      limit: 1, // We only need one valid tether
    );

    if (results.isNotEmpty) {
      return results.first['set_id'] as String;
    }
    return null;
  }

  Future<int> updateMedicationName(String medicationId, String newQuery) async {
    final db = await database; // Assuming your getter is named 'database'

    return await db.update(
      'medication', // Your table name
      {'name': newQuery},
      where: 'id = ?',
      whereArgs: [medicationId],
    );
  }

  Future<Map<String, dynamic>?> getMedicationById(String id) async {
    final db = await database; // Your getter for the Database instance

    // We query the specific table for the single row matching the ID
    final List<Map<String, dynamic>> results = await db.query('medication', where: 'id = ?', whereArgs: [id], limit: 1);

    if (results.isNotEmpty) {
      return results.first;
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> getPatientConditions(String uuid) async {
    final db = await database;
    return await db.query('patient_condition', where: 'patient_uuid = ? AND is_active = 1', whereArgs: [uuid]);
  }

  Future<Map<String, dynamic>?> getDatasheetBySetId(String setId) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'datasheet',
      where: 'set_id = ?',
      whereArgs: [setId],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, int>> countCompletedAssessments(String patientId) async {
    final db = await database;

    // We query the table directly using the assessment_id column as our key
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
    SELECT assessment_id, COUNT(*) as total
    FROM completed_assessment
    WHERE patient_id = ? AND complete = 1
    GROUP BY assessment_id
  ''',
      [patientId],
    );

    // Convert the list of rows into a Map: {'PHQ-9': 1, 'GAD-7': 0, ...}
    return {for (var row in results) row['assessment_id'] as String: row['total'] as int};
  }

  Future<void> saveAssessmentResults({
    required String assessmentId,
    required String patientId,
    required Map<String, String> answers, // Map of question_id -> answer_text
    bool isComplete = true,
  }) async {
    final db = await database;
    final String completedAssessmentId = uuid.v4();
    final String now = DateTime.now().toIso8601String();
    // Use a transaction to ensure data integrity across both tables
    await db.transaction((txn) async {
      // 1. Insert the parent record into completed_assessment
      await txn.insert('completed_assessment', {
        'id': completedAssessmentId,
        'assessment_id': assessmentId,
        'patient_id': patientId,
        'date_started': now, // In a real flow, you might track actual start time
        'complete': isComplete ? 1 : 0,
        'date_completed': isComplete ? now : null,
        'last_modified': now,
      });

      // 2. Insert each individual answer into completed_question
      for (var entry in answers.entries) {
        await txn.insert('completed_question', {
          'completed_assessment_id': completedAssessmentId,
          'question_id': entry.key,
          'answer': entry.value,
        });
      }
    });
  }

  Future<Map<String, String>?> getLatestAssessmentResults({
    required String assessmentId,
    required String patientId,
  }) async {
    final db = await database;
    // Find the ID of the most recent completed assessment for this patient/scale
    final List<Map<String, dynamic>> assessmentMaps = await db.query(
      'completed_assessment',
      where: 'assessment_id = ? AND patient_id = ? AND complete = 1',
      whereArgs: [assessmentId, patientId],
      orderBy: 'date_completed DESC',
      limit: 1,
    );

    if (assessmentMaps.isEmpty) return null;

    final String completedId = assessmentMaps.first['id'];

    // 2. Fetch all answers associated with that specific completion ID
    final List<Map<String, dynamic>> questionMaps = await db.query(
      'completed_question',
      where: 'completed_assessment_id = ?',
      whereArgs: [completedId],
    );

    // Reconstruct the Map<String, String> (question_id -> answer)
    return {for (var row in questionMaps) row['question_id'] as String: row['answer'] as String};
  }
  //
  // Future<(bool, String)> checkInteractions(String primarySetId, String otherSetId) async {
  //   final db = await database;
  //
  //   // The Full CTE
  //   final List<Map<String, dynamic>> result = await db.rawQuery(
  //     r'''
  //   WITH RECURSIVE split_classes(class_name, remainder) AS (
  //     SELECT
  //       trim(substr(classes || ',', 1, instr(classes || ',', ',') - 1)),
  //       substr(classes || ',', instr(classes || ',', ',') + 1)
  //     FROM datasheet WHERE set_id = ?
  //     UNION ALL
  //     SELECT
  //       trim(substr(remainder, 1, instr(remainder, ',') - 1)),
  //       substr(remainder, instr(remainder, ',') + 1)
  //     FROM split_classes
  //     WHERE remainder != ''
  //   )
  //   SELECT class_name FROM split_classes WHERE class_name != '';
  // ''',
  //     [otherSetId],
  //   );
  //
  //   if (result.isNotEmpty) {
  //     List<String> list = result.map((e) => e['class_name'].toString()).toList();
  //     return (true, list.first);
  //   }
  //   return (false, "");
  // }

  Future<List<Map<String, dynamic>>> getStaff() async {
    final db = await database;

    // Use a LEFT JOIN to ensure we get the patient even if they have no vitals yet
    return await db.rawQuery('''
    SELECT s.*
    FROM staff s
    ORDER BY s.last_name, s.first_name
  ''');
  }

  Future<List<Map<String, dynamic>>> getStaffMember({required String id}) async {
    final db = await database;

    // Use a LEFT JOIN to ensure we get the patient even if they have no vitals yet
    return await db.rawQuery(
      '''
    SELECT s.*
    FROM staff s
    WHERE id = ?
    ORDER BY s.last_name, s.first_name
  ''',
      [id],
    );
  }
}
