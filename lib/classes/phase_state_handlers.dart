
import 'dart:convert';

import 'package:flutter/services.dart';

enum SentimentScale {
  calm, content, neutral, dissatisfied, stressed
}


enum PatientStatePhase{
  preHospitalAndIntake,
  assessmentAndBedTracking,
  diagnosticsAndInterventions,
  safetyAndLegalInterventions,
  consultationsAndDecisions,
  inpatientAdmissionPathway,
  dischargePathway,
  unknown,
}

class Event {
  String id;
  String label;
  String description;
  Event({required this.id, required this.label, required this.description});
  factory Event.fromJson(dynamic eventJson){
    return Event(
        id: eventJson['event_id'],
        label: eventJson['label'],
        description: eventJson['description']
    );
  }
}

class Phase {
  String label;
  PatientStatePhase id;
  String description;
  Map<String, Event>? events;
  Phase({required this.label, required this.id, required this.description, required this.events, required String name});
  factory Phase.fromJson(dynamic phaseJson){
    Map<String, Event> eventsFromJson = {};
    for(dynamic eventJson in phaseJson['events']){
      Event event = Event.fromJson(eventJson);
      eventsFromJson[event.id] = event;
    }
    return Phase(
        label:phaseJson['phase'],
        id:PatientStatePhase.values[phaseJson['phase_id']],
        description:'',             //phaseJson[''],
        events:eventsFromJson, name: ''
    );
  }
}

class PhasesFactory {
  // 1. Private constructor
  PhasesFactory._();

  // 2. The single instance
  static final PhasesFactory instance = PhasesFactory._();
  static final Phase _defaultPhase = Phase(id: PatientStatePhase.unknown, name: 'Unknown', label: '', description: '', events: {});
  // 3. Cached storage
  Map<PatientStatePhase, Phase> _phases = {};

  // 4. Initialization method (call this once at app startup)
  Future<void> initialize(String jsonPath) async {
    if (_phases.isNotEmpty) return; // Prevent re-parsing

    final String jsonString = await rootBundle.loadString(jsonPath);
    final List<dynamic> jsonList = json.decode(jsonString);

    _phases = {
      for (var item in jsonList)
        PatientStatePhase.values[item['phase_id']]: Phase.fromJson(item)

    };
    Event unknownEvent = Event(id:"UKNWN", label: "Unknown Event", description: "this event is not officially registered");
    Map<String, Event> unknownEvents = { "UKNWN": unknownEvent };
    _phases[PatientStatePhase.unknown] = Phase(id: PatientStatePhase.unknown, description:"unknown phase", label:"unknown", events: unknownEvents, name: '', );

  }

  // 5. Easy access
  Phase getPhase(PatientStatePhase phase) => _phases[phase] ?? _defaultPhase;

  Map<PatientStatePhase, Phase> get allPhases => Map.unmodifiable(_phases);
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

