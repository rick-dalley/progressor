import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<File> getFileFromAsset(String assetPath) async {
  // Load the asset data
  final byteData = await rootBundle.load(assetPath);

  // Create a temp file in the device's cache directory
  final file = File('${(await getTemporaryDirectory()).path}/${assetPath.split('/').last}');

  // Write the bytes to the file
  await file.writeAsBytes(byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes
  ));

  return file;
}

class TextScanner extends StatefulWidget {
  final Function(RecognizedText) onTextDetected;
  final String? mockImagePath; // If passed, we OCR this instead of the live feed

  const TextScanner({
    super.key,
    required this.onTextDetected,
    this.mockImagePath,
  });

  @override
  State<TextScanner> createState() => _TextScannerState();
}

class _TextScannerState extends State<TextScanner> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isPermissionGranted = false;
  bool _isProcessing = false;
  final TextRecognizer _textRecognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.mockImagePath != null) {
      _processMockImage();
    } else {
      _requestCameraPermission();
    }
  }

  Future<void> _processMockImage() async {
    try {
      // Convert asset path to a physical file the OCR can see
      final File imageFile = await getFileFromAsset(widget.mockImagePath!);

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      widget.onTextDetected(recognizedText);
    } catch (e) {
      debugPrint("OCR Mock Error: $e");
    }
  }
  // --- Camera Lifecycle & Permissions ---
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _isPermissionGranted = status.isGranted;
    });
    if (_isPermissionGranted) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller?.initialize();
    if (!mounted) return;
    setState(() {});

    // Start the stream for live document detection
    _controller?.startImageStream(_processCameraImage);
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    // Logic for converting CameraImage to InputImage goes here
    // (similar to yesterday, but using a larger ROI)

    _isProcessing = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mockImagePath != null) {
      return const Center(child: CircularProgressIndicator(color: Colors.indigo));
    }

    if (!_isPermissionGranted) {
      return const Center(child: Text("Camera permission required", style: TextStyle(color: Colors.white)));
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: 3 / 4, // More suitable for documents than a square
      child: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          _buildDocumentOverlay(),
        ],
      ),
    );
  }

  Widget _buildDocumentOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: _DocumentOverlayShape(
          borderColor: Colors.indigoAccent,
          borderWidth: 3.0,
        ),
      ),
      child: const Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "ALIGN DOCUMENT WITHIN FRAME",
            style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),
      ),
    );
  }
}

class _DocumentOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;

  const _DocumentOverlayShape({required this.borderColor, required this.borderWidth});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // A vertical document-style frame
    final frameRect = Rect.fromLTWH(
      rect.width * 0.1,
      rect.height * 0.1,
      rect.width * 0.8,
      rect.height * 0.8,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(12)),
      paint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}