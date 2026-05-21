import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../app_theme.dart';
import '../widgets/text_scanner.dart';

class PoliceReportScreen extends StatefulWidget {
  const PoliceReportScreen({super.key});

  @override
  State<PoliceReportScreen> createState() => _PoliceReportScreenState();
}

class _PoliceReportScreenState extends State<PoliceReportScreen> {

  final _badgeController = TextEditingController();
  final _fileNumberController = TextEditingController();
  final _narrativeController = TextEditingController();
  String _selectedAgency = 'RCMP';

  bool _isScanning = false;
  bool _documentAttached = false;


  void _onTextDetected(RecognizedText recognizedText) {
    final String fullText = recognizedText.text;
    final List<String> lines = fullText.split('\n');

    setState(() {
      _selectedAgency = 'Other';
      for (int i = 0; i < lines.length; i++) {
        String currentLine = lines[i].trim();

        // Found by looking for the "first and last name of applicant" descriptor
        if (currentLine.contains("name of applicant")) {
          if (i > 0) _badgeController.text = lines[i - 1].trim(); // Officer name
        }

        // 1. Get the entire text in lowercase to make it case-insensitive
        final String lowerFullText = fullText.toLowerCase();

        if (lowerFullText.contains("rcmp")) {
          _selectedAgency = 'RCMP';
        } else if (lowerFullText.contains("vpd") || lowerFullText.contains("vancouver police")) {
          _selectedAgency = 'VPD';
        } else if (lowerFullText.contains("transit police")) {
          _selectedAgency = 'Transit Police';
        }

        if (_selectedAgency == 'Other' && lowerFullText.contains("burnaby")) {
          _selectedAgency = 'RCMP';
        }
      }

      // 4. Extract Narrative (The "Grounds")
      // This looks for the block between the header and the "If additional space" footer
      const startMarker = "THE GROUNDS FOR MY BELIEF ARE:";
      const endMarker = "If additional space is required";

      if (fullText.contains(startMarker)) {
        String narrative = fullText.split(startMarker).last;
        if (narrative.contains(endMarker)) {
          narrative = narrative.split(endMarker).first;
        }
        _narrativeController.text = narrative.trim();
      }

      _isScanning = false;
      _documentAttached = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("POLICE HANDOFF / SEC. 28"),
        actions: [
          if (_documentAttached)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.verified_user, color: Colors.greenAccent),
            )
        ],
      ),
      body: Column(
        children: [
          // Dynamic Header: Scanner or Document Status
          _buildScannerHero(),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                const SizedBox(height: 16),
                _buildAgencySection(),
                _buildNarrativeSection(),
                const SizedBox(height: 8),

                // 🟢 FIXED: Changed abstract EdgeInsetsGeometry to concrete const EdgeInsets
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildSaveButton(),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview(String assetName) {
    return Stack(
      children: [
        // The actual image (from assets for the mock, or file for live)
        Center(
          child: Opacity(
            opacity: 0.8,
            child: Image.asset(assetName, fit: BoxFit.contain),
          ),
        ),
        // Overlay buttons for rescan or zoom
        Positioned(
          bottom: 10,
          right: 10,
          width: 120, // 🟢 FIXED: Forcing a finite layout width directly on the Positioned container bounds!
          height: 40, // Keeps the vertical height locked cleanly
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _isScanning = true),
            icon: const Icon(Icons.reorder, size: 16),
            label: const Text("RE-SCAN"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.zero, // 💡 Clears internal button padding so text wraps/fits cleanly inside 120px
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanPrompt() {
    return InkWell(
      onTap: () => setState(() => _isScanning = true),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.document_scanner,
            color: AppTheme.clinicalCyan,
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            "TAP TO SCAN FORM 9 / 10",
            style: TextStyle(
              color: AppTheme.clinicalCyan,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Align document in frame for auto-fill",
            style: TextStyle(
              color: AppTheme.clinicalCyan.withAlpha(144),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerHero() {
    final form9Report = "assets/screen_captures/CompletedForm9.png";

    // Calculate 40% of screen height
    final screenHeight = MediaQuery.of(context).size.height;
    final double lockedHeight = screenHeight * 0.4;

    return Container(
      height: lockedHeight,
      width: double.infinity,
      color: Colors.black, // Dark background for contrast
      child: _isScanning
          ? SizedBox(
        width: MediaQuery.of(context).size.width, // 🟢 Forces a definitive, finite width constraint
        height: lockedHeight, // Matches the parent hero box bounds
        child: TextScanner(
          onTextDetected: _onTextDetected,
          mockImagePath: form9Report,
        ),
      )
          : _documentAttached
          ? _buildDocumentPreview(form9Report)
          : _buildScanPrompt(),
    );
  }

  Widget _buildAgencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wrap the Dropdown inside a clean layout constraint block
        SizedBox(
          width: double.infinity, // Forces a fixed boundary relative to the ListView width
          child: DropdownButtonFormField<String>(
            initialValue: _selectedAgency, // 🟢 Fixed property name from initialValue to value
            items: ['RCMP', 'VPD', 'Transit Police', 'Other'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (val) => setState(() => _selectedAgency = val!),
            decoration: const InputDecoration(labelText: "Agency"),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _badgeController,
                decoration: const InputDecoration(labelText: "Name or Badge Number"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _fileNumberController,
                decoration: const InputDecoration(labelText: "File/GO Number"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrativeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("NARRATIVE SUMMARY",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white54)),
        const SizedBox(height: 16),
        TextField(
          controller: _narrativeController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: "Enter summary or auto-fill from scan...",
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    // 🟢 FIXED: Wrapped in SizedBox to stop the button layout expansion from inflating to Infinity inside the ListView
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _savePoliceReport,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _savePoliceReport() {
    int reportCount = 1; // later count the number of reports and add them to a list.
    Navigator.pop(context, reportCount);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Handoff record synchronized with Triage Timeline.")),
    );
  }
}