
import 'dart:convert';

import 'package:flutter/services.dart';

enum AcuityLevel {
  resuscitation, emergent, urgent, lessUrgent, notUrgent
}

class Acuity {
  final AcuityLevel level;
  final String statusName;
  final String clinicalPicture;
  final int interventionWindow;

  Acuity({
    required this.level,
    required this.statusName,
    required this.clinicalPicture,
    required this.interventionWindow,
  });

  // Using an initializer list is best practice for final fields in Dart
  Acuity.fromJson(dynamic item)
      : level = AcuityLevel.values[item['level']],
        statusName = item['status'],
        clinicalPicture = item['clinical_picture'],
        interventionWindow = item['intervention_window'];
}

class AcuityFactory {
  // 1. Private constructor
  AcuityFactory._();

  // 2. The single instance
  static final AcuityFactory instance = AcuityFactory._();
  static final Acuity _defaultAcuity = Acuity(level: AcuityLevel.notUrgent, interventionWindow: 120,statusName: "Non-Urgent", clinicalPicture: "Minor, chronic issues; long-standing psychiatric conditions seeking routine evaluation or social support referrals.");
  // 3. Cached storage
  Map<AcuityLevel, Acuity> _acuities = {};

  // 4. Initialization method (call this once at app startup)
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
  Acuity getAcuity(AcuityLevel level) => _acuities[level] ?? _defaultAcuity;

  Map<AcuityLevel, Acuity> get allAcuities => Map.unmodifiable(_acuities);
}