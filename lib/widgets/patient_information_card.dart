import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/database_manager.dart';
import '../app_theme.dart';
import '../classes/medication_services.dart';
import '../classes/metric_value.dart';
import '../classes/patient.dart';
import 'body_metrics.dart';

class StringValuePair {
  final String label;
  final dynamic value;

  const StringValuePair({required this.value, required this.label});
}

class Tuple {
  final StringValuePair first;
  final StringValuePair second;

  const Tuple({required this.first, required this.second});
}

class PatientInformationCard extends StatefulWidget {
  final Patient patient;
  final VoidCallback? onPoliceTap;
  final VoidCallback? onAssessmentsTap;
  final VoidCallback onInterviewTap; // <--- Add this
  final VoidCallback? onMedsTap;

  const PatientInformationCard({
    super.key,
    required this.patient,
    this.onPoliceTap,
    this.onAssessmentsTap,
    required this.onInterviewTap,
    this.onMedsTap,
  });

  @override
  State<StatefulWidget> createState() => PatientInformationCardState();
}

class PatientInformationCardState extends State<PatientInformationCard> {
  late Patient patient;
  String heightUom = "cm";
  String weightUom = "kg";

  @override
  void initState() {
    super.initState();
    patient = widget.patient;
  }

  void onMetricsChanged({double? newHeight, double? newWeight}) async {
    final String patientUuid = patient.patientUuid;
    if (patientUuid.isEmpty) return;

    // --- HANDLE HEIGHT FILTER ---
    if (newHeight != null && newHeight > 0) {
      final MetricValue? lastHeightMetric = await DatabaseManager().getLatestMetric(patientUuid, 'height');

      if (lastHeightMetric == null || lastHeightMetric.value != newHeight) {
        await DatabaseManager().insertPatientMetric(patientUuid, newHeight, 'height');
        setState(() {
          patient.height = newHeight;
          widget.patient.height = newHeight;
        });
      }
      // else {
      //   debugPrint("Optimization: Height unchanged. Skipped write.");
      // }
    }

    // --- HANDLE WEIGHT FILTER ---
    if (newWeight != null && newWeight > 0) {
      final MetricValue? lastWeightMetric = await DatabaseManager().getLatestMetric(patientUuid, 'weight');
      bool shouldWriteWeight = true;

      if (lastWeightMetric != null) {
        final Duration timeSinceLastLog = DateTime.now().difference(lastWeightMetric.recorded);
        if (lastWeightMetric.value == newWeight && timeSinceLastLog.inHours < 23) {
          shouldWriteWeight = false;
          // debugPrint("Optimization: Weight stable and logged within 23h. Skipped write.");
        }
      }

      if (shouldWriteWeight) {
        await DatabaseManager().insertPatientMetric(patientUuid, newWeight, 'weight');
        setState(() {
          patient.weight = newWeight;
          widget.patient.weight = newWeight;
        });
      }
    }
  }

  void _showMetricsEntryDialog({
    required BuildContext context,
    double? initialHeight,
    required String initialHeightUom,
    double? initialWeight,
    required String initialWeightUom,
  }) {
    // Sanitize variables and assign them to strict local copies
    // BEFORE entering the framework's showDialog execution stack.
    final double? cleanHeight = (initialHeight == 0.0) ? null : initialHeight;
    final double? cleanWeight = (initialWeight == 0.0) ? null : initialWeight;
    // Normalize the unit strings here to avoid doing text mutations inside the render tree
    final String normalizedHeightUom = initialHeightUom.toLowerCase();
    final String normalizedWeightUom = initialWeightUom.toLowerCase();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Update Patient Metrics',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepCharcoal),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BodyMetricsWidget(
                  height: cleanHeight,
                  weight: cleanWeight,
                  heightUom: normalizedHeightUom,
                  weightUom: normalizedWeightUom,
                  onMetricsChanged: (newWeightValue, newHeightValue) {
                    //Pop the UI instantly so the app feels snappy
                    Navigator.pop(dialogContext);
                    Future.microtask(() {
                      onMetricsChanged(newWeight: newWeightValue, newHeight: newHeightValue);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTappableMetricsRow({
    required BuildContext context,
    double? currentHeight,
    required String heightUom,
    double? currentWeight,
    required String weightUom,
  }) {
    final heightStr = currentHeight != null ? '${currentHeight.toStringAsFixed(1)} $heightUom' : 'Not Set';
    final weightStr = currentWeight != null ? '${currentWeight.toStringAsFixed(1)} $weightUom' : 'Not Set';
    final bmiValue = MedicalMath.calculateBMI(
      weight: currentWeight ?? 0.0,
      weightUom: weightUom,
      height: currentHeight ?? 0.0,
      heightUom: heightUom,
    );
    final bmiStr = bmiValue > 0 ? bmiValue.toStringAsFixed(1) : 'Not Set';

    return InkWell(
      onTap: () {
        _showMetricsEntryDialog(
          context: context,
          initialHeight: currentHeight,
          initialHeightUom: heightUom,
          initialWeight: currentWeight,
          initialWeightUom: weightUom,
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            // 1. HEIGHT COLUMN (Occupies exactly 1/3 of available row space)
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HEIGHT', // Pro-tip: Shortening labels to HT/WT saves massive real estate on small screens
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      heightStr,
                      style: const TextStyle(fontSize: 13, color: AppTheme.deepCharcoal, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis, // Prevents layout explosion if string is long
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4), // Small safe gutter padding
            // 2. WEIGHT COLUMN (Occupies exactly 1/3 of available row space)
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'WEIGHT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      weightStr,
                      style: const TextStyle(fontSize: 13, color: AppTheme.deepCharcoal, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // 3. BMI COLUMN (Occupies exactly 1/3 of available row space)
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BMI',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      bmiStr,
                      style: const TextStyle(fontSize: 13, color: AppTheme.deepCharcoal, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),

            // 4. FIXED ICON ANCHOR
            Icon(Icons.edit, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = '${patient.firstName} ${patient.lastName}';
    bool hasReports = patient.policeReports > 0;
    Color? medColor;
    if (patient.medications > 0) {
      switch (patient.medicationSafetyAudit) {
        case MedicationSafetyAudit.interactionsNotDetected:
          medColor = Colors.greenAccent;
          break;
        case MedicationSafetyAudit.interactionsDetected:
          medColor = Colors.redAccent;
          break;
        case MedicationSafetyAudit.auditNotPerformed:
          // Keep default theme colors
          break;
      }
    }

    return Card(
      elevation: 2,
      color: const Color(0xFFFBFBFB), // Ultra-clean clinical off-white
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line 1: Patient Name & Process Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepCharcoal),
                  overflow: TextOverflow.ellipsis,
                ),
                Spacer(),
                Text("Provincial Health #:"),
                Text(_formatPHN(patient.phn.toString())),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Born: ${patient.formattedDateOfBirth} (${patient.age} yrs)"),
                Spacer(),
                Text("Admitted: ${patient.formattedAdmissionDate}"),
              ],
            ),
            SizedBox(height: 16),
            _buildTappableMetricsRow(
              context: context,
              currentHeight: patient.height,
              heightUom: patient.heightUoM,
              currentWeight: patient.weight,
              weightUom: patient.weightUoM,
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8, // Horizontal space between buttons
              runSpacing: 8, // Vertical space between lines
              alignment: WrapAlignment.start,
              children: [
                _buildCompactButton(
                  context: context,
                  label: "Assess",
                  icon: Symbols.medical_information,
                  onTap: widget.onAssessmentsTap ?? () {},
                ),
                _buildCompactButton(
                  context: context,
                  label: "Interview",
                  icon: Icons.mic,
                  onTap: widget.onInterviewTap,
                ),
                _buildCompactButton(
                  context: context,
                  label: "Meds",
                  icon: Symbols.medication,
                  onTap: widget.onMedsTap ?? () {},
                  color: medColor,
                ),
                _buildCompactButton(
                  context: context,
                  label: "Police",
                  icon: Icons.local_police,
                  onTap: widget.onPoliceTap ?? () {},
                  color: hasReports ? Colors.greenAccent : null,
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildTuple(
              Tuple(
                first: StringValuePair(label: "CONTACT:", value: patient.contactName),
                second: StringValuePair(label: "PHONE:", value: patient.contactPhone),
              ),
            ),
            _buildTuple(
              Tuple(
                first: StringValuePair(label: "DOCTOR:", value: patient.familyDoctorName),
                second: StringValuePair(label: "PHONE:", value: patient.familyDoctorPhone),
              ),
            ),
            _buildTuple(
              Tuple(
                first: StringValuePair(label: "PHARMACY:", value: patient.pharmacyPhone),
                second: StringValuePair(label: "FAX:", value: patient.pharmacyFax),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper row helper to maintain perfect horizontal tabular alignment across fields
  Widget _buildTuple(Tuple tuple) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
            child: Row(
              children: [
                Text(
                  tuple.first.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tuple.first.value,
                    style: const TextStyle(fontSize: 13, color: AppTheme.deepCharcoal, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16), // Gutter separation between the two columns
        // RIGHT COLUMN (Second Pair: e.g., CONTACT or PHARMACY)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
            child: Row(
              children: [
                Text(
                  tuple.second.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tuple.second.value,
                    style: const TextStyle(fontSize: 13, color: AppTheme.deepCharcoal, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Standard string parser to separate long digits into readable "#### ### ###" blocks
  String _formatPHN(String rawPhn) {
    final clean = rawPhn.replaceAll(RegExp(r'\s+'), '');
    if (clean.length == 10) {
      return "${clean.substring(0, 4)} ${clean.substring(4, 7)} ${clean.substring(7)}";
    }
    return rawPhn; // Fallback if format differs
  }

  Widget _buildCompactButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    double availableWidth = MediaQuery.of(context).size.width - 80; // Adjusted for margins
    return SizedBox(
      width: availableWidth / 4,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          // 1. Force a minimum height so the icon and text aren't cramped
          minimumSize: const Size(0, 54),
          // 2. Add specific vertical padding
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          foregroundColor: color,
          side: color != null ? BorderSide(color: color, width: 1.5) : null,
          backgroundColor: color?.withAlpha(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22), // Slightly larger icon
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.normal,
                letterSpacing: -0.2, // Tighter letters to prevent overflow
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
