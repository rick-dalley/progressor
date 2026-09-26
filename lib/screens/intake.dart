import 'package:carbon_ui/carbon_ui.dart';
import 'package:flutter/material.dart';
import 'package:cwicare_vision/cwicare_vision.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/pdf417_scanner.dart';
import 'package:triage/classes/scanned_data.dart';
import 'package:triage/widgets/pdf417_capture_widget.dart';
import 'package:triage/widgets/scanner_widget.dart';

enum _CaptureMethod { photoId, barcode }

class IntakeScreen extends StatefulWidget {
  final bool? isSimulation;
  final Function(ScannedData data)? onScannedData;
  const IntakeScreen({super.key, this.isSimulation, this.onScannedData});

  @override
  IntakeScreenState createState() => IntakeScreenState();
}

class IntakeScreenState extends State<IntakeScreen> {
  _CaptureMethod _method = _CaptureMethod.photoId;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phnController = TextEditingController();
  final _dobController = TextEditingController();

  bool get _isSimulation => widget.isSimulation ?? true;

  bool get _canSave => _firstNameController.text.trim().isNotEmpty && _lastNameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    for (final c in [_firstNameController, _lastNameController, _phnController, _dobController]) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in [_firstNameController, _lastNameController, _phnController, _dobController]) {
      c.removeListener(_onFieldChanged);
    }
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phnController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void onTextDetected(RecognizedText recognizedText) {
    final String fullText = recognizedText.text;
    final List<String> lines = fullText.split('\n').map((e) => e.trim()).toList();

    // 1. PHN (Regex is robust, keep it)
    final phnRegex = RegExp(r'\d{4} \d{3} \d{3}');
    final match = phnRegex.firstMatch(fullText);
    if (match != null) _phnController.text = match.group(0)!;

    // 2. SWEEP FOR DOB & NAME
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].toUpperCase();

      // Handle DOB (Checking for "OB:" to catch "DOB" or "ĐOB")
      if (line.contains("OB:")) {
        _dobController.text = lines[i].split(':').last.trim();
      }

      // Handle Name: Look for a surname line, marked with a trailing comma
      if (line.contains(',')) {
        _lastNameController.text = lines[i].replaceAll(',', '').trim().toUpperCase();

        // The very next line is likely the First Name
        if (i + 1 < lines.length) {
          _firstNameController.text = lines[i + 1].trim().toUpperCase();
        }
      }
    }
  }

  void _onBarcodeScanned(ParsedIdData data) {
    if (data.firstName.isNotEmpty) _firstNameController.text = data.firstName;
    if (data.lastName.isNotEmpty) _lastNameController.text = data.lastName;
    if (data.dateOfBirth != null) _dobController.text = _isoDate(data.dateOfBirth!);
  }

  void _save() {
    if (!_canSave) return;
    final data = ScannedData()
      ..firstName = _firstNameController.text.trim()
      ..lastName = _lastNameController.text.trim()
      ..dob = _dobController.text.trim()
      ..phn = _phnController.text.trim();
    Navigator.pop(context);
    widget.onScannedData?.call(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Intake")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Capture Method", style: CarbonTheme.carbonHintTextStyle),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CarbonCompactButton(
                      icon: Symbols.badge,
                      label: "Photo ID",
                      style: _method == _CaptureMethod.photoId ? CarbonButtonStyle.primary : CarbonButtonStyle.secondary,
                      onTap: () => setState(() => _method = _CaptureMethod.photoId),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CarbonCompactButton(
                      icon: Symbols.barcode_scanner,
                      label: "Barcode",
                      style: _method == _CaptureMethod.barcode ? CarbonButtonStyle.primary : CarbonButtonStyle.secondary,
                      onTap: () => setState(() => _method = _CaptureMethod.barcode),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_method == _CaptureMethod.photoId)
                ScannerWidget(scanFront: true, scanBack: true, isSimulationOnly: _isSimulation, onTextDetected: onTextDetected)
              else
                Pdf417CaptureWidget(isSimulationOnly: _isSimulation, onScanned: _onBarcodeScanned),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CarbonTextInput(label: "First Name", controller: _firstNameController),
                      const SizedBox(height: 16),
                      CarbonTextInput(label: "Last Name", controller: _lastNameController),
                      const SizedBox(height: 16),
                      CarbonTextInput(label: "Date of Birth", controller: _dobController, helperText: "YYYY-MM-DD"),
                      const SizedBox(height: 16),
                      CarbonTextInput(label: "PHN", controller: _phnController),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CarbonCompactButton(
                      icon: Symbols.close,
                      label: "Cancel",
                      style: CarbonButtonStyle.ghost,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CarbonCompactButton(
                      icon: Symbols.save,
                      label: "Save",
                      style: CarbonButtonStyle.primary,
                      onTap: _canSave ? _save : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
