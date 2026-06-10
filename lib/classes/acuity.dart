
import 'dart:convert';

import 'package:flutter/services.dart';

enum AcuityLevel {
  resuscitation, emergent, urgent, lessUrgent, notUrgent
}

class Descriptor{
  final String name;
  final String description;

  const Descriptor({required this.description, required this.name});

  factory Descriptor.fromJson(dynamic json){
    return Descriptor(
      name: json['name'] ?? "",
      description: json['description'] ?? ""
    );
  }
}

class Acuity {
  final AcuityLevel level;
  final String statusName;
  final String clinicalPicture;
  final List<Descriptor> presentingWith;
  final List<Descriptor> secondaryModifiers;
  final int interventionWindow;

  Acuity({
    required this.level,
    required this.statusName,
    required this.clinicalPicture,
    required this.interventionWindow,
    required this.presentingWith,
    required this.secondaryModifiers
  });

  // Using an initializer list is best practice for final fields in Dart
  factory Acuity.fromJson(dynamic json){
    List<Descriptor> complaints = [];
    List<Descriptor> modifiers = [];
    dynamic rawComplaints = json["presenting_complaints"];
    dynamic rawModifiers = json["secondary_modifiers"];
    for (dynamic item in rawComplaints){
      complaints.add(Descriptor.fromJson(item));
    }
    for (dynamic item in rawModifiers){
      modifiers.add(Descriptor.fromJson(item));
    }
    return Acuity(
        level : AcuityLevel.values[json['level']],
        statusName : json['status'],
        clinicalPicture : json['clinical_picture'],
        interventionWindow : json['intervention_window'],
      presentingWith: complaints,
      secondaryModifiers: modifiers

    );
  }
}

class AcuityFactory {
  // Private constructor
  AcuityFactory._();

  // The single instance
  static final AcuityFactory instance = AcuityFactory._();
  // Cached storage
  Map<AcuityLevel, Acuity> _acuities = {};

  // Initialization method (call this once at app startup)
  Future<void> initialize(String jsonPath) async {
    if (_acuities.isNotEmpty) return; // Prevent re-parsing

    final String jsonString = await rootBundle.loadString(jsonPath);
    final List<dynamic> jsonList = json.decode(jsonString);

_acuities = {
      for (var item in jsonList)
        AcuityLevel.values[item['level']]: Acuity.fromJson(item)

    };
  }

  // 5. Easy access
  Acuity? getAcuity({required AcuityLevel level}) => _acuities[level];

  Map<AcuityLevel, Acuity> get allAcuities => Map.unmodifiable(_acuities);

  List<Acuity> getAllAcuitiesExcept(AcuityLevel currentLevel) {
    // We access .values to get the list of Acuity objects
    return _acuities.values
        .where((acuity) => acuity.level != currentLevel)
        .toList();
  }
}