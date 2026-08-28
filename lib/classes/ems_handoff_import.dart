import 'dart:convert';

// The receiving half of Acuitage's EMS handoff (see acuitage's ems_handoff_export.dart)
// — no shared backend, a paramedic emails a summary whose body carries a
// progressor://import?data=... deep link. Key names here must match Acuitage's export
// exactly — there's no shared package/type between the two apps for this payload today.
class EmsHandoffImportPayload {
  final String firstName;
  final String lastName;
  final DateTime? dob;
  final String? phn;
  final String? acuityLevel;
  final String? assessmentType;
  final String? topDiagnosis;
  final Map<String, double> vitals;
  final String? narrative;
  final String? incidentName;
  final String? dispatchCode;
  final List<String> crew;
  final String? destinationFacility;
  final String? contactName;
  final String? contactPhone;
  final String? familyDoctorName;
  final String? familyDoctorPhone;
  final DateTime deliveredAt;

  const EmsHandoffImportPayload({
    required this.firstName,
    required this.lastName,
    this.dob,
    this.phn,
    this.acuityLevel,
    this.assessmentType,
    this.topDiagnosis,
    this.vitals = const {},
    this.narrative,
    this.incidentName,
    this.dispatchCode,
    this.crew = const [],
    this.destinationFacility,
    this.contactName,
    this.contactPhone,
    this.familyDoctorName,
    this.familyDoctorPhone,
    required this.deliveredAt,
  });

  // Returns null rather than throwing — a malformed or truncated link shouldn't crash
  // the app that just opened it (same reasoning as Ally's CarePlanImportPayload).
  static EmsHandoffImportPayload? tryParse(Uri uri) {
    final String? encoded = uri.queryParameters['data'];
    if (encoded == null) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(utf8.decode(base64Url.decode(encoded))) as Map<String, dynamic>;
      final Map<String, dynamic> rawVitals = json['vitals'] as Map<String, dynamic>? ?? {};
      return EmsHandoffImportPayload(
        firstName: json['firstName'] as String? ?? 'Unknown',
        lastName: json['lastName'] as String? ?? 'Patient',
        dob: json['dob'] != null ? DateTime.tryParse(json['dob'] as String) : null,
        phn: json['phn'] as String?,
        acuityLevel: json['acuityLevel'] as String?,
        assessmentType: json['assessmentType'] as String?,
        topDiagnosis: json['topDiagnosis'] as String?,
        vitals: rawVitals.map((key, value) => MapEntry(key, (value as num).toDouble())),
        narrative: json['narrative'] as String?,
        incidentName: json['incidentName'] as String?,
        dispatchCode: json['dispatchCode'] as String?,
        crew: (json['crew'] as List<dynamic>? ?? []).cast<String>(),
        destinationFacility: json['destinationFacility'] as String?,
        contactName: json['contactName'] as String?,
        contactPhone: json['contactPhone'] as String?,
        familyDoctorName: json['familyDoctorName'] as String?,
        familyDoctorPhone: json['familyDoctorPhone'] as String?,
        deliveredAt: DateTime.tryParse(json['deliveredAt'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
