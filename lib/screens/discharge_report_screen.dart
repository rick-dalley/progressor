import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../classes/care_order.dart';
import '../classes/database_manager.dart';
import '../classes/dispositional.dart';
import '../classes/journey_stage.dart';
import '../classes/patient.dart';

// The provider-reviewed report handed to a patient at discharge — active
// take-home orders, medications, and care-team contacts. Sent via the
// device's own mail client (mailto:), not a backend we control, so CWICare
// never handles the patient's health information in transit. The email also
// carries an `ally://import?data=...` deep link so Ally (once it implements
// the matching handler — separate, follow-up work) can pull the same
// summary in directly, on-device, with no server round-trip.
class DischargeReportScreen extends StatefulWidget {
  final Patient patient;

  const DischargeReportScreen({super.key, required this.patient});

  @override
  State<DischargeReportScreen> createState() => _DischargeReportScreenState();
}

class _DischargeReportScreenState extends State<DischargeReportScreen> {
  List<Therapy> _activeOrders = [];
  List<Map<String, dynamic>> _medications = [];
  DispositionDecision? _latestDecision;
  bool _loading = true;

  final Set<String> _excludedOrderIds = {};
  final Set<String> _excludedMedicationIds = {};
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final orderRows = await DatabaseManager().getCareOrdersForPatient(widget.patient.patientUuid);
    final medRows = await DatabaseManager().getMedicationsForPatient(widget.patient.patientUuid);
    final decisionRows = await DatabaseManager().getDispositionDecisionsForPatient(widget.patient.patientUuid);
    if (!mounted) return;
    setState(() {
      _activeOrders = orderRows.map(Therapy.fromJson).where((o) => o.isActive).toList();
      _medications = medRows;
      _latestDecision = decisionRows.isEmpty ? null : DispositionDecision.fromJson(decisionRows.last);
      _loading = false;
    });
  }

  String _buildReportText() {
    final String name = '${widget.patient.firstName} ${widget.patient.lastName}';
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Care Plan for $name');
    buffer.writeln(DateFormat('MMMM d, y').format(DateTime.now()));
    buffer.writeln();

    if (_latestDecision != null) {
      buffer.writeln('Status: ${journeyStageLabels[_latestDecision!.stageAfter] ?? _latestDecision!.statusAfter}');
      buffer.writeln();
    }

    final included = _activeOrders.where((o) => !_excludedOrderIds.contains(o.id)).toList();
    if (included.isNotEmpty) {
      buffer.writeln('CONTINUING CARE');
      for (final order in included) {
        buffer.writeln('- ${order.label}: ${order.directions}${order.frequency != null ? ' (${order.frequency})' : ''}');
      }
      buffer.writeln();
    }

    final includedMeds = _medications.where((m) => !_excludedMedicationIds.contains(m['id'] as String)).toList();
    if (includedMeds.isNotEmpty) {
      buffer.writeln('MEDICATIONS');
      for (final med in includedMeds) {
        buffer.writeln('- ${med['name']} ${med['dose'] ?? ''} ${med['freq'] ?? ''}'.trim());
      }
      buffer.writeln();
    }

    if (widget.patient.familyDoctorName.isNotEmpty) {
      buffer.writeln('Family doctor: ${widget.patient.familyDoctorName} — ${widget.patient.familyDoctorPhone}');
    }
    if (widget.patient.pharmacyPhone.isNotEmpty) {
      buffer.writeln('Pharmacy: ${widget.patient.pharmacyPhone}');
    }

    if (_notesController.text.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('NOTES FROM YOUR CARE TEAM');
      buffer.writeln(_notesController.text.trim());
    }

    return buffer.toString();
  }

  // A compact JSON summary, base64-encoded into an ally:// deep link — see
  // the class doc comment. Kept intentionally small (no full clinical
  // record) since deep-link URLs have practical length limits.
  String _buildAllyImportLink() {
    final included = _activeOrders.where((o) => !_excludedOrderIds.contains(o.id)).toList();
    final includedMeds = _medications.where((m) => !_excludedMedicationIds.contains(m['id'] as String)).toList();
    final Map<String, dynamic> payload = {
      'v': 1,
      'patientName': '${widget.patient.firstName} ${widget.patient.lastName}',
      'orders': included.map((o) => {'label': o.label, 'directions': o.directions, 'frequency': o.frequency}).toList(),
      'medications': includedMeds.map((m) => {'name': m['name'], 'dose': m['dose'], 'freq': m['freq']}).toList(),
    };
    final String encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));
    return 'ally://import?data=$encoded';
  }

  Future<void> _send() async {
    // Guarded by the button's own disabled state below (email == null/empty), but
    // checked again here too — this is the one place a null would otherwise reach
    // Uri's non-nullable path parameter.
    final String? email = widget.patient.email;
    if (email == null || email.isEmpty) return;
    final String body = '${_buildReportText()}\n\nHave the Ally app? Tap this link to import your care plan:\n${_buildAllyImportLink()}';
    final Uri mailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Your Care Plan', 'body': body},
    );
    if (await canLaunchUrl(mailUri)) {
      await launchUrl(mailUri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No mail app available on this device.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = "${widget.patient.firstName} ${widget.patient.lastName}";
    return Scaffold(
      backgroundColor: AppTheme.clinicalWhite,
      appBar: AppBar(
        title: Text("Discharge Report — $name", style: const TextStyle(fontSize: 15)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        backgroundColor: AppTheme.clinicalWhite,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_latestDecision != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: (journeyStageColors[_latestDecision!.stageAfter] ?? Colors.grey).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Status: ${journeyStageLabels[_latestDecision!.stageAfter] ?? _latestDecision!.statusAfter}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                if (_activeOrders.isNotEmpty) ...[
                  const Text("CONTINUING CARE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey)),
                  ..._activeOrders.map((order) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: !_excludedOrderIds.contains(order.id),
                        onChanged: (val) => setState(() {
                          if (val == true) {
                            _excludedOrderIds.remove(order.id);
                          } else {
                            _excludedOrderIds.add(order.id);
                          }
                        }),
                        title: Text(order.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(order.directions, style: const TextStyle(fontSize: 12)),
                      )),
                  const SizedBox(height: 12),
                ],
                if (_medications.isNotEmpty) ...[
                  const Text("MEDICATIONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey)),
                  ..._medications.map((med) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: !_excludedMedicationIds.contains(med['id'] as String),
                        onChanged: (val) => setState(() {
                          if (val == true) {
                            _excludedMedicationIds.remove(med['id']);
                          } else {
                            _excludedMedicationIds.add(med['id'] as String);
                          }
                        }),
                        title: Text('${med['name']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('${med['dose'] ?? ''} ${med['freq'] ?? ''}'.trim(), style: const TextStyle(fontSize: 12)),
                      )),
                  const SizedBox(height: 12),
                ],
                const Text("CARE TEAM", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey)),
                const SizedBox(height: 6),
                if (widget.patient.familyDoctorName.isNotEmpty)
                  Text('Family doctor: ${widget.patient.familyDoctorName} — ${widget.patient.familyDoctorPhone}', style: const TextStyle(fontSize: 13)),
                if (widget.patient.pharmacyPhone.isNotEmpty)
                  Text('Pharmacy: ${widget.patient.pharmacyPhone}', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(labelText: "Additional notes", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (widget.patient.email?.isEmpty ?? true) ? null : _send,
                    icon: const Icon(Icons.email_outlined, color: Colors.white),
                    label: Text(
                      (widget.patient.email?.isEmpty ?? true) ? "No email on file" : "Review & Send to ${widget.patient.email}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepLogicViolet),
                  ),
                ),
              ],
            ),
    );
  }
}
