import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:triage/classes/database_manager.dart';
import 'package:triage/classes/date_time_utilities.dart';
import 'package:triage/classes/patient_sentiment.dart';
import 'package:triage/classes/template_text.dart';

import 'body_zone.dart';

enum VerbalSeverity {
  none, // = No pain.
  mild, // = Pain is very mild, barely noticeable. Most of the time you don't think about it.,// = Minor pain. It's annoying. You may have sharp pain now and then.
  minor, // = Noticeable pain. It may distract you, but you can get used to it.
  moderate, // = Moderate pain. If you are involved in an activity, you're able to ignore the pain for a while. But it is still distracting.
  moderatelyStrong, // = Moderately strong pain. You can't ignore it for more than a few minutes. But, with effort, you can still work or do some social activities.
  moderatelyStronger, // = Moderately stronger pain. You avoid some of your normal daily activities. You have trouble concentrating.
  strong, // = Strong pain. It keeps you from doing normal activities.
  intense, // = Very strong pain. It's hard to do anything at all.
  excruciating, // = Pain that is very hard to tolerate. You can't carry on a conversation.
  worst, // = Worst pain possible.
}

Map<VerbalSeverity, String> severityExplanations = {
  VerbalSeverity.none: "No pain.",
  VerbalSeverity.mild:
      "Pain is very mild, barely noticeable. Most of the time you don't think about it. Minor pain. It's annoying. You may have sharp pain now and then.",
  VerbalSeverity.minor: "Noticeable pain. It may distract you, but you can get used to it.",
  VerbalSeverity.moderate:
      "Moderate pain. If you are involved in an activity, you're able to ignore the pain for a while. But it is still distracting.",
  VerbalSeverity.moderatelyStrong:
      "Moderately strong pain. You can't ignore it for more than a few minutes. But, with effort, you can still work or do some social activities.",
  VerbalSeverity.moderatelyStronger:
      "Moderately stronger pain. You avoid some of your normal daily activities. You have trouble concentrating.",
  VerbalSeverity.strong: "Strong pain. It keeps you from doing normal activities.",
  VerbalSeverity.intense: "Very strong pain. It's hard to do anything at all.",
  VerbalSeverity.excruciating: "Pain that is very hard to tolerate. You can't carry on a conversation.",
  VerbalSeverity.worst: "Worst pain possible.",
};

enum Frequency { cyclical, chronic, acute }

enum Nature { stinging, penetrating, dull, throbbing, achy, nagging, gnawing, sharp }

typedef Chips = List<TemplateText>;

class BodyMarker {
  final Offset offset;
  final Sentiment emoji;
  final AnatomyZoneMaps zoneMap;
  final String name;
  final String medicalName;
  final BodyMarkerGroup group;
  Chips? descriptions = [];
  VerbalSeverity? severity;
  Frequency? frequency;
  Nature? nature;
  Chips? improvesWhen;
  Chips? worsensWhen;
  Chips? interventionsTried;
  int? recorded = DTUtilities.now();

  BodyMarker({
    required this.offset,
    required this.emoji,
    required this.name,
    required this.medicalName,
    required this.zoneMap,
    required this.group,
    this.descriptions,
    this.severity,
    this.frequency,
    this.nature,
    this.improvesWhen,
    this.worsensWhen,
    this.interventionsTried,
    this.recorded,
  });

  static Chips chipList(dynamic json) {
    Chips chips = [];
    for (dynamic desc in json) {
      TemplateText tt = TemplateText.fromJson(desc);
      chips.add(tt);
    }
    return chips;
  }

  factory BodyMarker.fromOffset(
    Offset offset,
    String name,
    String medicalName,
    AnatomyZoneMaps zoneMap,
    BodyMarkerGroup markerGroup,
  ) {
    return BodyMarker(
      offset: offset,
      emoji: Sentiment.stressed,
      name: name,
      medicalName: medicalName,
      zoneMap: zoneMap,
      group: markerGroup,
    );
  }
  factory BodyMarker.fromJson(Map<String, dynamic> item) {
    int severityIndex = item["severity"];
    int emojiIndex = item["emoji"];
    int frequencyIndex = item["frequency"];
    int natureIndex = item["nature"];
    AnatomyZoneMaps zoneMap = AnatomyZoneMaps.values[item["map"]];
    Zone zoneFromJson = Zone.fromJson(item["zone"], zoneMap);
    double dx = item["dx"];
    double dy = item["dy"];
    Chips descriptionChips = chipList(item["description"]);
    Chips improvesWhenChips = chipList(item["improves_when"]);
    Chips worsensWhenChips = chipList(item["worsens_when"]);
    Chips interventionsTriedChips = chipList(item["interventions_tried"]);

    return BodyMarker(
      offset: Offset(dx, dy),
      name: zoneFromJson.name,
      medicalName: zoneFromJson.latin,
      descriptions: descriptionChips,
      severity: VerbalSeverity.values[severityIndex],
      emoji: Sentiment.values[emojiIndex],
      frequency: Frequency.values[frequencyIndex],
      nature: Nature.values[natureIndex],
      improvesWhen: improvesWhenChips,
      worsensWhen: worsensWhenChips,
      interventionsTried: interventionsTriedChips,
      recorded: item["recorded"],
      group: BodyMarkerGroup.values[item['group']],
      zoneMap: zoneFromJson.map,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "dx": offset.dx,
      "dy": offset.dy,
      "name": name,
      "medical_name": medicalName,
      "emoji": emoji.index,
      "severity": severity?.index,
      "frequency": frequency?.index,
      "nature": nature?.index,
      "improves_when": improvesWhen?.map((e) => e.toJson()).toList(),
      "worsens_when": worsensWhen?.map((e) => e.toJson()).toList(),
      "interventions_tried": interventionsTried?.map((e) => e.toJson()).toList(),
      "descriptions": descriptions?.map((e) => e.toJson()).toList(),
      "recorded": recorded,
      "zone": zoneMap,
      "group": group,
    };
  }

  Future<void> save({required String patientUuid, required BodyMarker marker}) async {
    DatabaseManager().insertBodyMarker(patientUuid, marker.toJson());
  }
}

class MarkerFactory {
  // Singleton pattern for clean access across your app
  static final MarkerFactory instance = MarkerFactory._internal();
  factory MarkerFactory() => instance;
  MarkerFactory._internal();

  Future<List<BodyMarker>> getMarkersForPatient(String patientUuid) async {
    // 1. Fetch raw data from the actual database
    final List<Map<String, dynamic>> rawData = await DatabaseManager().getMarkersForPatient(patientUuid);

    // 2. Hydrate: Convert JSON strings back to lists, then to BodyMarker objects
    return rawData.map((item) {
      // Create a mutable copy to perform decoding
      Map<String, dynamic> decodedItem = Map<String, dynamic>.from(item);

      // Decode the stored JSON strings back into dynamic lists
      decodedItem['description'] = jsonDecode(decodedItem['descriptions'] ?? '[]');
      decodedItem['improves_when'] = jsonDecode(decodedItem['improves_when'] ?? '[]');
      decodedItem['worsens_when'] = jsonDecode(decodedItem['worsens_when'] ?? '[]');
      decodedItem['interventions_tried'] = jsonDecode(decodedItem['interventions_tried'] ?? '[]');

      return BodyMarker.fromJson(decodedItem);
    }).toList();
  }

  Future<void> saveMarkersForPatient(String patientUuid, List<BodyMarker> markers) async {
    // Convert BodyMarkers to the database-friendly Map format
    List<Map<String, dynamic>> rows = markers.map((marker) {
      Map<String, dynamic> row = marker.toJson();
      row['patient_uuid'] = patientUuid;

      // Handle the serialization logic here, NOT in the database manager
      row['descriptions'] = jsonEncode(row['descriptions'] ?? []);
      row['improves_when'] = jsonEncode(row['improves_when'] ?? []);
      row['worsens_when'] = jsonEncode(row['worsens_when'] ?? []);
      row['interventions_tried'] = jsonEncode(row['interventions_tried'] ?? []);

      return row;
    }).toList();

    // The database manager just sees raw data, not 'Markers'
    await DatabaseManager().insertMarkersBatch('body_markers', rows);
  }
}
