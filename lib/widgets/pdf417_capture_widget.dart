import 'package:carbon_ui/carbon_ui.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/pdf417_scanner.dart';

import 'text_scanner.dart' show getFileFromAsset;

// Many North American driver's licenses and ID cards encode the cardholder's
// demographics in a PDF417 barcode on the back (AAMVA standard) — a second capture
// path alongside ScannerWidget's OCR, for the cards where scanning the barcode is
// faster/more reliable than reading printed text. Like ScannerWidget's own
// isSimulationOnly mode, a real live-camera decode loop isn't wired up here (see
// TextScanner._processCameraImage's own unfinished stub for the OCR side of that
// same gap) — this offers a bundled sample barcode for demos and a gallery picker
// for testing against a real photo of one.
class Pdf417CaptureWidget extends StatefulWidget {
  final bool isSimulationOnly;
  final ValueChanged<ParsedIdData> onScanned;

  const Pdf417CaptureWidget({super.key, required this.onScanned, this.isSimulationOnly = false});

  @override
  State<Pdf417CaptureWidget> createState() => _Pdf417CaptureWidgetState();
}

class _Pdf417CaptureWidgetState extends State<Pdf417CaptureWidget> {
  final Pdf417IdScannerService _service = Pdf417IdScannerService();
  bool _scanning = false;
  String? _error;

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _scan(String path) async {
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final data = await _service.scanImageFile(path);
      if (data == null) {
        if (mounted) setState(() => _error = "Couldn't read a barcode from that image.");
        return;
      }
      widget.onScanned(data);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _useSample() async {
    final file = await getFileFromAsset('assets/screen_captures/license_pdf417_sample.png');
    await _scan(file.path);
  }

  Future<void> _pickAndScan() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await _scan(picked.path);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10, width: 2)),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _scanning
            ? const CircularProgressIndicator(color: Colors.white70)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Symbols.barcode_scanner, color: Colors.white24, size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    "SCAN THE BARCODE ON THE BACK OF THE ID",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isSimulationOnly) ...[
                        Expanded(
                          child: CarbonCompactButton(icon: Symbols.qr_code_scanner, label: "Use Sample", style: CarbonButtonStyle.ghost, onTap: _useSample),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: CarbonCompactButton(icon: Symbols.photo_library, label: "Choose from Photos", style: CarbonButtonStyle.ghost, onTap: _pickAndScan),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ],
                ],
              ),
      ),
    );
  }
}
