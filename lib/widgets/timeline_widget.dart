import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../classes/action.dart';

class TimeLineWidget extends StatefulWidget {
  final List<PatientAction> actions;
  final DateTime startTime;
  final DateTime endTime;

  const TimeLineWidget({super.key, required this.actions, required this.startTime, required this.endTime});

  @override
  State<StatefulWidget> createState() => TimeLineWidgetState();
}

class TimeLineWidgetState extends State<TimeLineWidget> {
  double _zoomLevel = 1.0;
  String _selectedRange = 'M';

  late DateTime _currentStartTime;
  late DateTime _currentEndTime;

  final ScrollController _scrollController = ScrollController();


  @override
  void initState() {
    super.initState();
    // 2. Initialize with the provided widget values
    _currentStartTime = widget.startTime;
    _currentEndTime = widget.endTime;
  }

  void _updateRange(String range) {
    setState(() {
      _selectedRange = range;
      // 3. Update the local variables, not just the string
      _currentStartTime = getStartTimeForRange(range);
      _currentEndTime = DateTime.now();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. The Selector sits at the top, naturally taking its required height
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'D', label: Text('Day')),
              ButtonSegment(value: 'W', label: Text('Week')),
              ButtonSegment(value: 'M', label: Text('Month')),
              ButtonSegment(value: 'Y', label: Text('Year')),
            ],
            selected: {_selectedRange},
            onSelectionChanged: (newSelection) => _updateRange(newSelection.first),
          ),
        ),

        // 2. Expanded forces the timeline to take ONLY the remaining space
        Expanded(
          child: GestureDetector(
            onScaleUpdate: (ScaleUpdateDetails details) {
              double newZoom = _zoomLevel + (details.scale - 1.0) * 0.5;
              setState(() {
                _zoomLevel = newZoom.clamp(1.0, 10.0);
              });
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                height: 1000 * _zoomLevel,
                width: double.infinity,
                child: CustomPaint(
                  // 3. CRITICAL: Now using the local state-managed dates
                  painter: TimeLinePainter(
                      widget.actions,
                      _currentStartTime,
                      _currentEndTime,
                      _zoomLevel
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DateTime getStartTimeForRange(String range) {
    final now = DateTime.now();
    switch (range) {
      case 'D':
        return now.subtract(const Duration(days: 1));
      case 'W':
        return now.subtract(const Duration(days: 7));
      case 'M':
        return now.subtract(const Duration(days: 30));
      case 'Y':
        return now.subtract(const Duration(days: 365));
      default:
        return now.subtract(const Duration(days: 30));
    }
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
    final double centerX = size.width / 2;
    final double dateBoxWidth = 100;
    final double actionBoxWidth = 184;
    final double boxHeight = 40;
    final double radius = 8.0;

    final Paint axisPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2.0;
    final Paint cardPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()
      ..color = Colors.blue.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw the main axis
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height * zoomLevel), axisPaint);

    final totalDuration = endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch;
    final textStyle = const TextStyle(color: Colors.black, fontSize: 14);

    for (var action in actions) {
      final actionTime = action.occurred * 1000;
      final progress = (actionTime - startTime.millisecondsSinceEpoch) / totalDuration;
      final double y = size.height * progress * zoomLevel;

      // --- CORRECTED PATH LOGIC ---
      {
        final Path path = Path();

        final double left = centerX - dateBoxWidth;
        final double axisX = centerX;
        final double top = y - (boxHeight / 2);
        final double bottom = y + (boxHeight / 2);
        final double radius = 8.0;

        // The "straight" part of the box before the taper starts
        final double shoulderX = left + dateBoxWidth - 15.0;

        // 1. Start at top-left curve anchor
        path.moveTo(left + radius, top);

        // 2. Straight line across the top to the shoulder
        path.lineTo(shoulderX, top);

        // 3. Taper from shoulder to the point on the axis
        path.lineTo(axisX, y);

        // 4. Taper from point back to the bottom shoulder
        path.lineTo(shoulderX, bottom);

        // 5. Straight line across the bottom to the left radius
        path.lineTo(left + radius, bottom);

        // 6. Bottom-left corner curve
        path.quadraticBezierTo(left, bottom, left, bottom - radius);

        // 7. Left edge upwards
        path.lineTo(left, top + radius);

        // 8. Top-left corner curve
        path.quadraticBezierTo(left, top, left + radius, top);
        path.close();

        // Draw the shape
        canvas.drawPath(path, cardPaint);
        canvas.drawPath(path, borderPaint);
        // Date inside the box
        final timeStr = DateFormat('MMM d').format(DateTime.fromMillisecondsSinceEpoch(action.occurred * 1000));
        final timePainter = TextPainter(
          text: TextSpan(text: timeStr, style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: dateBoxWidth - radius);
        timePainter.paint(canvas, Offset(left + radius, y - (timePainter.height / 2)));
      }
      // --- ACTION CARD (RIGHT SIDE) ---
      {
        final Path actionPath = Path();

        final double rightStart = centerX + 15; // Offset from axis
        final double rightEnd = rightStart + actionBoxWidth;
        final double top = y - (boxHeight / 2);
        final double bottom = y + (boxHeight / 2);
        final double radius = 8.0;

        // The shoulder is now on the left side of this box
        final double shoulderX = rightStart + 15.0;

        // 1. Start at the point (on the axis side)
        actionPath.moveTo(centerX, y);

        // 2. Up to the shoulder
        actionPath.lineTo(shoulderX, top);

        // 3. Top edge to the right
        actionPath.lineTo(rightEnd - radius, top);

        // 4. Top-right corner curve
        actionPath.quadraticBezierTo(rightEnd, top, rightEnd, top + radius);

        // 5. Right edge down
        actionPath.lineTo(rightEnd, bottom - radius);

        // 6. Bottom-right corner curve
        actionPath.quadraticBezierTo(rightEnd, bottom, rightEnd - radius, bottom);

        // 7. Bottom edge back to shoulder
        actionPath.lineTo(shoulderX, bottom);

        // 8. Back to the point on the axis
        actionPath.lineTo(centerX, y);

        actionPath.close();

        canvas.drawPath(actionPath, cardPaint);
        canvas.drawPath(actionPath, borderPaint);

        // --- TEXT RENDERING ---
        // Action Name to the right of the axis
        final namePainter = TextPainter(
          text: TextSpan(text: action.getName(), style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        namePainter.paint(canvas, Offset(centerX + 15, y - (namePainter.height / 2)));
      }
    }
  }

  @override
  bool shouldRepaint(TimeLinePainter oldDelegate) {
    // You MUST check all variables that affect the visual output
    return oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.startTime != startTime ||
        oldDelegate.endTime != endTime;
  }
}
