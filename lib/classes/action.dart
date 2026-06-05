import 'dart:convert';
import 'dart:core';
import 'package:flutter/services.dart';
import 'package:triage/classes/date_time_utilities.dart';
import 'package:triage/classes/phase_state_handlers.dart';

abstract class TimelineItem {
  int get occurred;
}

enum TransferRequestStatus { pending, approved, denied, retracted }

enum TransferDenialType {
  unstableMedicalCondition, //The patient requires a higher level of acuity—such as continuous monitoring, ventilators, or critical care nurses—which standard hospital wards are not equipped to provide.
  noAvailableBeds, // The destination ward is operating at maximum capacity and cannot safely accommodate another patient.
  specializedServiceUnavailable, // The specific medical or surgical services required are not offered at the receiving ward or facility.
  requiresMultidisciplinarySupport, //The patient requires extensive care coordination (e.g., new medical technology dependence, home health planning) that must be initiated prior to transfer.
  patientRefusal, //Competent patients or their medical power of attorney may decline the transfer if they are uncomfortable with the receiving care team or prefer to stay in their familiar unit.
  administrative, //
  insuranceAuthorizationMissing, // Delays can occur due to insurance authorization requirements or pending discharge paperwork.
  notDetermined,
}


enum ActionType {
  administerMedicine,
  performTest,
  answerQuestionnaire,
  observeBehaviour,
  performEventStep,
  interviewPatient,
  changePrescription,
}

Map<ActionType, String> actionLabels = {
  ActionType.administerMedicine: "Administered Medicine",
  ActionType.performTest: "Performed a Test",
  ActionType.answerQuestionnaire: "Answered a  Questionnaire",
  ActionType.observeBehaviour: "Observed Behaviour",
  ActionType.performEventStep: "Event Occurred",
  ActionType.interviewPatient: "Interviewed Patient",
  ActionType.changePrescription: "Changed Prescription",
};

class PatientEvent implements TimelineItem {
  final String patientUuid;
  final PhaseIdentifier phase;
  final String eventId;
  @override
  final int occurred;
  final String? notes;

  // 1. Standard Const Constructor
  const PatientEvent({
    required this.patientUuid,
    required this.eventId,
    this.notes,
    required this.phase,
    required this.occurred,
  });

  // 2. Factory Constructor for JSON
  factory PatientEvent.fromJson(Map<String, dynamic> json) {
    // Perform your logic here
    int rawPhase = json["phase_id"];

    // Return the result of the standard constructor
    return PatientEvent(
      patientUuid: json["patient_uuid"],
      phase: PhaseIdentifier.values[rawPhase],
      eventId: json["event_id"],
      occurred: json["occurred"],
      notes: json["notes"],
    );
  }
}

//Workflow: The 'Process'
class TransferRequest implements TimelineItem {
  final String id;
  final String patientUuid;
  final String requester;
  final String requestingTeam;
  final String granter;
  final String fromWard;
  final String toWard;
  final TransferRequestStatus status;
  final int requested;
  TransferDenialType? denial; // Nullable: only populated if denied
  int? disposed; //UNIX date time
  int? transferred; //UNIX date time
  String? notes;
  @override
  int occurred;

  TransferRequest({
    required this.id,
    required this.status,
    required this.requested,
    required this.patientUuid,
    required this.fromWard,
    required this.granter,
    required this.requester,
    required this.requestingTeam,
    required this.toWard,
    this.notes,
    this.disposed,
    this.transferred,
    this.denial,
  }) : occurred = requested;

  factory TransferRequest.fromJson(Map<String, dynamic> json) {
    int? rawDenialReason = json["denial"];
    int rawStatus = json["TransferRequestStatus"];
    TransferRequestStatus status = TransferRequestStatus.values[rawStatus];
    TransferDenialType denial = rawDenialReason == null
        ? TransferDenialType.notDetermined
        : TransferDenialType.values[rawDenialReason];
    return TransferRequest(
      id: json["id"],
      status: status,
      denial: denial,
      requested: json["requested"],
      patientUuid: json["patient_uuid"],
      requester: json["requested_by_uuid"],
      requestingTeam: json["requesting_team"],
      granter: json["grantor_uuid"],
      fromWard: json["from_ward"],
      toWard: json["to_ward"],
      transferred: DTUtilities.dateStringToUnixInt(json["transferred_at"]),
      disposed: DTUtilities.dateStringToUnixInt(json["disposed_at"]),
      notes: json["notes"],
    );
  }
}

//Clinical Act: The 'What'
class PatientAction implements TimelineItem {
  final String id;
  final String patientUuid;
  final String actionId;
  final String actorUuid;
  final String witnessUuid;
  final ActionType type;
  @override
  final int occurred;
  final String notes;

  String getName() {
    return actionLabels[type] ?? "Unknown";
  }

  PatientAction({
    required this.type,
    required this.notes,
    required this.id,
    required this.occurred,
    required this.patientUuid,
    required this.actionId,
    required this.actorUuid,
    required this.witnessUuid,
  });

  factory PatientAction.fromJson(Map<String, dynamic> json) {
    int rawType = json["action"] ?? 0;
    dynamic rawOccurred = json["occurred"];
    // Convert to Unix timestamp (seconds)
    int unixOccurred = DTUtilities.dateStringToUnixInt(rawOccurred.toString());

    return PatientAction(
      id: json["id"],
      patientUuid: json["patient_uuid"],
      actionId: json["id"],
      type: ActionType.values[rawType],
      occurred: unixOccurred,
      actorUuid: json["actor_uuid"] ?? "",
      witnessUuid: json["witness_uuid"] ?? "",
      notes: json["notes"] ?? "",
    );
  }

  DateTime getFormattedOccurred() {
    return DateTime.fromMillisecondsSinceEpoch(occurred * 1000);
  }
}

class PatientActionFactory {
  // 1. Private constructor
  PatientActionFactory._();

  // 2. The single instance
  static final PatientActionFactory instance = PatientActionFactory._();

  // 3. Private storage
  Map<String, PatientAction> _actions = {};

  // 4. Async initialization with path
  Future<void> initialize(String jsonPath) async {
    if (_actions.isNotEmpty) return;

    final String jsonString = await rootBundle.loadString(jsonPath);
    final List<dynamic> jsonList = json.decode(jsonString);

    _actions = {for (var item in jsonList) item['id']: PatientAction.fromJson(item)};
  }

  // 5. Accessors
  PatientAction? getAction(String id) => _actions[id];

  bool get isInitialized => _actions.isNotEmpty;

  // Optional: Get everything
  Map<String, PatientAction> get allActions => Map.unmodifiable(_actions);

  // Inside ActionFactory
  List<PatientAction> getActionsForPatient(String patientUuid) {
    return _actions.values.where((action) => action.patientUuid == patientUuid).toList();
  }
}

//The Aggregate: The 'Timeline'
class TimeLine {
  final String patientUuid;
  final int startTime;
  final int endTime;
  List<PatientAction> actions = [];
  List<TransferRequest> transfers = [];
  List<PatientEvent> events = [];

  TimeLine({
    required this.patientUuid,
    required this.endTime,
    required this.startTime,
    required this.events,
    required this.actions,
    required this.transfers,
  });

  factory TimeLine.fromJson(Map<String, dynamic> json) {
    List<dynamic> eventJson = json["events"];
    List<PatientEvent> newEvents = [];
    List<dynamic> transferJson = json["transfers"];
    List<TransferRequest> newTransfers = [];
    List<dynamic> actionJson = json["actions"];
    List<PatientAction> newActions = [];

    for (Map<String, dynamic> json in eventJson) {
      newEvents.add(PatientEvent.fromJson(json));
    }
    for (Map<String, dynamic> json in transferJson) {
      newTransfers.add(TransferRequest.fromJson(json));
    }
    for (Map<String, dynamic> json in actionJson) {
      newActions.add(PatientAction.fromJson(json));
    }

    return TimeLine(
      patientUuid: json["patient_uuid"],
      startTime: json["start_time"],
      endTime: json["end_time"],
      actions: newActions,
      transfers: newTransfers,
      events: newEvents,
    );
  }

  // This is the "Magic" method for your CustomPainter
  List<TimelineItem> get sortedChronology {
    List<TimelineItem> combined = [...actions, ...transfers, ...events];
    // Sort by integer using a common interface or getter
    combined.sort((a, b) => a.occurred.compareTo(b.occurred));
    return combined;
  }
}
