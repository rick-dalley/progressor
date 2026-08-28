import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/carbon_ui.dart';

// What a physician decides for a patient is broader than medications —
// exercise, observation, medication management, counselling, diagnostics,
// restraints/devices, activity restrictions. Prescribing a drug itself
// already has its own specialized pipeline (interaction checking, FDA
// datasheet sync — see meds.dart) and stays there; this is the generic home
// for everything else a doctor orders coming out of an interview/assessment.
enum OrderCategory { exercise, observation, medication, counselling, diet, diagnostic, restraintOrDevice, activity }

const Map<OrderCategory, String> orderCategoryLabels = {
  OrderCategory.exercise: 'Exercise',
  OrderCategory.observation: 'Observation',
  OrderCategory.medication: 'Medication',
  OrderCategory.counselling: 'Counselling',
  OrderCategory.diet: 'Diet',
  OrderCategory.diagnostic: 'Diagnostic Test',
  OrderCategory.restraintOrDevice: 'Restraint / Device',
  OrderCategory.activity: 'Activity / Rest',
};

const Map<OrderCategory, IconData> orderCategoryIcons = {
  OrderCategory.exercise: Symbols.exercise,
  OrderCategory.observation: Symbols.visibility,
  OrderCategory.medication: Symbols.medication,
  OrderCategory.counselling: Symbols.psychology,
  OrderCategory.diet: Symbols.nutrition,
  OrderCategory.diagnostic: Symbols.lab_panel,
  OrderCategory.restraintOrDevice: Symbols.emergency_recording,
  OrderCategory.activity: Symbols.bed,
};

// One outline color per category — a preset chip renders outlined in its
// category color; tapped into the "basket," the same chip switches to a
// solid fill of that color with white text, so the two states stay visibly
// linked to each other.
const Map<OrderCategory, Color> orderCategoryColors = {
  OrderCategory.exercise: Colors.green,
  OrderCategory.observation: Colors.blue,
  OrderCategory.medication: Colors.deepPurple,
  OrderCategory.counselling: Colors.teal,
  OrderCategory.diet: Colors.brown,
  OrderCategory.diagnostic: Colors.orange,
  OrderCategory.restraintOrDevice: Colors.redAccent,
  OrderCategory.activity: Colors.indigo,
};

OrderCategory orderCategoryFromDbValue(String value) =>
    OrderCategory.values.firstWhere((c) => c.name == value, orElse: () => OrderCategory.observation);

// Common orders, grouped by category, offered as one-tap chips in the
// composer — tapping a chip drops it straight into the "basket" at the top,
// which the physician can then tap again to add fuller directions.
const Map<OrderCategory, List<String>> commonOrderPresets = {
  OrderCategory.exercise: ['Physical Therapy', 'Occupational Therapy', 'Speech Therapy', 'Ambulate with Assistance'],
  OrderCategory.observation: ['1:1 Observation', 'Heart Monitor', 'Continuous Pulse Oximetry', 'Vitals Monitoring q4h', 'Intensive Care'],
  OrderCategory.medication: ['Insulin Monitoring', 'Medication Compliance Review', 'PRN Medication as Needed'],
  OrderCategory.counselling: ['Individual Counselling', 'Group Therapy Session', 'Family Counselling', 'Crisis Intervention'],
  OrderCategory.diet: ['Low Sodium Diet', 'Diabetic Diet', 'Low Fat Diet', 'Renal Diet', 'NPO (Nothing by Mouth)', 'Regular Diet'],
  OrderCategory.diagnostic: ['Daily Urinalysis', 'Blood Work', 'ECG', 'X-Ray'],
  OrderCategory.restraintOrDevice: [
    'Soft Wrist Restraints', 'Optical Prescription', 'Hearing Aid Fitting',
    'Cane', 'CPAP Machine', 'Insulin Pump', 'Neck Brace',
  ],
  OrderCategory.activity: ['Bed Rest', 'Bathroom Privileges', 'Fall Precautions'],
};

// Every care order is a Therapeutic (what it is — the doctor's own words,
// not a coded diagnosis) with a real duration once you know when it started
// and, if applicable, when it was discontinued.
abstract class Therapeutic {
  String get label;
  String get directions;
  Duration get duration;
}

// A Therapeutic that's also trackable on the shared timeline (see
// CarbonTimelineScroller) — the order itself, appearing as a real duration
// span alongside a patient's care-phase stay and any other therapy already
// being compared.
class Therapy implements Therapeutic, CarbonTimelineSpan {
  final String id;
  final String patientUuid;
  final OrderCategory category;
  @override
  final String label;
  @override
  final String directions;
  final String? frequency;
  final String orderedBy; // StaffMember.id
  final DateTime startedAt;
  // The intended end date set when the order was placed (e.g. "for 5 days")
  // — purely informational until it actually happens. Distinct from
  // discontinuedAt, which is when someone actually stopped the order; a
  // future plannedEndAt does NOT make the order inactive.
  final DateTime? plannedEndAt;
  final DateTime? discontinuedAt;

  const Therapy({
    required this.id,
    required this.patientUuid,
    required this.category,
    required this.label,
    required this.directions,
    this.frequency,
    required this.orderedBy,
    required this.startedAt,
    this.plannedEndAt,
    this.discontinuedAt,
  });

  factory Therapy.fromJson(Map<String, dynamic> row) => Therapy(
    id: row['id'] as String,
    patientUuid: row['patient_uuid'] as String,
    category: orderCategoryFromDbValue(row['category'] as String),
    label: row['label'] as String,
    directions: row['directions'] as String? ?? '',
    frequency: row['frequency'] as String?,
    orderedBy: row['ordered_by'] as String,
    startedAt: DateTime.parse(row['started_at'] as String),
    plannedEndAt: row['planned_end_at'] != null ? DateTime.parse(row['planned_end_at'] as String) : null,
    discontinuedAt: row['discontinued_at'] != null ? DateTime.parse(row['discontinued_at'] as String) : null,
  );

  bool get isActive => discontinuedAt == null;

  @override
  Duration get duration => endDate.difference(startDate);

  // --- CarbonTimelineSpan ---
  @override
  String get sourceId => id;
  @override
  DateTime get startDate => startedAt;
  @override
  DateTime get endDate => discontinuedAt ?? plannedEndAt ?? DateTime.now();
  @override
  bool get isOngoing => discontinuedAt == null;
  @override
  String get categoryLabel => orderCategoryLabels[category] ?? category.name;
  @override
  IconData? get icon => orderCategoryIcons[category];
}
