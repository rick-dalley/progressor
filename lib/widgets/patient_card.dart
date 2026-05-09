import 'dart:math';
import 'package:flutter/material.dart';
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
    final List<dynamic> flags = patient['flags'] ?? [];
    final Color statusColor = _getDispositionColor();
    final isTriage = patient['status'] == 'Triage';
    // final DateTime admittedDate = DateTime.parse(patient['admitted']).toLocal(); // uncomment when camera is working
    final admittedDate = AdmittanceUtils.generateRandomAdmittance();
    final int policeReports = patient['police_reports'] ?? 0;
    bool hasReports = policeReports > 0;
    final int medicationCount = patient['medications'] ?? 0;
    final int auditIndex = patient['medication_safety_audit'] ?? 0;
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
            InkWell(
              onTap: onVitalsTap ?? () {},
              borderRadius: BorderRadius.circular(8),
              child: _buildVitalsBar(),
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
            _buildProcessTimeline(isTriage),
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

  Widget _buildVitalsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _vitalItem(Icons.favorite, "88", "bpm"),
          _vitalItem(Icons.speed, "120/80", "bp"),
          _vitalItem(Icons.thermostat, "36.8", "°C"),
          _vitalItem(Icons.air, "98", "%"),
        ],
      ),
    );
  }

  Widget _vitalItem(IconData icon, String value, String unit) {
    return Column(
      children: [
        Icon(icon, size: 14, color: Colors.blueGrey.shade300),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(unit, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildProcessTimeline(bool isTriage) {
    final List<String> stages = isTriage
        ? ["Handoff", "Search", "Certify", "Admit"]
        : ["Stabilize", "Review", "Handoff", "Home"];
    int currentStep = isTriage ? 1 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PROCESS PATHWAY",
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(stages.length, (index) {
            bool isCompleted = index < currentStep;
            bool isCurrent = index == currentStep;
            return Expanded(
              child: Row(
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_circle
                        : (isCurrent
                              ? Icons.play_circle
                              : Icons.circle_outlined),
                    size: 16,
                    color: isCompleted
                        ? Colors.green
                        : (isCurrent ? Colors.yellow : Colors.grey),
                  ),
                  if (index < stages.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted
                            ? Colors.green
                            : Colors.grey.shade800,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
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
