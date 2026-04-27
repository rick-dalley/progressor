import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class DatabaseManager {
  // Singleton pattern
  static final DatabaseManager _instance = DatabaseManager._internal();
  Database? _db;

  DatabaseManager._internal();
  factory DatabaseManager() => _instance;

  // Accessor that ensures the DB is ready before use
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await init();
    return _db!;
  }

  Future<Database> init({bool overwrite = false}) async {
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
        await _seedFromLegacyJson(db);
      },
    );
  }

  Future<void> _createTablesFromConfig(Database db) async {
    // 1. Load the JSON file from assets
    final String response = await rootBundle.loadString('assets/sql/sql.json');
    final Map<String, dynamic> config = json.decode(response);

    // 2. Extract the CREATE array
    final List<dynamic> createScripts = config['CREATE'];

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

  Future<void> _seedFromLegacyJson(Database db) async {
    final String response = await rootBundle.loadString('assets/medications/meds.json');
    final List<dynamic> data = json.decode(response);

    Batch batch = db.batch();
    for (var entry in data) {
      // Match the schema: patient_uuid, first_name, last_name, etc.
      batch.insert('patient', {
        'patient_uuid': entry['patient_uuid'],
        'first_name': entry['first_name'] ?? 'Unknown',
        'last_name': entry['last_name'] ?? 'Subject',
        'current_acuity': 3 // Default for Robert Miller and others
      });
    }
    // noResult: true is faster for initial seeds
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getPatientMeds(String patientUuid) async {
    final db = await database;

    // Joins the local patient med record with the full FDA datasheet
    return await db.rawQuery('''
    SELECT 
      m.dosage, 
      m.frequency, 
      d.brand_name, 
      d.generic_name, 
      d.boxed_warning,
      d.interaction_data
    FROM medication m 
    INNER JOIN datasheet d ON m.set_id = d.set_id 
    WHERE m.patient_uuid = ?
  ''', [patientUuid]);
  }

}