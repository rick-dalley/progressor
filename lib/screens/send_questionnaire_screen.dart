import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../classes/patient.dart';
import '../classes/questionnaire_catalog.dart';

// The push-button half of Ally's assigned-questionnaire model — no paperwork, no
// scoring shown to the patient unsupervised: pick an instrument, it lands as a
// gated, single-use request on the patient's Ally profile (see Ally's
// AssignQuestionnaireScreen), and the completed results email straight back here.
// Same no-shared-backend shape as DischargeReportScreen: a mailto whose body carries
// an ally://assignQuestionnaire?data=... deep link.
class SendQuestionnaireScreen extends StatefulWidget {
  final Patient patient;

  const SendQuestionnaireScreen({super.key, required this.patient});

  @override
  State<SendQuestionnaireScreen> createState() => _SendQuestionnaireScreenState();
}

class _SendQuestionnaireScreenState extends State<SendQuestionnaireScreen> {
  QuestionnaireCatalogEntry _selected = questionnaireCatalog.first;
  final TextEditingController _providerNameController = TextEditingController();
  final TextEditingController _providerEmailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _providerNameController.dispose();
    _providerEmailController.dispose();
    super.dispose();
  }

  String _buildAllyAssignLink() {
    final Map<String, dynamic> payload = {
      'v': 1,
      'patientName': '${widget.patient.firstName} ${widget.patient.lastName}',
      'templateId': _selected.id,
      'providerName': _providerNameController.text.trim(),
      'providerEmail': _providerEmailController.text.trim(),
    };
    final String encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));
    return 'ally://assignQuestionnaire?data=$encoded';
  }

  bool get _canSend => _providerNameController.text.trim().isNotEmpty && _providerEmailController.text.trim().isNotEmpty;

  Future<void> _send() async {
    final String body =
        'Hi ${widget.patient.firstName},\n\n'
        '${_providerNameController.text.trim()} would like you to complete a short ${_selected.name} '
        '(${_selected.description.toLowerCase()}) questionnaire.\n\n'
        'Have the Ally app? Tap this link to open it:\n${_buildAllyAssignLink()}';
    final Uri mailUri = Uri(
      scheme: 'mailto',
      path: widget.patient.email,
      queryParameters: {'subject': 'A quick questionnaire from ${_providerNameController.text.trim()}', 'body': body},
    );
    if (await canLaunchUrl(mailUri)) {
      await launchUrl(mailUri);
      if (mounted) setState(() => _sent = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No mail app available on this device.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Send Questionnaire")),
      body: SafeArea(
        child: _sent ? _buildSent() : _buildForm(),
      ),
    );
  }

  Widget _buildSent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.check_circle, size: 56, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              "${_selected.name} sent to ${widget.patient.firstName}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "They'll see it on their Ally profile — you'll get the results back the same way once they finish.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
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

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Sending to ${widget.patient.firstName} ${widget.patient.lastName}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 16),
        const Text("QUESTIONNAIRE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey)),
        const SizedBox(height: 6),
        DropdownButtonFormField<QuestionnaireCatalogEntry>(
          initialValue: _selected,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          items: questionnaireCatalog
              .map((e) => DropdownMenuItem(value: e, child: Text('${e.name} — ${e.description}')))
              .toList(),
          onChanged: (val) => setState(() => _selected = val ?? _selected),
        ),
        const SizedBox(height: 16),
        const Text("FROM", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey)),
        const SizedBox(height: 6),
        TextField(
          controller: _providerNameController,
          decoration: const InputDecoration(labelText: "Your name", border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _providerEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: "Your email (results come back here)", border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _canSend ? _send : null,
            icon: const Icon(Symbols.send, color: Colors.white),
            label: const Text("Send", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepLogicViolet),
          ),
        ),
      ],
    );
  }
}
