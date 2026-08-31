import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'date_time_utilities.dart';
import 'ems_handoff.dart';

class DataSeeder {
  // Mirrors the asset pool StaffIdCard used to pick from by list position — now
  // assigned once per seeded row instead, so a demo colleague keeps the same face
  // no matter how the staff list gets sorted or trimmed later.
  static const List<String> _demoStaffPhotos = [
    "assets/images/faces/dr_face_1.png",
    "assets/images/faces/dr_face_2.png",
    "assets/images/faces/emerg_face_1.png",
    "assets/images/faces/emerg_face_2.png",
    "assets/images/faces/nurse_face_1.png",
    "assets/images/faces/nurse_face_2.png",
    "assets/images/faces/police_face_1.png",
    "assets/images/faces/police_face_2.png",
    "assets/images/faces/psych_face_1.png",
    "assets/images/faces/psych_face_2.png",
    "assets/images/faces/psych_nurse_1.png",
    "assets/images/faces/psych_nurse_2.png",
  ];

  /// Entry point for seeding data.
  /// Only executes in debug mode to prevent data pollution in release builds.
  /// [onProgress], if given, is called after each batch finishes with
  /// (batches completed so far, total batches) — see StartupScreen, which uses this
  /// to show real progress instead of an indefinite spinner during the one-time
  /// first-install seed (onCreate only; an already-seeded install never re-runs this).
  static Future<void> seed(Database db, {void Function(int completed, int total)? onProgress}) async {
    if (!kDebugMode) return;

    debugPrint('--- Starting Database Seeding ---');

    final List<Future<void> Function(Database)> batches = [
      _seedPatientData,
      _seedPhaseSteps,
      _seedTrackedMetrics,
      _seedTherapySpans,
      _seedEmsHandoffs,
      _seedObservations,
      _seedConditionsCatalog,
      _seedStaff,
      _seedCareOrders,
      _seedDispositionDecisions,
      _seedInteractions,
    ];

    for (int i = 0; i < batches.length; i++) {
      await batches[i](db);
      onProgress?.call(i + 1, batches.length);
    }
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
      for (var (i, entry) in data.indexed) {
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
          // A real per-row photo assignment, not derived from list position at
          // render time (StaffIdCard used to do that, which shifted everyone's
          // photo around whenever the roster was re-sorted or trimmed).
          'photo_path': _demoStaffPhotos[i % _demoStaffPhotos.length],
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

  // phase_step starts empty (nothing in the app has ever written to it — see
  // the Progressor foundation-rebuild plan). Each seeded patient's
  // phase_step_id scalar (e.g. 301 = phase 3, step 1) already encodes where
  // they should be, so decode it and backfill plausible history: one
  // completed row for every step before the current one within that phase,
  // plus one started row for the current step itself.
  static const String _phaseBlueprintId = 'psych_unit_v1';
  static const String _phaseBlueprintVersion = '1';

  static Future<void> _seedPhaseSteps(Database db) async {
    final String rawJsonString = await rootBundle.loadString('assets/patients/patients.json');
    final List<dynamic> decodedData = jsonDecode(rawJsonString);

    await db.transaction((txn) async {
      for (var item in decodedData) {
        if (item is! Map<String, dynamic>) continue;

        final String patientUuid = item['patient_uuid'];
        final int? phaseStepId = item['phase_step_id'] as int?;
        if (phaseStepId == null) continue;

        final int phaseId = phaseStepId ~/ 100;
        final int stepId = phaseStepId % 100;
        final DateTime admitted = DTUtilities.sqliteToDart(item['admitted']);

        for (int step = 1; step <= stepId; step++) {
          final bool isCurrent = step == stepId;
          final DateTime startedAt = admitted.add(Duration(hours: step * 3));
          await txn.insert('phase_step', {
            'id': const Uuid().v4(),
            'patient_uuid': patientUuid,
            'blueprint_id': _phaseBlueprintId,
            'version': _phaseBlueprintVersion,
            'phase_id': phaseId,
            'step_id': step,
            'criticality': 1,
            'status': isCurrent ? 'started' : 'completed',
            'category': 'clinical',
            'started_at': startedAt.toIso8601String(),
            'completed_at': isCurrent ? null : startedAt.add(const Duration(hours: 2)).toIso8601String(),
            'resolved_by_user_id': 'seed',
            'logged': startedAt.toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        // Denormalize the current step onto patient.phase_step_id — already the
        // same value it was seeded with, but this keeps the write path
        // consistent with DatabaseManager._recomputeCurrentPhaseStep instead
        // of relying on the seed row being written correctly by coincidence.
        await txn.update(
          'patient',
          {'phase_step_id': phaseId * 100 + stepId},
          where: 'patient_uuid = ?',
          whereArgs: [patientUuid],
        );
      }
    });
  }

  // Demo period spans for the therapy-comparison timeline (see
  // timeline_adapters.dart) — alongside the patient's real phase_step spans,
  // so the compare-up-to-3 picker has more than one real category to show
  // off. Physical therapy is staggered to start well after medication
  // therapy begins (the patient recovers in bed first), not day one.
  static Future<void> _seedTherapySpans(Database db) async {
    final String rawJsonString = await rootBundle.loadString('assets/patients/patients.json');
    final List<dynamic> decodedData = jsonDecode(rawJsonString);
    final DateTime now = DateTime.now();

    await db.transaction((txn) async {
      for (final dynamic item in decodedData) {
        if (item is! Map<String, dynamic>) continue;
        final String patientUuid = item['patient_uuid'];
        final DateTime admitted = DTUtilities.sqliteToDart(item['admitted']);

        final int totalHours = now.difference(admitted).inHours.clamp(8, 1000000);
        final DateTime medicationStart = admitted.add(const Duration(hours: 4));
        final int ptOffsetHours = (totalHours * 0.35).round().clamp(6, totalHours - 2);
        final DateTime physicalTherapyStart = admitted.add(Duration(hours: ptOffsetHours));
        // A low-dose pain-killer course that runs well past when physical therapy
        // starts, so a clinician can actually see all three spans (stay / medication
        // / PT) overlapping at once — clamped so it never ends in the future.
        final DateTime medicationEndTarget = physicalTherapyStart.add(const Duration(days: 14));
        final DateTime medicationEnd = medicationEndTarget.isBefore(now) ? medicationEndTarget : now;

        await txn.insert('therapy_span', {
          'id': '${patientUuid}_therapy_medication',
          'patient_uuid': patientUuid,
          'category': 'medication',
          'label': 'Acetaminophen (Low Dose)',
          'started_at': medicationStart.toIso8601String(),
          'ended_at': medicationEnd.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        await txn.insert('therapy_span', {
          'id': '${patientUuid}_therapy_physical',
          'patient_uuid': patientUuid,
          'category': 'physical_therapy',
          'label': 'Physical Therapy',
          'started_at': physicalTherapyStart.toIso8601String(),
          'ended_at': null,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // Example EMS handoffs (see ems_handoff.dart) for roughly 1-in-3 seeded
  // patients — a stand-in for a real Acuitage sync pipe, since none exists
  // today. Deliberately independent of the disposition/journey seeding below.
  // Reason/assessment-type pairs skew toward what a psych unit (this app's
  // only seeded blueprint) actually receives, using Acuitage's own
  // AssessmentType categories (see EmsAssessmentType) so the incident reason
  // and the icon shown for it tell a consistent story.
  static Future<void> _seedEmsHandoffs(Database db) async {
    final String rawJsonString = await rootBundle.loadString('assets/patients/patients.json');
    final List<dynamic> decodedData = jsonDecode(rawJsonString);
    const List<(String, EmsAssessmentType)> scenarios = [
      ('Behavioral Crisis', EmsAssessmentType.psychosis),
      ('Suicide Attempt', EmsAssessmentType.suicide),
      ('Motor Vehicle Accident', EmsAssessmentType.trauma),
      ('Altered Mental Status', EmsAssessmentType.toxidrome),
      ('Fall — Head Injury', EmsAssessmentType.consciousness),
    ];
    const List<String> crews = ['Medic 12 — J. Alvarez, T. Nguyen', 'Medic 7 — R. Singh, K. Malone', 'Medic 3 — D. Cho, P. Okafor'];
    const int acuityLevelCount = 5; // AcuityLevel.values.length

    await db.transaction((txn) async {
      for (int i = 0; i < decodedData.length; i++) {
        final dynamic item = decodedData[i];
        if (item is! Map<String, dynamic>) continue;
        if (i % 3 != 0) continue; // only a subset arrived via EMS

        final String patientUuid = item['patient_uuid'];
        final DateTime admitted = DTUtilities.sqliteToDart(item['admitted']);
        final (String reason, EmsAssessmentType assessmentType) = scenarios[i % scenarios.length];

        await txn.insert('ems_handoff', {
          'id': '${patientUuid}_ems',
          'patient_uuid': patientUuid,
          'incident_name': reason,
          'dispatch_code': 'ECHO-${(i % 9) + 1}',
          'crew': crews[i % crews.length],
          'on_scene_acuity': i % acuityLevelCount,
          'assessment_type_index': assessmentType.index,
          'destination_facility': "St. Mary's General — ED",
          'narrative': 'Patient assessed and transported per protocol; handoff report delivered to receiving team on arrival.',
          'delivered_at': admitted.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // Example care orders (see care_order.dart) for a subset of seeded
  // patients — demonstrates the non-medication side of what a physician
  // prescribes. Needs real staff ids to exist first.
  static Future<void> _seedCareOrders(Database db) async {
    final String rawJsonString = await rootBundle.loadString('assets/patients/patients.json');
    final List<dynamic> decodedData = jsonDecode(rawJsonString);
    final List<Map<String, dynamic>> staffRows = await db.query('staff');
    if (staffRows.isEmpty) return;
    const List<(String, String, String?)> orderTemplates = [
      ('observation', '1:1 supervised observation', 'Continuous'),
      ('diagnostic', 'Daily urinalysis', 'Daily, 0600'),
      ('exercise', 'Physical therapy consult', '3x weekly'),
      ('activity', 'Bedrest with bathroom privileges', null),
      ('restraintOrDevice', 'Soft wrist restraints — agitation risk', 'PRN, reassess q2h'),
    ];

    await db.transaction((txn) async {
      for (int i = 0; i < decodedData.length; i++) {
        final dynamic item = decodedData[i];
        if (item is! Map<String, dynamic>) continue;
        if (i % 4 != 0) continue; // only a subset have recorded orders

        final String patientUuid = item['patient_uuid'];
        final DateTime admitted = DTUtilities.sqliteToDart(item['admitted']);
        final (String category, String label, String? frequency) = orderTemplates[i % orderTemplates.length];
        final String orderedBy = staffRows[i % staffRows.length]['id'] as String;

        await txn.insert('care_order', {
          'id': '${patientUuid}_order_1',
          'patient_uuid': patientUuid,
          'category': category,
          'label': label,
          'directions': label,
          'frequency': frequency,
          'ordered_by': orderedBy,
          'started_at': admitted.add(const Duration(hours: 2)).toIso8601String(),
          'discontinued_at': null,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // Example disposition decisions (see dispositional.dart/journey_stage.dart)
  // for a realistic subset of seeded patients — varies outcome and
  // deliberately skips ~1-in-5 patients entirely so CountdownTimer's solid-red
  // halo (undecided + overdue) stays visible in the demo, not just the
  // green/orange/red in-window states. Needs real staff ids to exist first.
  static Future<void> _seedDispositionDecisions(Database db) async {
    final String rawJsonString = await rootBundle.loadString('assets/patients/patients.json');
    final List<dynamic> decodedData = jsonDecode(rawJsonString);
    final List<Map<String, dynamic>> staffRows = await db.query('staff');
    if (staffRows.isEmpty) return; // no deciders to assign — skip rather than violate the FK
    const List<String> outcomes = ['admittance', 'admittance', 'admittance', 'released', 'transferred'];
    final DateTime now = DateTime.now();

    await db.transaction((txn) async {
      for (int i = 0; i < decodedData.length; i++) {
        final dynamic item = decodedData[i];
        if (item is! Map<String, dynamic>) continue;
        if (i % 5 == 0) continue; // leave this one undecided — see comment above

        final String patientUuid = item['patient_uuid'];
        final DateTime admitted = DTUtilities.sqliteToDart(item['admitted']);
        final String outcome = outcomes[i % outcomes.length];
        final String deciderId = staffRows[i % staffRows.length]['id'] as String;
        final DateTime decidedAtTarget = admitted.add(const Duration(hours: 6));
        final DateTime decidedAt = decidedAtTarget.isBefore(now) ? decidedAtTarget : now;

        await txn.insert('disposition_decision', {
          'id': '${patientUuid}_disposition_1',
          'patient_uuid': patientUuid,
          'status_before': 'triage',
          'status_after': outcome,
          'decider_id': deciderId,
          'decided_at': decidedAt.toIso8601String(),
          'notes': null,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        await txn.update('patient', {'journey_stage': outcome}, where: 'patient_uuid = ?', whereArgs: [patientUuid]);
      }
    });
  }

  // The generic per-patient tracked-metrics catalog (see tracked_metric.dart)
  // — starts with the same 5 vitals every patient already has, so no card
  // regresses to empty, plus a few non-vital examples to actually demonstrate
  // "track whatever the clinician wants." IDs are assigned explicitly (not
  // left to AUTOINCREMENT) so the vitals-mirroring step below can address
  // them by a fixed id without depending on insertion order.
  static const List<Map<String, dynamic>> _trackedMetricCatalog = [
    {
      'id': 1, 'name': 'Systolic BP', 'symbol': 'SYS', 'category': 'Vitals', 'unit': 'mmHg',
      'color_index': 0, 'healthy_lower_limit': 110.0, 'healthy_upper_limit': 130.0,
    },
    {
      'id': 2, 'name': 'Diastolic BP', 'symbol': 'DIA', 'category': 'Vitals', 'unit': 'mmHg',
      'color_index': 1, 'healthy_lower_limit': 60.0, 'healthy_upper_limit': 90.0,
    },
    {
      'id': 3, 'name': 'Pulse', 'symbol': 'PULSE', 'category': 'Vitals', 'unit': 'bpm',
      'color_index': 2, 'healthy_lower_limit': 60.0, 'healthy_upper_limit': 100.0,
    },
    {
      'id': 4, 'name': 'O2 Saturation', 'symbol': 'O2', 'category': 'Vitals', 'unit': '%',
      'color_index': 3, 'healthy_lower_limit': 90.0, 'healthy_upper_limit': 100.0,
    },
    {
      'id': 5, 'name': 'Temperature', 'symbol': 'TEMP', 'category': 'Vitals', 'unit': '°C',
      'color_index': 4, 'healthy_lower_limit': 36.1, 'healthy_upper_limit': 37.2,
    },
    {
      'id': 6, 'name': 'Pain Score', 'symbol': 'PAIN', 'category': 'Patient-Reported', 'unit': '/10',
      'color_index': 5, 'healthy_lower_limit': 0.0, 'healthy_upper_limit': 3.0,
    },
    {
      // Name matches Ally's own catalog entry, in case a future handoff ever
      // maps tracked metrics by name between the two apps.
      'id': 7, 'name': 'Blood Glucose (Fasting / General)', 'symbol': 'GLU',
      'category': 'Diabetes & Metabolic', 'unit': 'mmol/L',
      'color_index': 6, 'healthy_lower_limit': 4.0, 'healthy_upper_limit': 7.8,
    },
    {
      'id': 8, 'name': 'Weight', 'symbol': 'WT', 'category': 'Vitals', 'unit': 'kg',
      'color_index': 7, 'healthy_lower_limit': null, 'healthy_upper_limit': null,
    },
    {
      // Height/weight/BMI used to live in a one-off widget on the card's
      // back; both now belong here instead, alongside every other metric a
      // clinician might track, with the same trend-chart/history support.
      'id': 9, 'name': 'Height', 'symbol': 'HT', 'category': 'Vitals', 'unit': 'cm',
      'color_index': 8, 'healthy_lower_limit': null, 'healthy_upper_limit': null,
    },
  ];

  // Maps vitals.dart's fixed metric_type strings to the catalog ids above, so
  // each patient's existing seeded vitals readings can be mirrored into the
  // new generic system too — same numbers, no separate live migration.
  static const Map<String, int> _vitalsMetricTypeToId = {
    'systolic': 1, 'diastolic': 2, 'pulse': 3, 'spo2': 4, 'temp': 5,
  };

  static Future<void> _seedTrackedMetrics(Database db) async {
    final String rawJsonString = await rootBundle.loadString('assets/patients/patients.json');
    final List<dynamic> decodedData = jsonDecode(rawJsonString);

    await db.transaction((txn) async {
      for (final Map<String, dynamic> definition in _trackedMetricCatalog) {
        await txn.insert('tracked_metric_definition', definition, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (int i = 0; i < decodedData.length; i++) {
        final dynamic item = decodedData[i];
        if (item is! Map<String, dynamic>) continue;
        final String patientUuid = item['patient_uuid'];
        final DateTime admitted = DTUtilities.sqliteToDart(item['admitted']);

        // Auto-track the 5 vitals for every patient, and mirror their
        // existing readings in so the numbers match the old pipeline.
        for (final int metricId in _vitalsMetricTypeToId.values) {
          await txn.insert('patient_tracked_metric', {
            'patient_uuid': patientUuid,
            'metric_id': metricId,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        if (item['vitals'] is List) {
          for (final dynamic vital in item['vitals'] as List) {
            final int vitalId = vital['id'] ?? 1;
            final DateTime measuredAt = admitted.add(Duration(hours: vitalId * 3));
            final Map<String, dynamic> readings = {
              'systolic': (vital['systolic'] as num?)?.toDouble(),
              'diastolic': (vital['diastolic'] as num?)?.toDouble(),
              'pulse': (vital['pulse'] as num?)?.toDouble(),
              'spo2': (vital['spo2'] as num?)?.toDouble(),
              'temp': (vital['temp'] as num?)?.toDouble(),
            };
            for (final entry in readings.entries) {
              if (entry.value == null) continue;
              await txn.insert('tracked_metric_reading', {
                'id': '${patientUuid}_tm_${entry.key}_$vitalId',
                'patient_uuid': patientUuid,
                'metric_id': _vitalsMetricTypeToId[entry.key],
                'value': entry.value,
                'measured': measuredAt.toIso8601String(),
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }

        // First 3 patients also get a non-vital metric tracked, to actually
        // demonstrate "track whatever the clinician wants" rather than every
        // card just showing the same 5 vitals as before.
        if (i < 3) {
          final int extraMetricId = i.isEven ? 6 : 7; // alternate Pain Score / Blood Glucose
          await txn.insert('patient_tracked_metric', {
            'patient_uuid': patientUuid,
            'metric_id': extraMetricId,
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          for (int reading = 1; reading <= 3; reading++) {
            final double value = extraMetricId == 6
                ? (1 + reading).toDouble() // Pain Score trending 2,3,4
                : 5.0 + reading; // Glucose trending 6.0,7.0,8.0 mmol/L
            await txn.insert('tracked_metric_reading', {
              'id': '${patientUuid}_tm_extra_$reading',
              'patient_uuid': patientUuid,
              'metric_id': extraMetricId,
              'value': value,
              'measured': admitted.add(Duration(hours: reading * 6)).toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }
    });
  }
}
