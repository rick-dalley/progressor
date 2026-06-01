import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../classes/action.dart';

class TimeLineWidget extends StatefulWidget {
  final List<PatientAction> actions;
  final DateTime startTime;
  final DateTime endTime;

  const TimeLineWidget({
    super.key,
    required this.actions,
    required this.startTime,
    required this.endTime
  });

  @override
  State<StatefulWidget> createState() => TimeLineWidgetState();

}

class TimeLineWidgetState extends State<TimeLineWidget> {
  double _zoomLevel = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: (ScaleUpdateDetails details) {
        setState(() {
          // Increase zoom based on scale factor
          _zoomLevel = (_zoomLevel * details.scale).clamp(1.0, 10.0);
        });
      },
      child: SingleChildScrollView(
        child: SizedBox(
          height: 1000 * _zoomLevel, // Stretches height based on zoom
          width: double.infinity,
          child: CustomPaint(
            painter: TimeLinePainter(widget.actions, widget.startTime, widget.endTime, _zoomLevel),
          ),
        ),
      ),
    );
  }
}

class TimeLinePainter extends CustomPainter {
  final List<PatientAction> actions;
  final DateTime startTime;
  final DateTime endTime;
  final double zoomLevel;

  TimeLinePainter(this.actions, this.startTime, this.endTime, this.zoomLevel);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0;

    // Draw the main axis
    canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height * zoomLevel),
        paint
    );

    final totalDuration = endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch;
    final textStyle = const TextStyle(color: Colors.black, fontSize: 14);

    for (var action in actions) {
      final actionTime = action.occurred * 1000;
      final progress = (actionTime - startTime.millisecondsSinceEpoch) / totalDuration;
      final double y = size.height * progress * zoomLevel;

      final Offset center = Offset(size.width / 2, y);
      canvas.drawCircle(center, 6.0, paint);

      // --- LABELS ---
      final timeStr = DateFormat('MMM d').format(
          DateTime.fromMillisecondsSinceEpoch(action.occurred * 1000)
      );

      // Draw Time (Left)
      final timePainter = TextPainter(
        text: TextSpan(text: timeStr, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      timePainter.paint(canvas, Offset(center.dx - timePainter.width - 15, center.dy - (timePainter.height / 2)));

      // Draw Name (Right)
      // If this errors, ensure your PatientAction class has 'String get name' defined
      final namePainter = TextPainter(
        text: TextSpan(text: action.getName(), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      namePainter.paint(canvas, Offset(center.dx + 15, center.dy - (namePainter.height / 2)));
    }
  }

  @override
  bool shouldRepaint(TimeLinePainter oldDelegate) {
    return oldDelegate.zoomLevel != zoomLevel;
  }
}