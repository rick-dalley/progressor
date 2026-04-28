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
        await _seedFromLegacyJson(db);
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

  Future<void> _seedMedsFromLegacyJson(Database db) async {
    final String response = await rootBundle.loadString('assets/medications/meds.json');
    final List<dynamic> data = json.decode(response);

    Batch batch = db.batch();
    for (var entry in data) {
      // Match the schema: patient_uuid, first_name, last_name, etc.
      batch.insert('patient', {
        'patient_uuid': entry['patient_uuid'],
        'first_name': entry['first_name'] ?? 'Unknown',
        'last_name': entry['last_name'] ?? 'Unknown',
        'current_acuity': 3 // Default for Robert Miller and others
      });
    }
    // noResult: true is faster for initial seeds
    await batch.commit(noResult: true);
  }

  Future<void> _seedFromLegacyJson(Database db) async {
    // 1. Load the correct source file
    final String response = await rootBundle.loadString('assets/patients/patients.json');
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
        'narrative_hint': entry['narrative_hint']
      });
    }

    // commit(noResult: true) is perfect here for performance
    await batch.commit(noResult: true);
  }

}