import 'package:flutter/material.dart';
import 'package:triage/classes/admittance_utils.dart';
import '../app_theme.dart';
import '../classes/medication_services.dart';

class PatientInformationCard extends StatelessWidget {
  final Map<String, dynamic> patient;
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
  Widget build(BuildContext context) {
    final String name = '${patient["first_name"]} ${patient["last_name"]}';
    final String phn = patient["phn"];
    final String? phone = patient["phone"];
    final String? proxyName = patient["contact_name"];
    final String? proxyPhone = patient["contact_phone"];
    final String? familyDoctorName = patient["family_doctor_name"];
    final String? familyDoctorPhone = patient["family_doctor_phone"];
    final String? pharmacyFax = patient["pharmacy_fax"];
    final String? pharmacyPhone = patient["pharmacy_phone"];
    final int policeReports = patient['police_reports'] ?? 0;
    final int medicationCount = patient['medications'] ?? 0;
    final int auditIndex = patient['medication_safety_audit'] ?? 0;
    final medicationAudit = MedicationSafetyAudit.values[auditIndex];
    final String? rawAdmissionDate = patient["admitted"];
    final DateTime? admitted = rawAdmissionDate == null ? AdmittanceUtils.generateRandomAdmittance() : AdmittanceUtils.parseDatabaseDate(rawAdmissionDate);
    final String formattedAdmission = AdmittanceUtils.formatAdmission(admitted);
    bool hasReports = policeReports > 0;
    Color? medColor;
    IconData medIcon = Icons.medication;
    if (medicationCount > 0) {
      switch (medicationAudit) {
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
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepCharcoal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("PHN:"), Text(_formatPHN(phn.toString())),
                Spacer(),
                Text("Admitted:"),Text(formattedAdmission)
              ],
            ),
            SizedBox(height:16),
            Wrap(
              spacing: 8, // Horizontal space between buttons
              runSpacing: 8, // Vertical space between lines
              alignment: WrapAlignment.start,
              children: [
                _buildCompactButton(
                  context: context,
                  label: "Assess",
                  icon: Icons.psychology,
                  onTap: onAssessmentsTap ?? () {},
                ),
                _buildCompactButton(context: context, label: "Interview", icon: Icons.mic, onTap: onInterviewTap),
                _buildCompactButton(
                  context: context,
                  label: "Meds",
                  icon: medIcon,
                  onTap: onMedsTap ?? () {},
                  color: medColor,
                ),
                _buildCompactButton(
                  context: context,
                  label: "Police",
                  icon: Icons.local_police,
                  onTap: onPoliceTap ?? () {},
                  color: hasReports ? Colors.greenAccent : null,
                ),
              ],
            ),
            SizedBox(height:16),
            _buildLabeledRow("PHONE", phone!),
            // Gap
            const SizedBox(height: 8),
            // Contact Name and Number (Next of Kin / Proxy)
            _buildLabeledRow("CONTACT", "$proxyName • $proxyPhone"),
            const SizedBox(height: 8),
            // Family Doctor details
            _buildLabeledRow("DOCTOR", "$familyDoctorName • $familyDoctorPhone"),
            const SizedBox(height: 8),
            // Pharmacy details
            _buildLabeledRow("PHARMACY", "$pharmacyFax • $pharmacyPhone"),
          ],
        ),
      ),
    );
  }

  // Helper row helper to maintain perfect horizontal tabular alignment across fields
  Widget _buildLabeledRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 85, // Fixed label width handles precise vertical grid alignment
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.deepCharcoal,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
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