import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class DatabaseManager {
  // Singleton pattern
  static final DatabaseManager _instance = DatabaseManager._internal();
  Database? _db;

  // Cache the SQL configuration in memory
  Map<String, dynamic>? sqlConfig;

  DatabaseManager._internal();

  factory DatabaseManager() => _instance;

  // Accessor that ensures the DB is ready before use
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await init();
    return _db!;
  }

  Future<Database> init({bool overwrite = false}) async {
    final String response = await rootBundle.loadString('assets/sql/sql.json');
    sqlConfig = json.decode(response);

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'triage_data.db');

    if (overwrite) {
      await deleteDatabase(path);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1. Setup Tables via external config
        await _createTablesFromConfig(db);
        // 2. Initial Seed from your JSON files
        await seedPatientData(db);
        await seedMedicationData(db);
      },
    );
  }

  // 3. The New Patient Retrieval Function
  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final db = await database;

    // Find the specific query in our cached SELECT list
    final List<dynamic> selectQueries = sqlConfig?['SELECT'] ?? [];
    final patientQueryObj = selectQueries.firstWhere(
      (q) => q['name'] == 'patients_all',
      orElse: () => null,
    );

    if (patientQueryObj != null) {
      return await db.rawQuery(patientQueryObj['query']);
    }

    // Fallback if the JSON name doesn't match
    return await db.query('patient');
  }

  Future<void> _createTablesFromConfig(Database db) async {
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

    // 4. Ensure Foreign Keys are enabled for the session
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  // UPDATED: Added 'Database db' parameter
  Future<void> seedMedicationData(Database db) async {
    try {
      final String response = await rootBundle.loadString(
        'assets/medications/meds.json',
      );
      final List<dynamic> data = json.decode(response);

      for (var patientEntry in data) {
        String patientUuid = patientEntry['patient_uuid'];
        List<dynamic> prescriptions = patientEntry['prescription'];

        for (var med in prescriptions) {
          // Use a local helper or the raw insert to avoid 'await database' deadlock
          await _rawInsertMedication(db, {
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
      debugPrint('Medication seeding complete.');
    } catch (e) {
      debugPrint('Error seeding medication data: $e');
    }
  }

  Future<void> seedPatientData(Database db) async {
    // 1. Load the correct source file
    final String response = await rootBundle.loadString(
      'assets/patients/patients.json',
    );
    final List<dynamic> data = json.decode(response);

    Batch batch = db.batch();

    for (var entry in data) {
      // Extract the nested name map

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
      });
    }

    // commit(noResult: true) is perfect here for performance
    await batch.commit(noResult: true);
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
  Future<void> _rawInsertMedication(
    Database db,
    Map<String, dynamic> medication,
  ) async {
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

    debugPrint('Inserted medication record with UUID: ${medication['id']}');
  }

  // The Tether (Updating the set_id)
  Future<void> updateMedicationSetId(String localUuid, String newSetId) async {
    final db = await database;
    await db.update(
      'medication',
      {
        'set_id': newSetId,
        'has_local_datasheet': 1,
      },
      where: 'id = ?',
      whereArgs: [localUuid],
    );
    debugPrint('Tethered medication $localUuid to FDA set_id: $newSetId');
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
      'rxcui': (openfda['rxcui'] != null && openfda['rxcui'].isNotEmpty)
          ? openfda['rxcui'][0]
          : null,
      'brand_name':
          (openfda['brand_name'] != null && openfda['brand_name'].isNotEmpty)
          ? openfda['brand_name'][0]
          : null,
      'generic_name':
          (openfda['generic_name'] != null &&
              openfda['generic_name'].isNotEmpty)
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
    await db.update(
      'datasheet',
      {'classes': classes},
      where: 'set_id = ?',
      whereArgs: [setId],
    );
  }

  Future<List<Map<String, dynamic>>> scanLocalDatasheetsForContraindications(
    List<String> drugNames,
  ) async {
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
            'description':
                'Interaction found in $name label regarding $otherName.',
          });
        }
      }
    }
    return found;
  }

  Future<List<Map<String, dynamic>>> getMedicationsForPatient(
    String patientUuid,
  ) async {
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
      debugPrint('Local tether found for $medName: ${results.first['set_id']}');
      return results.first['set_id'] as String;
    }

    debugPrint('No local datasheet for $medName. Fetch required.');
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
    final List<Map<String, dynamic>> results = await db.query(
      'medication',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first;
    }

    return null;
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

  Future<(bool, String)> checkInteractionsInDb(String primarySetId, String otherSetId) async {
    final db = await database;

    // STEP 3: The Full CTE
    final List<Map<String, dynamic>> result = await db.rawQuery(r'''
    WITH RECURSIVE split_classes(class_name, remainder) AS (
      SELECT 
        trim(substr(classes || ',', 1, instr(classes || ',', ',') - 1)),
        substr(classes || ',', instr(classes || ',', ',') + 1)
      FROM datasheet WHERE set_id = ?
      UNION ALL
      SELECT 
        trim(substr(remainder, 1, instr(remainder, ',') - 1)),
        substr(remainder, instr(remainder, ',') + 1)
      FROM split_classes
      WHERE remainder != ''
    )
    SELECT class_name FROM split_classes WHERE class_name != '';
  ''', [otherSetId]);

    if (result.isNotEmpty) {
      List<String> list = result.map((e) => e['class_name'].toString()).toList();
      print("DEBUG: Full CTE Results: $list");
      return (true, list.first);
    }

    print("DEBUG FAIL: CTE returned empty despite raw data existing.");
    return (false, "");
  }

}
