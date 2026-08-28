import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

enum EventRequirement { mandatory, advised, discretionary, none }

enum EventRequirementType { medical, administrative, legal, none }

enum Impetus { voluntary, involuntary, unknown }

enum PhaseIdentifier { arrival, registration, triage, intervention, holding, disposition, unknown }

enum PhaseState {started, pending, completed, aborted, unknown}

// Was defined in the now-deleted patient_state.dart (superseded by
// JourneyStepperWidget) — kept here, PhaseIdentifier's natural home, since
// patient_roster.dart/patient_timeline_screen.dart/timeline_adapters.dart
// all still need a PhaseIdentifier -> icon lookup.
const Map<PhaseIdentifier, IconData> phaseIdentifierIcons = {
  PhaseIdentifier.arrival: Symbols.emergency,
  PhaseIdentifier.registration: Symbols.conditions,
  PhaseIdentifier.triage: Symbols.diagnosis,
  PhaseIdentifier.intervention: Symbols.stethoscope,
  PhaseIdentifier.holding: Symbols.bed,
  PhaseIdentifier.disposition: Symbols.arrow_split,
};

class Event {
  String id;
  String label;
  String description;
  Impetus impetus;
  EventRequirementType requirementType;
  EventRequirement requirement;

  Event({
    required this.id,
    required this.label,
    required this.description,
    required this.impetus,
    required this.requirement,
    required this.requirementType,
  });

  factory Event.fromJson(dynamic json) {
    return Event(
      id: json['event_id'],
      label: json['label'],
      impetus: json['impetus'] != null ? Impetus.values[json['impetus']] : Impetus.unknown,
      requirement: json['requirement'] != null ? EventRequirement.values[json['requirement']] : EventRequirement.none,
      requirementType: json['requirement_type'] != null
          ? EventRequirementType.values[json['requirement_type']]
          : EventRequirementType.none,
      description: json['description'],
    );
  }

  factory Event.unknownEvent(){
    return Event(
      id: "UKNWN",
      label: "Unknown Event",
      description: "this event is not officially registered",
      impetus: Impetus.unknown,
      requirement: EventRequirement.none,
      requirementType: EventRequirementType.none,
    );
  }
}

class Phase {
  String label;
  PhaseIdentifier id;
  String description;
  Map<String, Event>? events;
  DateTime? started;
  DateTime? ended;
  PhaseState? state = PhaseState.unknown;
  Phase({required this.label, required this.id, required this.description, required this.events, this.ended, this.started, this.state});

  factory Phase.fromJson(dynamic json) {
    Map<String, Event> eventsFromJson = {};
    for (dynamic eventJson in json['events']) {
      Event event = Event.fromJson(eventJson);
      eventsFromJson[event.id] = event;
    }
    eventsFromJson["UNKNWN"] = Event.unknownEvent();
    return Phase(
      label: json['label'],
      id: PhaseIdentifier.values[json['phase_id']],
      description: json['description'],
      events: eventsFromJson,
    );
  }
}

class PhasesFactory {
  // 1. Private constructor
  PhasesFactory._();

  // 2. The single instance
  static final PhasesFactory instance = PhasesFactory._();
  static final Phase _defaultPhase = Phase(
    id: PhaseIdentifier.unknown,
    label: '',
    description: '',
    events: {"UNKNWN":Event.unknownEvent()},
  );

  // 3. Cached storage
  Map<PhaseIdentifier, Phase> _phases = {};

  // 4. Initialization method (call this once at app startup)
  Future<void> initialize(String jsonPath) async {
    if (_phases.isNotEmpty) return; // Prevent re-parsing

    final String jsonString = await rootBundle.loadString(jsonPath);
    final List<dynamic> jsonList = json.decode(jsonString);

    _phases = {for (var item in jsonList) PhaseIdentifier.values[item['phase_id']]: Phase.fromJson(item)};
  }

  // 5. Easy access
  Phase getPhase(PhaseIdentifier phase) => _phases[phase] ?? _defaultPhase;

  Map<PhaseIdentifier, Phase> get allPhases => Map.unmodifiable(_phases);
}

// "SELECT
// e.event_timestamp,
// e.event_type_id,
// e.location_id,
// p.provider_name
// FROM clinical_events e
// LEFT JOIN providers p ON e.provider_id = p.provider_id
// WHERE e.encounter_id = 'ENC-908112'
// ORDER BY e.event_timestamp ASC;
// "
