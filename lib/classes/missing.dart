import 'package:triage/classes/patient.dart';

import 'date_time_utilities.dart';

enum MentalHealthStatus{suicidal, psychotic, anxiety, disorder}
enum Substances{cocaine, marijuana, alcohol}
enum FinancialAnomalies{fundsMissing, lossOfIncome, unexpectedHardship, none}
enum VehicleType {car, suv, bicycle, motorcycle, atv, snowmobile, scooter, van, pickup, truck, rv}

class Vehicle{
  final String color;
  final VehicleType type;
  final String identifyingMarks;
  String? make;
  String? model;
  int? year;
  String? vin;
  String? licensePlate;
  Vehicle({required this.color, required this.type, required this.identifyingMarks});
}

class Missing{
  Patient? subject;
  final String id;
  final String clothing;
  final String identifyingMarks;
  final bool disappearedBefore;
  final bool accessToMeans;
  String mobilePhone;
  int lastSeen;
  String lastLocation;
  String travelling;
  String answersTo;
  String? photo;
  String? idCard;
  Vehicle? vehicle;
  String? present;
  List<String>? medicalNeeds;
  MentalHealthStatus? mentalHealthStatus;//: Do they have a history of suicidal ideation, psychosis, or depression? (This links directly to your SuicideRiskAssessment flags).
  String? mentalHealthStatusDescription;
  List<Substances>? substanceDependencies;//: Are there any known dependencies?
  String? socialMedia;
  FinancialAnomalies financialAnomalies;

  Missing({
    required this.id,
    required this.subject,
    required this.clothing,
    required this.identifyingMarks,
    required this.lastLocation,
    required this.travelling,
    required this.answersTo,
    this.photo,
    this.idCard,
    this.vehicle,
    this.present,
    this.accessToMeans = false,
    this.disappearedBefore = false,
    this.substanceDependencies,
    this.mentalHealthStatusDescription,
    this.medicalNeeds,
    this.mobilePhone = "",
    this.financialAnomalies = FinancialAnomalies.none
  }):lastSeen = DTUtilities.now();

  Map<String, dynamic> toMap() {
    return {
      'subject_id': id, // Assuming Patient has an ID
      'clothing': clothing,
      'identifying_marks': identifyingMarks,
      'disappeared_before': disappearedBefore ? 1 : 0,
      'access_to_means': accessToMeans ? 1 : 0,
      'mobile_phone': mobilePhone,
      'last_seen': lastSeen,
      'last_location': lastLocation,
      'travelling': travelling,
      'answers_to': answersTo,
      'photo_path': photo,
      'id_path': id,
      // Handle complex types
      'medical_needs': medicalNeeds?.join(','),
      'mental_health_status': mentalHealthStatus?.index,
      'mental_health_description': mentalHealthStatusDescription,
      'substance_dependencies': substanceDependencies?.map((s) => s.index).join(','),
      'financial_anomalies': financialAnomalies.index,
    };
  }

  factory Missing.fromMap(Map<String, dynamic> map, Patient? subject) {
    return Missing(
      subject: subject,
      clothing: map['clothing'],
      identifyingMarks: map['identifying_marks'],
      lastLocation: map['last_location'],
      travelling: map['travelling'],
      answersTo: map['answers_to'],
      photo: map['photo_path'],
      id: map['id_path'],
      accessToMeans: map['access_to_means'] == 1,
      disappearedBefore: map['disappeared_before'] == 1,
      medicalNeeds: (map['medical_needs'] as String?)?.split(','),
      // mentalHealthStatus: map['mental_health_status'] != null
      //     ? MentalHealthStatus.values[map['mental_health_status']] : null,
      substanceDependencies: (map['substance_dependencies'] as String?)
          ?.split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => Substances.values[int.parse(s)])
          .toList(),
      financialAnomalies: FinancialAnomalies.values[map['financial_anomalies'] ?? 0],
      mentalHealthStatusDescription: map['mental_health_description'],
      mobilePhone: map['mobile_phone'],
    );
  }

}
