import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:uuid/uuid.dart';

import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/professional_gate.dart';
import '../classes/questionnaire_result_import.dart';

// The receiving end of Ally's progressor://questionnaireResult deep link — mirrors
// Ally's own ImportCarePlanScreen/AssignQuestionnaireScreen shape: pick which patient
// this belongs to, confirm, then it's attached to their chart. This is the one place
// in the whole handoff the actual score/interpretation becomes visible to anyone —
// deliberately never to the patient themselves (see Ally's side of this feature).
class ImportQuestionnaireResultScreen extends StatefulWidget {
  final QuestionnaireResultPayload payload;

  const ImportQuestionnaireResultScreen({super.key, required this.payload});

  @override
  State<ImportQuestionnaireResultScreen> createState() => _ImportQuestionnaireResultScreenState();
}

class _ImportQuestionnaireResultScreenState extends State<ImportQuestionnaireResultScreen> {
  List<Patient> _patients = [];
  Patient? _selectedPatient;
  bool _loading = true;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DatabaseManager().getAllPatientsWithVitals();
    final List<Patient> loaded = rows.map((r) => Patient.fromJson(r)).toList();
    if (!mounted) return;
    setState(() {
      _patients = loaded;
      final String incoming = widget.payload.patientName.trim().toLowerCase();
      for (final Patient p in loaded) {
        if ('${p.firstName} ${p.lastName}'.trim().toLowerCase() == incoming) {
          _selectedPatient = p;
          break;
        }
      }
      _loading = false;
    });
  }

  Future<void> _save() async {
    final Patient? patient = _selectedPatient;
    if (patient == null) return;
    if (!await ProfessionalGate.ensureVerified(context)) return;
    if (!mounted) return;
    setState(() => _saving = true);

    await DatabaseManager().insertQuestionnaireResult(
      id: const Uuid().v4(),
      patientUuid: patient.patientUuid,
      templateId: widget.payload.templateId,
      score: widget.payload.score,
      summary: widget.payload.summary,
      action: widget.payload.action,
      answeredAt: widget.payload.answeredAt,
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Questionnaire Results", style: TextStyle(fontSize: 16)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _saved
              ? _buildSuccess()
              : _buildReview(),
    );
  }

  Widget _buildSuccess() {
    final String name = _selectedPatient != null ? '${_selectedPatient!.firstName} ${_selectedPatient!.lastName}' : widget.payload.patientName;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.check_circle, size: 56, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              "Attached to $name's chart",
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.deepLogicViolet.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Text(
            "${widget.payload.templateId} completed by ${widget.payload.patientName}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        Text("Score: ${widget.payload.score}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(widget.payload.summary, style: const TextStyle(fontSize: 14)),
        if ((widget.payload.action ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text("Recommended action: ${widget.payload.action}", style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 16),
        const Text("ATTACH TO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey)),
        const SizedBox(height: 6),
        _patients.isEmpty
            ? const Text("No patients in your caseload yet.", style: TextStyle(fontSize: 13))
            : DropdownButtonFormField<Patient>(
                initialValue: _selectedPatient,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                hint: const Text("Choose a patient"),
                items: _patients
                    .map((p) => DropdownMenuItem(value: p, child: Text('${p.firstName} ${p.lastName}', overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (p) => setState(() => _selectedPatient = p),
              ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: (_selectedPatient == null || _saving) ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Symbols.download, color: Colors.white),
            label: Text(_saving ? "Saving..." : "Attach to Chart", style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepLogicViolet),
          ),
        ),
      ],
    );
  }
}
