import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../app_theme.dart';
import '../classes/acuity.dart';
import '../classes/ems_handoff.dart';

// Read-only view of the EMS crew's handoff — see ems_handoff.dart for why this
// is seeded data standing in for a real Acuitage sync pipe.
class EmsHandoffReportScreen extends StatelessWidget {
  final EmsHandoff handoff;
  final String patientName;

  const EmsHandoffReportScreen({super.key, required this.handoff, required this.patientName});

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Acuity? acuity = AcuityFactory.instance.getAcuity(level: handoff.onSceneAcuity);
    return Scaffold(
      backgroundColor: AppTheme.clinicalWhite,
      appBar: AppBar(
        title: Text("EMS Handoff — $patientName", style: const TextStyle(fontSize: 16)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        backgroundColor: AppTheme.clinicalWhite,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (emsAssessmentTypeColors[handoff.assessmentType] ?? Colors.grey).withAlpha(40),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: emsAssessmentTypeColors[handoff.assessmentType] ?? Colors.grey),
            ),
            child: Row(
              children: [
                Icon(
                  emsAssessmentTypeIcons[handoff.assessmentType] ?? Icons.circle_rounded,
                  color: emsAssessmentTypeColors[handoff.assessmentType],
                ),
                const SizedBox(width: 12),
                Text(
                  emsAssessmentTypeLabels[handoff.assessmentType] ?? handoff.assessmentType.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                AppTheme.acuityIcons[handoff.onSceneAcuity] ?? Icons.circle_rounded,
                size: 18,
                color: AppTheme.acuityColors[handoff.onSceneAcuity],
              ),
              const SizedBox(width: 8),
              Text("On-scene acuity: ${acuity?.statusName ?? handoff.onSceneAcuity.name}"),
            ],
          ),
          const SizedBox(height: 20),
          _row("Incident", handoff.incidentName),
          _row("Dispatch code", handoff.dispatchCode),
          _row("Crew", handoff.crew),
          _row("Destination facility", handoff.destinationFacility),
          _row("Delivered", DateFormat('MMM d, y • h:mm a').format(handoff.deliveredAt)),
          _row("Narrative", handoff.narrative),
        ],
      ),
    );
  }
}
