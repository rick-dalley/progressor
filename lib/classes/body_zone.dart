import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum HeadZones { none, forehead, rightEye, leftEye, rightEyeBrow, leftEyeBrow, rightEar, leftEar, nose, mouth, jaw, rightCheek, leftCheek, rightTemple, leftTemple, chin }

enum HandZones { none, palm, dorsum, thumb, pointer, middle, ring, little, wristJoint }

enum FootZones { none, heel, sole, instep, ball, bigToe, secondToe, thirdToe, fourthToe, littleToe, ankleJoint, footTop }

class Zone {
  final String name;
  final String latin;
  final List<Offset> points;

  Zone({
    required this.name,
    required this.latin,
    required this.points,
  });

  factory Zone.fromJson(Map<String, dynamic> json){
    List<dynamic> rawPoints = json['points'];
    List<Offset> offsetPoints  = [];

    for (dynamic rawPoint in rawPoints){
      double dx = (rawPoint['dx'] as num).toDouble(); //(json['dx'] as num).toDouble();
      double dy = (rawPoint['dy'] as num).toDouble();
      offsetPoints.add(Offset(dx, dy));
    }

    return Zone(
      name : json['name'],
      latin: json['latin'],
      points: offsetPoints,
    );
  }

  // Automatically generates the Path from your list of points
  Path get shape {
    if (points.isEmpty) return Path();

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    path.close();
    return path;
  }

  // Check if a tap point is within the polygon
  bool isIn(double dx, double dy) => shape.contains(Offset(dx, dy));

}

class PolygonPainter extends CustomPainter {
  final List<Zone> zones;
  PolygonPainter(this.zones);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha:0.3)
      ..style = PaintingStyle.fill;

    for (var zone in zones) {
      final path = Path()..addPolygon(zone.points, true);
      canvas.drawPath(path, paint);

      // Optional: Draw the name at the first point
      final textPainter = TextPainter(
        text: TextSpan(text: zone.name, style: const TextStyle(fontSize: 10, color: Colors.white)),
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

class TouchImage{
  final String imagePath;
  final List<Zone> zones;

  TouchImage({required this.imagePath, required this.zones});

  factory TouchImage.fromJson(Map<String, dynamic> json){
    dynamic rawZones = json['zones'];
    List<Zone> zonesFromJson = [];

    for (dynamic rawZone in rawZones){
      Zone zone = Zone.fromJson(rawZone['zone']);
          zonesFromJson.add(zone);
    }

    return TouchImage(
      imagePath: json['image_path'],
      zones:zonesFromJson,
    );
  }

}
enum ZoneMaps{ bodyFront, bodyBack, face, handFront, handBack, footTop, footBottom}

class TouchImageFactory {
  // Private constructor
  TouchImageFactory._();

  // The single instance
  static final TouchImageFactory instance = TouchImageFactory._();
  // Cached storage
  Map<ZoneMaps, TouchImage> _touchImages = {};

  // Initialization method (call this once at app startup)
  Future<void> initialize(String jsonPath) async {
    if (_touchImages.isNotEmpty) return; // Prevent re-parsing

    final String jsonString = await rootBundle.loadString(jsonPath);
    final List<dynamic> jsonList = json.decode(jsonString);

    _touchImages = {
      for (var item in jsonList)
        ZoneMaps.values[item['image_map_index']]: TouchImage.fromJson(item)

    };
  }

  // 5. Easy access
  TouchImage? getTouchImage({required ZoneMaps selection}) => _touchImages[selection];

  Map<ZoneMaps, TouchImage> get allTouchImages => Map.unmodifiable(_touchImages);

}

