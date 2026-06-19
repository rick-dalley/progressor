import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:triage/screens/body_screen.dart';

enum AnatomyZoneMaps { bodyFront, bodyBack, face, handFront, handBack, footTop, footBottom }

enum BodyMarkerGroup {
  none,
  bodyFront,
  bodyBack,
  leftHandFront,
  leftHandBack,
  rightHandFront,
  rightHandBack,
  leftFootTop,
  leftFootBottom,
  rightFootTop,
  rightFootBottom,
  face,
}

class Zone {
  final String name;
  final String latin;
  final List<Offset> points;
  final AnatomyZoneMaps map;
  final Path shape;
  final bool isLink;

  Zone({required this.name, required this.latin, required this.points, required this.map, required this.isLink})
    : shape = _pathFromPoints(points);

  factory Zone.fromJson(Map<String, dynamic> json, AnatomyZoneMaps zoneMap) {
    List<dynamic> rawPoints = json['points'];
    List<Offset> offsetPoints = [];

    for (dynamic rawPoint in rawPoints) {
      double dx = (rawPoint['dx'] as num).toDouble(); //(json['dx'] as num).toDouble();
      double dy = (rawPoint['dy'] as num).toDouble();
      offsetPoints.add(Offset(dx, dy));
    }

    return Zone(
      name: json['name'],
      latin: json['latin'],
      map: zoneMap,
      points: offsetPoints,
      isLink: json['is_image_link'] ?? false,
    );
  }

  // Automatically generates the Path from your list of points
  static Path _pathFromPoints(List<Offset> points) {
    if (points.isEmpty) return Path();
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    return path;
  }

  Offset flipOffset(Offset point, FlipDirection flipDirection, double width, double height, double padding) {
    double dx = flipDirection == FlipDirection.flipX || flipDirection == FlipDirection.flipXY
        ? width - point.dx
        : point.dx;
    double dy = flipDirection == FlipDirection.flipY || flipDirection == FlipDirection.flipXY
        ? height - point.dy - padding
        : point.dy;
    return Offset(dx, dy);
  }

  // Automatically generates the Path from your list of points
  Path flipPath(FlipDirection flipDirection, double width, double height, double padding) {
    if (points.isEmpty) return Path();
    final path = Path();
    Offset flippedPoint = flipOffset(points.first, flipDirection, width, height, padding);
    path.moveTo(flippedPoint.dx, flippedPoint.dy);
    for (int i = 1; i < points.length; i++) {
      flippedPoint = flipOffset(points[i], flipDirection, width, height, padding);
      path.lineTo(flippedPoint.dx, flippedPoint.dy);
    }
    path.close();
    return path;
  }

  // Check if a tap point is within the polygon
  bool isIn(double dx, double dy) => shape.contains(Offset(dx, dy));
}

class PolygonPainter extends CustomPainter {
  final TouchImage touchImage;
  final FlipDirection flipDirection;
  final double width;
  final double height;
  final double imageHeight;
  PolygonPainter(this.touchImage, this.flipDirection, this.width, this.height, this.imageHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    for (var zone in touchImage.zones) {
      if (flipDirection == FlipDirection.flipX) {
        Path path = zone.flipPath(flipDirection, width, height, height - imageHeight);
        canvas.drawPath(path, paint);
      } else {
        canvas.drawPath(zone.shape, paint);
      }
      // Optional: Draw the name at the first point
      final textPainter = TextPainter(
        text: TextSpan(
          text: zone.name,
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, zone.points.first);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

const double dx = 0.0;
const double dy = 0.0;

class TouchImage {
  final String imagePath;
  final List<Zone> zones;
  final Image image;
  TouchImage({required this.imagePath, required this.zones}) : image = Image.asset(imagePath, fit: BoxFit.contain);

  factory TouchImage.fromJson(Map<String, dynamic> json) {
    dynamic rawZones = json['zones'];
    List<Zone> zonesFromJson = [];
    AnatomyZoneMaps zoneMap = AnatomyZoneMaps.values[json['image_map_index']];

    for (dynamic rawZone in rawZones) {
      Zone zone = Zone.fromJson(rawZone['zone'], zoneMap);
      zonesFromJson.add(zone);
    }

    return TouchImage(imagePath: json['image_path'], zones: zonesFromJson);
  }

  Size getSizeFromContainer() {
    ImageProvider provider = AssetImage(imagePath);
    Size size = Size(0, 0);
    provider
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((ImageInfo imageInfo, bool synchronousCall) {
            final double width = imageInfo.image.width.toDouble();
            final double height = imageInfo.image.height.toDouble();
            size = Size(width, height);
          }),
        );
    return size;
  }

  Widget flip(FlipDirection flip) {
    bool flipX = (flip == FlipDirection.flipX) || (flip == FlipDirection.flipXY);
    bool flipY = (flip == FlipDirection.flipY) || (flip == FlipDirection.flipXY);
    return Transform.flip(flipX: flipX, flipY: flipY, child: image);
  }
}

class TouchImageFactory {
  // Private constructor
  TouchImageFactory._();

  // The single instance
  static final TouchImageFactory instance = TouchImageFactory._();
  // Cached storage
  Map<AnatomyZoneMaps, TouchImage> _touchImages = {};

  // Initialization method (call this once at app startup)
  Future<void> initialize(String jsonPath) async {
    if (_touchImages.isNotEmpty) return; // Prevent re-parsing

    final String jsonString = await rootBundle.loadString(jsonPath);
    final List<dynamic> jsonList = json.decode(jsonString);

    _touchImages = {
      for (var item in jsonList) AnatomyZoneMaps.values[item['image_map_index']]: TouchImage.fromJson(item),
    };
  }

  // 5. Easy access
  TouchImage? getTouchImage({required AnatomyZoneMaps selection}) => _touchImages[selection];

  Map<AnatomyZoneMaps, TouchImage> get allTouchImages => Map.unmodifiable(_touchImages);
}
