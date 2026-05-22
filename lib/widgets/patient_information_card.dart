import 'package:flutter/material.dart';
import '../app_theme.dart';

class PatientInformationCard extends StatelessWidget {
  final Map<String, dynamic> patient;

  const PatientInformationCard({
    super.key,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final String name = '${patient["first_name"]} ${patient["last_name"]}';
    final String admitted = DateTime.now().toIso8601String();
    final String phn = patient["phn"];
    final String? streetAddress = patient["street_address"];
    final String? city = patient["city"];
    final String? province = patient["province"];
    final String? postalCode = patient["postal_code"];
    final String? phone = patient["phone"];
    final String? proxyName = patient["contact_name"];
    final String? proxyPhone = patient["contact_phone"];
    final String? familyDoctorName = patient["family_doctor_name"];
    final String? familyDoctorPhone = patient["family_doctor_phone"];
    final String? pharmacyFax = patient["pharmacy_fax"];
    final String? pharmacyPhone = patient["pharmacy_phone"];

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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.clinicalCyan.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 13, color: AppTheme.clinicalCyan),
                      const SizedBox(width: 4),
                      Text(
                        admitted,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.clinicalCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Line 2: PHN (Personal Health Number)
            _buildLabeledRow("PHN", _formatPHN(phn.toString())),
            const SizedBox(height: 8),

            // Line 3 & 4: Address Blocks
            _buildLabeledRow("ADDRESS", streetAddress!),
            Padding(
              padding: const EdgeInsets.only(left: 85.0, top: 2), // Aligns nicely underneath the label column gap
              child: Text(
                "$city, $province  $postalCode",
                style: const TextStyle(fontSize: 13, color: AppTheme.deepCharcoal),
              ),
            ),

            // Gap 1
            const SizedBox(height: 14),

            // Line 5: Phone Number
            _buildLabeledRow("PHONE", phone!),

            // Gap 2
            const SizedBox(height: 14),

            // Line 6: Contact Name and Number (Next of Kin / Proxy)
            _buildLabeledRow("CONTACT", "$proxyName • $proxyPhone"),
            const SizedBox(height: 8),

            // Line 7: Family Doctor details
            _buildLabeledRow("DOCTOR", "$familyDoctorName • $familyDoctorPhone"),
            const SizedBox(height: 8),

            // Line 8: Pharmacy details
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
}