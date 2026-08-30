import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/carbon_ui.dart';
import '../classes/database_manager.dart';
import '../classes/journey_stage.dart';
import '../classes/medication_services.dart';
import '../classes/patient.dart';

// The "more info" content revealed by expanding a patient's card — reference
// data (contacts, care team) and less-frequent actions, not the moment-to-
// moment clinical status already on the front of the card. Height/weight/BMI
// used to live here as a one-off widget; both are now just entries in the
// clinician's own tracked-metrics catalog (see tracked_metric.dart) instead
// of a separate, redundant mechanism.
class PatientInformationCard extends StatefulWidget {
  final Patient patient;
  final VoidCallback? onAssessmentsTap;
  final VoidCallback onInterviewTap; // <--- Add this
  final VoidCallback? onMedsTap;
  final VoidCallback? onOrdersTap;
  final VoidCallback? onDischargeReportTap;
  final VoidCallback? onSendQuestionnaireTap;
  final VoidCallback? onArchiveTap;

  const PatientInformationCard({
    super.key,
    required this.patient,
    this.onAssessmentsTap,
    required this.onInterviewTap,
    this.onMedsTap,
    this.onOrdersTap,
    this.onDischargeReportTap,
    this.onSendQuestionnaireTap,
    this.onArchiveTap,
  });

  @override
  State<StatefulWidget> createState() => PatientInformationCardState();
}

class PatientInformationCardState extends State<PatientInformationCard> {
  late Patient patient;

  @override
  void initState() {
    super.initState();
    patient = widget.patient;
  }

  @override
  Widget build(BuildContext context) {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Born: ${patient.formattedDateOfBirth} (${patient.age} yrs)"),
          const SizedBox(height: 4),
          Text("Provincial Health #: ${_formatPHN(patient.phn.toString())}"),
          const SizedBox(height: 16),
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
                label: "Orders",
                icon: Symbols.assignment,
                onTap: widget.onOrdersTap ?? () {},
              ),
              _buildCompactButton(
                context: context,
                label: "Send Questionnaire",
                icon: Symbols.checklist,
                onTap: widget.onSendQuestionnaireTap ?? () {},
              ),
              // Shows once the journey has actually reached a terminal
              // outcome — before that there isn't a discharge to report yet.
              if (terminalJourneyStages.contains(patient.journeyStage))
                _buildCompactButton(
                  context: context,
                  label: "Discharge Report",
                  icon: Symbols.summarize,
                  onTap: widget.onDischargeReportTap ?? () {},
                ),
              // Fallback archive affordance — the primary path is the archive
              // checkbox on DispositionDecisionSheet at the moment a terminal
              // outcome is recorded; this covers a physician who skipped that.
              if (terminalJourneyStages.contains(patient.journeyStage) && !patient.isArchived)
                _buildCompactButton(
                  context: context,
                  label: "Archive",
                  icon: Symbols.archive,
                  onTap: widget.onArchiveTap ?? () {},
                  color: Colors.redAccent,
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildEditableField(
            label: "Contact Name",
            value: patient.contactName,
            column: 'contact_name',
            onSaved: (v) => patient.contactName = v,
          ),
          _buildEditableField(
            label: "Contact Phone",
            value: patient.contactPhone,
            column: 'contact_phone',
            onSaved: (v) => patient.contactPhone = v,
          ),
          _buildEditableField(
            label: "Family Doctor",
            value: patient.familyDoctorName,
            column: 'family_doctor_name',
            onSaved: (v) => patient.familyDoctorName = v,
          ),
          _buildEditableField(
            label: "Doctor Phone",
            value: patient.familyDoctorPhone,
            column: 'family_doctor_phone',
            onSaved: (v) => patient.familyDoctorPhone = v,
          ),
          _buildEditableField(
            label: "Pharmacy Phone",
            value: patient.pharmacyPhone,
            column: 'pharmacy_phone',
            onSaved: (v) => patient.pharmacyPhone = v,
          ),
          _buildEditableField(
            label: "Pharmacy Fax",
            value: patient.pharmacyFax,
            column: 'pharmacy_fax',
            onSaved: (v) => patient.pharmacyFax = v,
          ),
        ],
      ),
    );
  }

  Future<void> _saveField(String column, String value, void Function(String) apply) async {
    setState(() => apply(value));
    await DatabaseManager().updatePatientField(patientUuid: patient.patientUuid, column: column, value: value);
  }

  // One CarbonQuickEntryField per row, full width — check to save, X to
  // clear, pre-filled with the existing value (see the initialValue
  // addition to CarbonQuickEntryField in carbon_ui). Two-up side-by-side
  // elided the text too much to be usable; a longer sheet reads better.
  Widget _buildEditableField({
    required String label,
    required String value,
    required String column,
    required void Function(String) onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: CarbonQuickEntryField(
        label: label,
        initialValue: value,
        onSave: (v) => _saveField(column, v, onSaved),
      ),
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
      width: availableWidth / 3,
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
