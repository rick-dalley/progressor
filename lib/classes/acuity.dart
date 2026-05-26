
class Acuity {
  final int level;
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
      : level = item['level'],
        statusName = item['status'],
        clinicalPicture = item['clinical_picture'],
        interventionWindow = item['intervention_window'];
}
