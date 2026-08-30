import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../app_theme.dart';
import '../classes/acuity.dart';
import '../classes/database_manager.dart';
import '../classes/ems_handoff.dart';
import '../classes/ems_handoff_import.dart';
import '../classes/professional_gate.dart';

// The receiving end of Acuitage's EMS handoff deep link — a paramedic's on-scene
// summary, previewed here before anything writes to the database. Unlike the
// Progressor -> Ally import (which attaches to an existing profile), this always
// creates a brand-new patient: arriving at the hospital via EMS handoff is, today,
// Progressor's only real "new patient" entry point (IntakeScreen's scan flow isn't
// wired to persistence yet).
class ImportEmsHandoffScreen extends StatefulWidget {
  final EmsHandoffImportPayload payload;

  const ImportEmsHandoffScreen({super.key, required this.payload});

  @override
  State<ImportEmsHandoffScreen> createState() => _ImportEmsHandoffScreenState();
}

class _ImportEmsHandoffScreenState extends State<ImportEmsHandoffScreen> {
  bool _importing = false;
  bool _imported = false;

  AcuityLevel get _acuity {
    try {
      return AcuityLevel.values.byName(widget.payload.acuityLevel ?? '');
    } catch (_) {
      return AcuityLevel.notUrgent;
    }
  }

  EmsAssessmentType? get _assessmentType {
    if (widget.payload.assessmentType == null) return null;
    try {
      return EmsAssessmentType.values.byName(widget.payload.assessmentType!);
    } catch (_) {
      return null;
    }
  }

  Future<void> _import() async {
    if (_importing) return;
    if (!await ProfessionalGate.ensureVerified(context)) return;
    if (!mounted) return;
    setState(() => _importing = true);

    final db = DatabaseManager();
    final String patientUuid = await db.createPatientFromEmsHandoff(
      firstName: widget.payload.firstName,
      lastName: widget.payload.lastName,
      phn: widget.payload.phn,
      dob: widget.payload.dob,
      acuityIndex: _acuity.index,
      contactName: widget.payload.contactName,
      contactPhone: widget.payload.contactPhone,
      familyDoctorName: widget.payload.familyDoctorName,
      familyDoctorPhone: widget.payload.familyDoctorPhone,
    );

    await db.insertEmsHandoff(
      patientUuid: patientUuid,
      incidentName: widget.payload.incidentName,
      dispatchCode: widget.payload.dispatchCode,
      crew: widget.payload.crew.isEmpty ? null : widget.payload.crew.join(', '),
      onSceneAcuity: _acuity.index,
      assessmentTypeIndex: (_assessmentType ?? EmsAssessmentType.esi).index,
      destinationFacility: widget.payload.destinationFacility,
      narrative: widget.payload.narrative,
      deliveredAt: widget.payload.deliveredAt,
    );

    final Map<String, double> v = widget.payload.vitals;
    if (v.containsKey('systolic') && v.containsKey('diastolic') && v.containsKey('pulse') && v.containsKey('spo2') && v.containsKey('temp')) {
      await db.insertVitalsBatch(
        patientUuid: patientUuid,
        systolic: v['systolic']!.round(),
        diastolic: v['diastolic']!.round(),
        pulse: v['pulse']!.round(),
        spo2: v['spo2']!,
        temperature: v['temp']!,
      );
    }

    if (!mounted) return;
    setState(() {
      _importing = false;
      _imported = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.clinicalWhite,
      appBar: AppBar(
        title: const Text("EMS Handoff", style: TextStyle(fontSize: 16)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        backgroundColor: AppTheme.clinicalWhite,
        elevation: 0,
      ),
      body: _imported ? _buildSuccess() : _buildReview(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.check_circle, size: 56, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              "${widget.payload.firstName} ${widget.payload.lastName} admitted",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepLogicViolet),
              child: const Text("Done", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    final EmsAssessmentType? assessmentType = _assessmentType;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.deepLogicViolet.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Text(
            '${widget.payload.firstName} ${widget.payload.lastName} — incoming EMS handoff',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.payload.dob != null) _row("DOB", DateFormat('MMM d, y').format(widget.payload.dob!)),
        if (widget.payload.phn != null) _row("PHN", widget.payload.phn!),
        _row("On-scene acuity", AcuityFactory.instance.getAcuity(level: _acuity)?.statusName ?? _acuity.name),
        if (assessmentType != null) _row("Presenting category", emsAssessmentTypeLabels[assessmentType] ?? assessmentType.name),
        if (widget.payload.topDiagnosis != null) _row("Working impression", widget.payload.topDiagnosis!),
        if (widget.payload.destinationFacility != null) _row("Destination", widget.payload.destinationFacility!),
        if (widget.payload.incidentName != null) _row("Incident", widget.payload.incidentName!),
        if (widget.payload.dispatchCode != null) _row("Dispatch code", widget.payload.dispatchCode!),
        if (widget.payload.crew.isNotEmpty) _row("Crew", widget.payload.crew.join(', ')),
        if (widget.payload.vitals.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text("VITALS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            widget.payload.vitals.entries.map((e) => '${e.key.toUpperCase()}: ${e.value.toStringAsFixed(0)}').join('   '),
            style: const TextStyle(fontSize: 13),
          ),
        ],
        if (widget.payload.narrative != null && widget.payload.narrative!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text("NARRATIVE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(widget.payload.narrative!, style: const TextStyle(fontSize: 13)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _import(),
            icon: _importing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Symbols.person_add, color: Colors.white),
            label: Text(_importing ? "Admitting..." : "Create Patient & Admit", style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepLogicViolet),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
