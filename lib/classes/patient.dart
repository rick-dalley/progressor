import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:triage/classes/acuity.dart';
import 'package:triage/classes/patient_sentiment.dart';
import 'package:triage/classes/vitals.dart';

import 'database_manager.dart';
import 'date_time_utilities.dart';
import 'medication_services.dart';

enum PatientState { stable, labile, agitated, catatonic, withdrawn }

class Patient {
  final String patientUuid; //'02039325-2425-4bf3-bf85-1ec81a797e25',
  final String firstName; //'Silvain',
  final String lastName; //'Saulter',
  final String phn; //'807-831-0857',
  final int phaseStepId; //301,
  final String email; //'ssaulter0@spotify.com',
  final String ssn; //'305-41-7220',
  final String title; //'Rev',
  final String city; //'Vyerkhnyadzvinsk',
  final String country; //'final String Belarus',
  final String streetAddress; //'0565 Blue Bill Park Avenue',
  final String state; //null,
  final String postalCode; //null,
  final DateTime dob; //'4/27/2019',
  final DateTime admitted; //'12/25/2025',
  final String status; //'Unstable',
  final String path; //'Custody',
  final int flags; //'Involuntary',
  final String phone; //'443-449-5848',
  final String familyDoctorPhone; //'857-582-7784',
  final String contactPhone; //'364-303-6922',
  final String pharmacyPhone; //'433-729-8681',
  final String pharmacyFax; //'509-196-1665',
  final String familyDoctorName; //'Silvain Saulter',
  final String relation; //'Partner',
  final String contactName; //'Silvain Saulter',
  String eyeColor;
  Sentiment sentiment;
  int assessments; //279,
  int medications; //11,
  MedicationSafetyAudit medicationSafetyAudit; //1,
  AcuityLevel acuityLevel; //3,
  int policeReports; //2,
  double height;
  String heightUoM;
  double weight;
  String weightUoM;
  String narrativeHint;
  String formattedDateOfBirth;
  String formattedAdmissionDate;
  int age;
  CurrentVitalsRecord? vitals;
  bool isAWOL;

  Patient({
    required this.patientUuid,
    required this.firstName,
    required this.lastName,
    required this.phn,
    required this.phaseStepId,
    required this.email,
    required this.ssn,
    required this.title,
    required this.city,
    required this.country,
    required this.streetAddress,
    required this.state,
    required this.postalCode,
    required this.dob,
    required this.admitted,
    required this.status,
    required this.path,
    required this.flags,
    required this.phone,
    required this.familyDoctorPhone,
    required this.contactPhone,
    required this.pharmacyPhone,
    required this.pharmacyFax,
    required this.familyDoctorName,
    required this.contactName,
    required this.relation,
    this.assessments = 0,
    this.medications = 0,
    this.medicationSafetyAudit = MedicationSafetyAudit.auditNotPerformed,
    this.policeReports = 0,
    this.acuityLevel = AcuityLevel.notUrgent,
    this.height = 0,
    this.heightUoM = "cm",
    this.weight = 0,
    this.weightUoM = "kg",
    this.narrativeHint = "",
    this.formattedAdmissionDate = "",
    this.formattedDateOfBirth = "",
    this.age = 17,
    this.vitals,
    this.sentiment = Sentiment.neutral,
    this.eyeColor = "",
    this.isAWOL = false,
  });

  factory Patient.fromJson(Map<String, dynamic> item) {
    final DateTime adm = DTUtilities.randomHrsAgo(max: 48);
    final DateTime birth = DTUtilities.randomYrsAgo(min: 17, max: 95);
    CurrentVitalsRecord vitalsRecord = CurrentVitalsRecord.fromPatientJson(item);
    int sentimentIndex = Random().nextInt(5);
    Sentiment sentiment = Sentiment.values[sentimentIndex];

    return Patient(
      patientUuid: item['patient_uuid'],
      //'02039325-2425-4bf3-bf85-1ec81a797e25',
      firstName: item['first_name'],
      //'Silvain',
      lastName: item['last_name'],
      //'Saulter',
      phn: item['phn'],
      //'807-831-0857',
      phaseStepId: item['phase_step_id'],
      //301,
      email: item['email'],
      //'ssaulter0@spotify.com',
      ssn: item['ssn'],
      //'305-41-7220',
      title: item['title'],
      //'Rev',
      city: item['city'],
      //'Vyerkhnyadzvinsk',
      country: item['country'],
      //'Belarus',
      streetAddress: item['street_address'],
      //'0565 Blue Bill Park Avenue',
      state: item['state'] ?? "",
      //null,
      postalCode: item['postal_code'] ?? "",
      //null,
      dob: birth,
      //'4/27/2019',
      admitted: adm,
      //'12/25/2025',
      acuityLevel: AcuityLevel.values[item['acuity']],
      //3,
      policeReports: item['police_reports'],
      //2,
      assessments: item['assessments'],
      //279,
      medications: item['medications'] ?? 0,
      //11,
      medicationSafetyAudit: item['medicationsafety_audit'] != null
          ? MedicationSafetyAudit.values[item['medicationsafety_audit']]
          : MedicationSafetyAudit.auditNotPerformed,
      //1,
      status: item['status'] ?? "",
      //'Unstable',
      path: item['path'],
      //'Custody',
      flags: item['flags'] ?? 0,
      //'Involuntary',
      phone: item['phone'],
      //'443-449-5848',
      familyDoctorPhone: item['family_doctor_phone'],
      //'857-582-7784',
      contactPhone: item['contact_phone'],
      //'364-303-6922',
      pharmacyPhone: item['pharmacy_phone'],
      //'433-729-8681',
      pharmacyFax: item['pharmacy_fax'],
      //'509-196-1665',
      familyDoctorName: item['family_doctor_name'],
      //'Silvain Saulter',
      contactName: item['contact_name'],
      //'Silvain Saulter',
      relation: item['relation'],
      height: item['current_height'] ?? 0,
      weight: item['current_weight'] ?? 0,
      age: DTUtilities.calculateYearsSince(birth),
      formattedDateOfBirth: DateFormat.yMEd().format(birth),
      formattedAdmissionDate: DateFormat.yMEd().format(adm),
      vitals: vitalsRecord,
      //'Partner',
      narrativeHint: item['narrative_hint'] ?? "", //'Maecenas ut massa ...
      sentiment: sentiment,
      eyeColor: "brown", //item["eye_color"],
    );
  }
  factory Patient.copy({required Patient patient}) {
    return Patient(
      patientUuid: patient.patientUuid,
      firstName: patient.firstName,
      lastName: patient.lastName,
      phn: patient.phn,
      phaseStepId: patient.phaseStepId,
      email: patient.email,
      ssn: patient.ssn,
      title: patient.title,
      city: patient.city,
      country: patient.country,
      streetAddress: patient.streetAddress,
      state: patient.state,
      postalCode: patient.postalCode,
      dob: patient.dob,
      admitted: patient.admitted,
      acuityLevel: patient.acuityLevel,
      policeReports: patient.policeReports,
      assessments: patient.assessments,
      medications: patient.medications,
      medicationSafetyAudit: patient.medicationSafetyAudit,
      status: patient.status,
      path: patient.path,
      flags: patient.flags,
      phone: patient.phone,
      familyDoctorPhone: patient.familyDoctorPhone,
      contactPhone: patient.contactPhone,
      pharmacyPhone: patient.pharmacyPhone,
      pharmacyFax: patient.pharmacyFax,
      familyDoctorName: patient.familyDoctorName,
      contactName: patient.contactName,
      relation: patient.relation,
      height: patient.height,
      weight: patient.weight,
      age: patient.age,
      vitals: patient.vitals,
      narrativeHint: patient.narrativeHint,
      eyeColor: "brown",
    );
  }

  Patient copyWithAcuity({required Patient oldPatient, required AcuityLevel acuityLevel}) {
    Patient patient = Patient.copy(patient: oldPatient);
    patient.acuityLevel = acuityLevel;
    return patient;
  }
}

class PatientController extends ChangeNotifier {
  Patient patient;

  // Use your existing DatabaseManager instance

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  PatientController(this.patient);

  Future<void> addAcuity(Acuity newAcuity, String rationale) async {
    _isLoading = true;
    notifyListeners();

    try {
      // await _db.insertAcuity(patientUuid: patient.patientUuid, acuity: newAcuity, rationale: rationale);
      await DatabaseManager().insertAcuity(
        patientUuid: patient.patientUuid,
        acuityLevel: newAcuity.level,
        rationale: rationale,
        encounterId: '',
        setBu: '',
      );
      patient.acuityLevel = newAcuity.level;
    } catch (e) {
      // Handle or re-throw error if needed
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
