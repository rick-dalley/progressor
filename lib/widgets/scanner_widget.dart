import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:triage/widgets/text_scanner.dart';

class ScannerWidget extends StatefulWidget {
  final bool scanFront; // Is the camera/scanner active right now?
  final bool? scanBack;
  final bool? isSimulationOnly;
  final Function(RecognizedText text)? onTextDetected;

  const ScannerWidget({super.key, required this.scanFront, this.scanBack, this.isSimulationOnly, this.onTextDetected});

  @override
  State<StatefulWidget> createState() => ScannerWidgetState();
}

class ScannerWidgetState extends State<ScannerWidget> {
  bool isScanningFront = false;
  bool isScanningBack = false;
  bool frontAttached = false; // New: track front completion
  bool backAttached = false; // New: track back completion

  @override
  Widget build(BuildContext context) {
    bool scanBack = widget.scanBack ?? false;
    bool scanFront = widget.scanFront;
    bool isSimulation = widget.isSimulationOnly ?? false;
    String frontScannerPath = '';
    String backScannerPath = '';
    if (isSimulation) {
      scanBack = true;
      scanFront = true;
      frontScannerPath = 'assets/screen_captures/license_front.png';
      backScannerPath = 'assets/screen_captures/license_back.png';
    }
    return Container(
      height: MediaQuery.of(context).size.height * 0.45, // Slightly taller for vertical stack
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // FRONT SLOT (Top)
          if (scanFront)
            Expanded(
              child: ScannerCardSlot(
                label: "FRONT OF ID",
                isScanning: isScanningFront,
                isAttached: frontAttached,
                imagePath: frontScannerPath,
                onTap: () => setState(() {
                  isScanningFront = true;
                  isScanningBack = false;
                }),
                onTextDetected: (RecognizedText text) {
                  setState(() {
                    isScanningFront = false; // Stop the scanner
                    frontAttached = true; // Mark as done
                  });
                  if (widget.onTextDetected != null) {
                    widget.onTextDetected!(text);
                  }
                },
              ),
            ),
          const SizedBox(height: 12),
          // BACK SLOT (Bottom)
          if (scanBack)
            Expanded(
              child: ScannerCardSlot(
                label: "BACK OF ID",
                isScanning: isScanningBack,
                isAttached: backAttached,
                imagePath: backScannerPath,
                onTap: () => setState(() {
                  isScanningBack = true;
                  isScanningFront = false;
                }),
                onTextDetected: (RecognizedText text) {
                  setState(() {
                    isScanningBack = false; // Stop the scanner
                    backAttached = true; // Mark as done
                  });
                  if (widget.onTextDetected != null) {
                    widget.onTextDetected!(text);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class ScannerCardSlot extends StatefulWidget {
  final String label;
  final bool isScanning;
  final bool isAttached;
  final VoidCallback onTap;
  final String? imagePath;
  final Function(RecognizedText text)? onTextDetected;

  const ScannerCardSlot({
    super.key,
    required this.label,
    required this.isScanning,
    required this.isAttached,
    required this.onTap,
    this.onTextDetected,
    this.imagePath,
  });

  @override
  State<StatefulWidget> createState() => ScannerCardSlotState();
}

class ScannerCardSlotState extends State<ScannerCardSlot> {
  @override
  Widget build(BuildContext context) {
    String imagePath = widget.imagePath ?? '';
    return Expanded(
      child: Container(
        width: double.infinity, // Forces the container to fill the Column's width
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.isScanning ? Colors.cyanAccent : Colors.white10, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: widget.isScanning
              ? TextScanner(
                  onTextDetected: (RecognizedText text) {
                    if (widget.onTextDetected != null) {
                      widget.onTextDetected!(text);
                    }
                  },
                  mockImagePath: imagePath,
                )
              : widget.isAttached && widget.imagePath != null
              ? Image.asset(imagePath, fit: BoxFit.contain)
              : InkWell(
                  onTap: widget.onTap,
                  child: SizedBox.expand(
                    // This makes the ENTIRE box clickable
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined, color: Colors.white24, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
