import 'dart:math';
import 'package:flutter/material.dart';
import 'package:triage/widgets/process_path.dart';
import 'package:triage/widgets/process_tree.dart';
import 'package:triage/widgets/vitals_display_bar.dart';
import 'package:triage/widgets/vitals_history.dart';
import 'package:triage/widgets/vitals_trend_gaph.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/medication_services.dart';
import 'countdown_timer.dart';

class PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;

  // Made these optional so your Roster doesn't break
  final VoidCallback? onVitalsTap;
  final VoidCallback? onPoliceTap;
  final VoidCallback? onAssessmentsTap;
  final VoidCallback onInterviewTap; // <--- Add this
  final VoidCallback? onMedsTap;
  final VoidCallback? onTimeLineTap;

  const PatientCard({
    super.key,
    required this.patient,
    this.onVitalsTap,
    this.onPoliceTap,
    this.onAssessmentsTap,
    required this.onInterviewTap,
    this.onMedsTap,
    this.onTimeLineTap,
  });

  Color _getDispositionColor() {
    final List<dynamic> flags = patient['flags'] ?? [];
    final String path = patient['path'] ?? '';
    final String status = patient['status'] ?? '';

    if (flags.contains('Form 4 Active')) return Colors.green.shade600;
    if (path == 'GP-Handoff' || status == 'Discharge Prep') {
      return Colors.red.shade600;
    }
    return Colors.yellow.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final String lastName = (patient['first_name'] ?? 'Patient').toString();
    final String firstName = (patient['last_name'] ?? 'Unknown').toString();
    final String phn = (patient['phn'] ?? '000-000-000').toString();
    final String status = (patient['status'] ?? 'Triage').toString();
    final String processPath =  (patient['path'] ?? 'Handoff').toString();
    final List<dynamic> flags = patient['flags'] ?? [];
    final Color statusColor = _getDispositionColor();
    final isTriage = patient['status'] == 'Triage';
    // final DateTime admittedDate = DateTime.parse(patient['admitted']).toLocal(); // uncomment when camera is working
    final admittedDate = AdmittanceUtils.generateRandomAdmittance();
    final int policeReports = patient['police_reports'] ?? 0;
    bool hasReports = policeReports > 0;
    final int medicationCount = patient['medications'] ?? 0;
    final int auditIndex = patient['medication_safety_audit'] ?? 0;
    final String patientUuid = patient['patient_uuid'] ?? "";
    final medicationAudit = MedicationSafetyAudit.values[auditIndex];
    Color? medColor;
    IconData medIcon = Icons.medication;
    if (medicationCount > 0) {
      switch (medicationAudit) {
        case MedicationSafetyAudit.NoInteractionsDetected:
          medColor = Colors.greenAccent;
          break;
        case MedicationSafetyAudit.HasInteractions:
          medColor = Colors.redAccent;
          break;
        case MedicationSafetyAudit.NoAuditPerformed:
          // Keep default theme colors
          break;
      }
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "$lastName, $firstName",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Replace the old monitor_heart button with this:
                CountdownTimer(
                  admittedAt: admittedDate,
                  onTap: onTimeLineTap ?? () {},
                ),
              ],
            ),
            const Divider(height: 8),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(Icons.badge, "PHN: $phn"),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.location_on, status),
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.speed,
                  "Acuity: ${patient['current_acuity']}",
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tappable Vitals
            VitalsBar(
              onAddPressed: onVitalsTap ?? () {},
                onHistoryPressed: () => showVitalsHistory(context, patientUuid),
              vitals: VitalsData(
                pulse: patient['current_pulse'],
                bp: patient['current_bp'],
                temp: patient['current_temp'],
                spo2: patient['current_spo2'],
              ),
            ),

            const SizedBox(height: 16),

            // Assessments/Meds Row
            // Replace the Row with a Wrap for automatic overflow handling
            Wrap(
              spacing: 8, // Horizontal space between buttons
              runSpacing: 8, // Vertical space between lines
              alignment: WrapAlignment.start,
              children: [
                _buildCompactButton(
                  context: context,
                  label: "Assess",
                  icon: Icons.psychology,
                  onTap: onAssessmentsTap ?? (){},

                ),
                _buildCompactButton(
                  context: context,
                  label: "Interview",
                  icon: Icons.mic,
                  onTap: onInterviewTap?? (){},
                ),
                _buildCompactButton(
                  context: context,
                  label: "Meds",
                  icon: medIcon,
                  onTap: onMedsTap?? (){},
                  color: medColor,
                ),
                _buildCompactButton(
                  context: context,
                  label: "Police",
                  icon: Icons.local_police,
                  onTap: onPoliceTap?? (){},
                  color: hasReports ? Colors.greenAccent : null,
                ),
              ],
            ),

            const SizedBox(height: 12),
            Wrap(
              spacing: 6.0,
              children: flags.map((flag) {
                return Chip(
                  label: Text(
                    flag,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: Colors.blueGrey.shade700,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showProcessModal(context, patient['patient_uuid'], status),
              child: ProcessPathway(
                processKey: status,
                currentStatus: processPath,
              ),
            ),
          ],
        ),
      ),
    );
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
                fontWeight: FontWeight.normal
                ,
                letterSpacing: -0.2, // Tighter letters to prevent overflow
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  void _showProcessModal(BuildContext context, String uuid, String key) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Allows for rounded corners
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: AppTheme.clinicWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FutureBuilder(
            // Fetch events for this specific patient
            future: DatabaseManager().getPatientEvents(uuid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  _buildModalHandle(),
                  Expanded(
                    child: ProcessTreeOverlay(
                      patientUuid: uuid,
                      processMap: DatabaseManager().processMaps[key] ?? {},
                      patientEvents: snapshot.data as List<Map<String, dynamic>>,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildModalHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 4,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  void showVitalsHistory(BuildContext context, String patientUuid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.clinicWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => VitalsHistoryView(patientUuid: patientUuid),
    );
  }
}

class AdmittanceUtils {
  /// Generates a random admittance time between 1 and 48 hours ago
  static DateTime generateRandomAdmittance() {
    final randomHours = Random().nextInt(48) + 1;
    return DateTime.now().subtract(Duration(hours: randomHours));
  }

  /// Calculates human-readable string for the toast
  static String getExpiryStatus(DateTime admittedAt) {
    final now = DateTime.now();
    final elapsed = now.difference(admittedAt);
    final remaining = const Duration(hours: 48) - elapsed;

    // Handle case where time might already be expired
    if (remaining.isNegative) return "LEGAL HOLD EXPIRED";

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    return "Admitted: ${admittedAt.hour}:${admittedAt.minute.toString().padLeft(2, '0')}\n"
        "Time Left: ${hours}h ${minutes}m";
  }
}
