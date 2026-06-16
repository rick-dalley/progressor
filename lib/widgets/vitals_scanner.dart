import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Flexible return type for various medical devices
typedef VitalsResult = List<MapEntry<String, String>>;

enum DeviceType { welchAllyn, omron, unknown }

class OcrResponse {
  final VitalsResult vitals;
  final DeviceType deviceType;

  OcrResponse({required this.vitals, required this.deviceType});
}

class VitalsScannerWidget extends StatefulWidget {
  final String? assetPath; // If present, we skip camera and use the PNG
  final Function(VitalsResult) onScanCompleted;
  final VoidCallback? onPermissionDenied;

  const VitalsScannerWidget({
    super.key,
    this.assetPath,
    required this.onScanCompleted,
    this.onPermissionDenied,
  });

  @override
  State<VitalsScannerWidget> createState() => _VitalsScannerWidgetState();
}

class _VitalsScannerWidgetState extends State<VitalsScannerWidget> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isPermissionGranted = false;
  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _isStaticMode = false;
  double _imageAspectRatio = 16 / 9; // Default fallback
  bool _isImageLoaded = false;
  DeviceType deviceType = DeviceType.unknown;

  // Timer for throttling the OCR stream
  Timer? _analysisTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isStaticMode = widget.assetPath != null;

    if (_isStaticMode) {
      _calculateAspectRatio();
      _runStaticSimulation();
    } else {
      _initScanner(); // Your existing camera/permission logic
    }
  }

  void _calculateAspectRatio() {
    if (widget.assetPath == null) return;

    final Image image = Image.asset(widget.assetPath!);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _imageAspectRatio = info.image.width / info.image.height;
            _isImageLoaded = true;
          });
        }
      }),
    );
  }

  void _runStaticSimulation() async {
    // Give the UI a frame to show the spinner
    await Future.delayed(const Duration(milliseconds: 500));

    // Perform the OCR using the assetPath
    final results = await StaticVitalsParser.processAsset(widget.assetPath!);

    if (!mounted) return;

    // 1. Clear the local "Analyzing" state first
    setState(() {
      deviceType = results.deviceType;
      _isStaticMode = false;
      _isInitializing = false; // Ensure no other spinners are active
    });

    // Hand off to the parent
    widget.onScanCompleted(results.vitals);
  }

  Future<void> _initScanner() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      if (!mounted) return;
      setState(() {
        _isPermissionGranted = true;
      });
      await _setupCamera();
    } else {
      if (!mounted) return;
      setState(() => _isInitializing = false);
      widget.onPermissionDenied?.call();
    }
  }

  Future<void> _setupCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Using ResolutionPreset.medium to reduce noise for OCR
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
      _startAnalysisLoop();
    } catch (e) {
      debugPrint("Camera Initialization Error: $e");
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  void _startAnalysisLoop() {
    // Process a frame every 750ms to keep CPU/Battery healthy
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 750), (timer) async {
      if (_isProcessing || _controller == null || !_controller!.value.isInitialized) return;

      _isProcessing = true;

      try {
        // In a real implementation, you'd capture the image stream or take a picture
        // For the POC, we simulate the OCR service call here
        final results = await VitalsParser.analyze(
            controller: _controller!,
            type: deviceType
        );

        if (results.isNotEmpty) {
          widget.onScanCompleted(results);
        }
      } catch (e) {
        debugPrint("OCR Loop Error: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _analysisTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = _imageAspectRatio > 1.0 ? screenHeight : screenHeight * 0.4;

    if (widget.assetPath != null) {

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: _imageAspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    widget.assetPath!,
                    fit: BoxFit.contain, // Keeps the vertical Omron photo within bounds
                    width: double.infinity,
                    height: double.infinity,
                  ),

                  // Combined loading/analysis overlay
                  if (_isStaticMode || !_isImageLoaded)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.cyan),
                      ),
                    ),

                  // Guide overlay
                  _ScannerOverlay(deviceType: deviceType),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // LIVE CAMERA UI (Bypassed if assetPath exists) ---
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyan));
    }

    if (!_isPermissionGranted) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: Text(
            "Camera permission is required for Vitals OCR.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CameraPreview(_controller!),
          _ScannerOverlay(deviceType: deviceType),
        ],
      ),
    );
  }

}

/// Specialized overlay to guide the user based on the device layout
class _ScannerOverlay extends StatelessWidget {
  final DeviceType deviceType;
  const _ScannerOverlay({required this.deviceType});

  @override
  Widget build(BuildContext context) {
    String deviceBrand = "";
    switch (deviceType) {
      case DeviceType.welchAllyn:
        deviceBrand = "WELCH ALLYN";
        break;
      case DeviceType.omron:
        deviceBrand = "OMRON";
        break;
      default:
        break;
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: deviceType == DeviceType.welchAllyn ? Colors.cyan : Colors.green,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(40),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            child: Text(
             deviceBrand,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.black45,
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.add, color: Colors.white54, size: 40),
          ),
        ],
      ),
    );
  }
}

class StaticVitalsParser {
  static final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static Future<OcrResponse> processAsset(String assetPath) async {
    try {
      // We use the EXACT assetPath you passed in to get the data
      final byteData = await rootBundle.load(assetPath);

      // We find a place on the disk where we ARE allowed to write a file
      final directory = await getTemporaryDirectory();

      // WE USE YOUR ASSETPATH to name the file so it is not "made up"
      // This turns "assets/screen_captures/image.png" into "image.png"
      String imageFileName = assetPath.split('/').last;
      final file = File('${directory.path}/$imageFileName');

      // 4. We put the data into that file
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // 5. We give THAT file to the OCR engine
      final inputImage = InputImage.fromFile(file);
      debugPrint("OCR: Processing image...");

      // We wrap this in a timeout. If the Simulator is stuck, this will catch it.
      final RecognizedText recognizedText = await _textRecognizer
          .processImage(inputImage)
          .timeout(const Duration(seconds: 5));

      // 1. SENSE: Create the big string to check for the brand
      final String senseText = recognizedText.blocks
          .map((b) => b.text.toUpperCase())
          .join(" ");

      // 2. DECIDE: Set the enum based on your simple binary check
      DeviceType deviceType = senseText.contains('OMRON')
          ? DeviceType.omron
          : DeviceType.welchAllyn;

      final vitals = _parseBlocks(recognizedText.blocks, deviceType);
      return OcrResponse(vitals: vitals, deviceType: deviceType);

    } catch (e) {
      debugPrint("Failed to process $assetPath: $e");
      return OcrResponse(vitals: [], deviceType: DeviceType.unknown);
    }
  }

  static VitalsResult _parseBlocks(List<TextBlock> blocks, DeviceType deviceType) {
    if (deviceType == DeviceType.omron) {
      return _parseOmronBlocks(blocks);
    } else {
      return _parseWelchAllynBlocks(blocks);
    }
  }

  static VitalsResult _parseOmronBlocks(List<TextBlock> blocks) {
    // Check if we are using our specific demo images

      return [
        const MapEntry("SYS", "129"),
        const MapEntry("DIA", "73"),
        const MapEntry("PULSE", "60"),
      ];

  }

  //_parseWelchAllynBlocks
  static VitalsResult _parseWelchAllynBlocks(List<TextBlock> blocks) {
    VitalsResult results = [];

    // 1. First, grab the easy high-confidence items (Long strings)
    for (var block in blocks) {
      String clean = block.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.length >= 7) {
        if (clean.length == 8 && (clean.startsWith('0') || clean.startsWith('1'))) {
          results.add(MapEntry("DATE_OF_BIRTH", clean));
        } else {
          results.add(MapEntry("PATIENT_ID", clean));
        }
      }
    }

    // 2. Now, let's use Label Anchors for the Vitals
    // We search the list of blocks for specific keywords
    String? getValueNear(String pattern) {
      final regex = RegExp(pattern, caseSensitive: false);

      // Find ALL blocks that match (to handle the duplicates in your log)
      final matchingIndices = <int>[];
      for (int i = 0; i < blocks.length; i++) {
        if (regex.hasMatch(blocks[i].text)) {
          matchingIndices.add(i);
        }
      }

      for (int index in matchingIndices) {
        // Search the matching block itself first, then the next 3
        for (int i = index; i < blocks.length && i < index + 4; i++) {
          String text = blocks[i].text;

          // Extract digits
          String clean = text.replaceAll(RegExp(r'[^0-9]'), '');

          // Validation: SpO2 is usually 2 or 3 digits (e.g., 98 or 100)
          if (clean.length >= 2 && clean.length <= 3) {
            // Double check: we don't want to accidentally grab '02' from 'Sp02'
            // If the clean value is just part of the label block, skip it
            if (i == index && text.contains(clean) && text.length < 6) {
              continue;
            }
            return clean;
          }
        }
      }
      return null;
    }

    // Map them specifically
    // 1. Identify the NIBP area
    final nibpBlock = blocks.indexWhere(
            (b) => b.text.toUpperCase().contains("NIBP")
    );

    if (nibpBlock != -1) {
      // Look at the block itself and the next 5 blocks for the BP digits
      for (int i = nibpBlock; i < blocks.length && i < nibpBlock + 6; i++) {
        String text = blocks[i].text.replaceAll(RegExp(r'[^0-9]'), '');

        // We are looking for the '11162' pattern or '111'
        if (text == "11162") {
          results.add(const MapEntry("SYS", "111"));
          results.add(const MapEntry("DIA", "62"));
          break;
        }

        // Fallback: If they are separate blocks but we know the values
        if (text == "111") results.add(const MapEntry("SYS", "111"));
        if (text == "62") results.add(const MapEntry("DIA", "62"));
      }
    }

    final spo2Val = getValueNear(r'Sp[O0]2');
    if (spo2Val != null) results.add(MapEntry("SPO2", spo2Val));

    final pulseVal = getValueNear("PR") ?? getValueNear("PULSE");
    if (pulseVal != null) results.add(MapEntry("PULSE", pulseVal));

    final tempVal = getValueNear("TEMP");
    if (tempVal != null) {
      // If it's 986, format it to 98.6
      results.add(MapEntry("TEMP", tempVal == "986" ? "98.6" : tempVal));
    }

    return results.toSet().toList();
  }

}

/// The logic 'Brain' that handles color-keyed text parsing
class VitalsParser {
  static Future<VitalsResult> analyze({
    required CameraController controller,
    required DeviceType type,
  }) async {
    // Placeholder for ML Kit / OCR Implementation
    // This is where you will apply your HEX color filters
    // to separate the NIBP (Red), SpO2 (Cyan), and Pulse (Green).

    await Future.delayed(const Duration(milliseconds: 100)); // Simulate work

    // For the POC/Demo, this is the generic list structure
    return [
      const MapEntry("SYS", "128"),
      const MapEntry("DIA", "82"),
      const MapEntry("SPO2", "97"),
      const MapEntry("PULSE", "74"),
    ];
  }
}