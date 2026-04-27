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
    _db = await _init();
    return _db!;
  }

  Future<Database> _init({bool overwrite = false}) async {
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
    // We keep the DDL in a central string or a separate asset for easy editing
    const String schemaSql = '''
      CREATE TABLE patients (uuid TEXT PRIMARY KEY, name TEXT, risk_level TEXT);
      CREATE TABLE medications (id INTEGER PRIMARY KEY, patient_id TEXT, name TEXT, dosage TEXT);
    ''';

    for (var script in schemaSql.trim().split(';')) {
      if (script.isNotEmpty) await db.execute(script);
    }
  }

  // Bridging your existing POC data into the new Relational structure
  Future<void> _seedFromLegacyJson(Database db) async {
    final String response = await rootBundle.loadString('assets/data/meds.json');
    final List<dynamic> data = json.decode(response);

    Batch batch = db.batch();
    for (var entry in data) {
      batch.insert('patients', {
        'uuid': entry['patient_uuid'],
        'name': entry['name'],
        'risk_level': 'UNKNOWN'
      });
      // Flattening logic...
    }
    await batch.commit(noResult: true);
  }

  // THE WRAPPER: Returns your data as JSON-compatible List<Map>
  Future<List<Map<String, dynamic>>> getPatientMeds(String patientUuid) async {
    final client = await database;
    // Standard SQL Join to give the UI a full JSON-like object
    return await client.rawQuery('''
      SELECT m.name, m.dosage, p.risk_level 
      FROM medications m 
      JOIN patients p ON m.patient_id = p.uuid 
      WHERE p.uuid = ?
    ''', [patientUuid]);
  }
}