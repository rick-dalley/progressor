
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


class PatientEvent{
  final PatientStatePhase phase;
  String eventId;
  DateTime occurred;
  String practitioner;
  String location;
  PatientEvent({required this.phase,required this.eventId, required this.occurred, required this.practitioner, required this.location});
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
  Phase({required this.label, required this.id, required this.description, required this.events});
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
        events:eventsFromJson
    );
  }
}


class PhasesFactory {
  final String jsonPath;
  PhasesFactory({required this.jsonPath});

  Future<Map<PatientStatePhase, Phase>> getPhases() async {
    // 1. Load the JSON string from assets
    final String jsonString = await rootBundle.loadString(jsonPath);

    // 2. Decode the string into a List (based on your previous JSON structure)
    final List<dynamic> jsonList = json.decode(jsonString);

    // 3. Build the map
    Map<PatientStatePhase, Phase> phasesMap = {};

    for (dynamic phaseJson in jsonList) {
      Phase phase = Phase.fromJson(phaseJson);
      phasesMap[phase.id] = phase;
    }

    return phasesMap;
  }
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

