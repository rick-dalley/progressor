import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:triage/app_theme.dart';
import '../classes/action.dart';

final List<Color> segmentColors = [
  Colors.blue.shade50,
  Colors.cyan.shade50,
  Colors.teal.shade50,
  Colors.green.shade50,
  Colors.lime.shade50,
  Colors.yellow.shade50,
  Colors.orange.shade50,
  Colors.red.shade50,
  Colors.pink.shade50,
  Colors.purple.shade50,
  Colors.indigo.shade50,
  Colors.blueGrey.shade50,
];

class TimelineSegment {
  String name;
  DateTime starts;
  DateTime ends;
  Color? backgroundColor;

  TimelineSegment({required this.name, required this.starts, required this.ends, this.backgroundColor});

  factory TimelineSegment.fromJson(dynamic json) {
    return TimelineSegment(name: json["name"], starts: json["starts"], ends: json["ends"]);
  }
}

class TimeLineWidget extends StatefulWidget {
  final List<PatientAction> actions;
  final DateTime startTime;
  final DateTime endTime;
  final Color? timelineColor;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final List<TimelineSegment>? segments;

  const TimeLineWidget({
    super.key,
    required this.actions,
    required this.startTime,
    required this.endTime,
    this.timelineColor,
    this.backgroundColor,
    this.foregroundColor,
    this.segments,
  });

  @override
  State<StatefulWidget> createState() => TimeLineWidgetState();
}

class TimeLineWidgetState extends State<TimeLineWidget> {
  double _zoomLevel = 1.0;
  String _selectedRange = 'A';
  Color color = Colors.black26;
  Color backgroundColor = AppTheme.clinicalCyan;
  Color foregroundColor = AppTheme.clinicalWhite;
  Color selectedBackgroundColor = AppTheme.clinicalWhite;
  Color selectedForegroundColor = AppTheme.clinicalCyan;
  late DateTime _currentStartTime;
  late DateTime _currentEndTime;
  late DateTime _timelineStart;
  late List<TimelineSegment> _segments;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 2. Initialize with the provided widget values
    color = widget.timelineColor ?? Colors.black26;
    backgroundColor = widget.backgroundColor ?? AppTheme.clinicalWhite;
    foregroundColor = widget.foregroundColor ?? AppTheme.clinicalCyan;
    selectedBackgroundColor = foregroundColor;
    selectedForegroundColor = backgroundColor;
    _timelineStart = widget.startTime;
    _currentStartTime = widget.startTime;
    _currentEndTime = widget.endTime;
    _segments = widget.segments ?? getSegmentsForDuration(startTime: _currentStartTime, endTime: _currentEndTime);
    // debugPrint('# of segments in TimelineWidgetState: ${_segments.length}');
    // debugPrint('# of actions in initState of TimeLineWidgetState: ${widget.actions.length}');
  }

  List<TimelineSegment> getSegmentsForDuration({required DateTime startTime, required DateTime endTime}) {
    List<TimelineSegment> segments = [];
    DateTime current = startTime;
    Duration timeSpan = endTime.difference(startTime);
    int index = 0;
    if (timeSpan.inDays > 365) {
      index = 0;
      while (current.isBefore(endTime)) {
        DateTime next = DateTime(current.year + 1, current.month + 1, 1);
        String name = DateFormat.y().format(current);
        segments.add(
          TimelineSegment(
            name: name,
            starts: current,
            ends: next,
            backgroundColor: segmentColors[index % segmentColors.length],
          ),
        );
        current = next;
        index++;
      }
    } else if (timeSpan.inDays <= 365 && timeSpan.inDays >= 90) {
      // YEAR view: Segment by Month
      while (current.isBefore(endTime)) {
        DateTime next = DateTime(current.year, current.month + 1, 1);
        String uot = DateFormat.MMM().format(current);
        String name = index > 0 ? uot : '$uot (${DateFormat.y().format(current)})';
        segments.add(
          TimelineSegment(
            name: name,
            starts: current,
            ends: next,
            backgroundColor: segmentColors[index % segmentColors.length],
          ),
        );
        current = next;
        index++;
      }
    } else if (timeSpan.inDays == 30) {
      // WEEK view: Segment by Day
      int index = 0;
      while (current.isBefore(endTime)) {
        DateTime next = current.add(const Duration(days: 7));
        String uot = 'Week ${index + 1}';
        String name = index > 0 ? uot : '$uot (${DateFormat.yMMM().format(current)})';
        segments.add(
          TimelineSegment(
            name: name,
            starts: current,
            ends: next,
            backgroundColor: segmentColors[index % segmentColors.length],
          ),
        );
        current = next;
        index++;
      }
    } else if (timeSpan.inDays == 7) {
      // WEEK view: Segment by Day
      int index = 0;
      while (current.isBefore(endTime)) {
        DateTime next = current.add(const Duration(days: 1));
        String uot = DateFormat.EEEE().format(current);
        String name = index > 0 ? uot : '$uot (${DateFormat.MMMd().format(current)})';
        segments.add(
          TimelineSegment(
            name: name,
            starts: current,
            ends: next,
            backgroundColor: segmentColors[index % segmentColors.length],
          ),
        );
        current = next;
        index++;
      }
    } else if (timeSpan.inDays == 1) {
      // DAY view: Segment by 4-hour chunks
      int index = 0;
      while (current.isBefore(endTime)) {
        DateTime next = current.add(const Duration(hours: 4));
        String uot = DateFormat.jm().format(current);
        String name = index > 0 ? uot : '$uot (${DateFormat.MMMd().format(current)})';
        segments.add(
          TimelineSegment(
            name: name,
            starts: current,
            ends: next,
            backgroundColor: segmentColors[index % segmentColors.length],
          ),
        );
        current = next;
        index++;
      }
    } else {
      // HOUR view: Segment by 15-minute chunks
      int index = 0;
      while (current.isBefore(endTime)) {
        DateTime next = current.add(const Duration(minutes: 15));
        String uot = DateFormat.jm().format(current);
        String name = index > 0 ? uot : '$uot (${DateFormat.MMMd().format(current)})';
        segments.add(
          TimelineSegment(
            name: name,
            starts: current,
            ends: next,
            backgroundColor: segmentColors[index % segmentColors.length],
          ),
        );
        current = next;
        index++;
      }
    }
    return segments;
  }

  void _updateRange(String range) {
    setState(() {
      _selectedRange = range;
      _currentStartTime = getStartTimeForRange(range);
      _currentEndTime = DateTime.now();
      _segments = widget.segments ?? getSegmentsForDuration(startTime: _currentStartTime, endTime: _currentEndTime);
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
              ButtonSegment(value: 'H', label: Text('Hour')),
              ButtonSegment(value: 'D', label: Text('Day')),
              ButtonSegment(value: 'W', label: Text('Week')),
              ButtonSegment(value: 'M', label: Text('Month')),
              ButtonSegment(value: 'Y', label: Text('Year')),
              ButtonSegment(value: 'A', label: Text('All')),
            ],
            selected: {_selectedRange},
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              backgroundColor: AppTheme.clinicalWhite,
              foregroundColor: AppTheme.deepLogicViolet,
              selectedBackgroundColor: AppTheme.deepLogicViolet,
              selectedForegroundColor: AppTheme.clinicalWhite,
            ),
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
                    actions: widget.actions,
                    startTime: _currentStartTime,
                    endTime: _currentEndTime,
                    zoomLevel: _zoomLevel,
                    color: color,
                    backgroundColor: backgroundColor,
                    foregroundColor: foregroundColor,
                    segments: _segments,
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
      case 'H':
        return now.subtract(const Duration(hours: 3));
      case 'D':
        return now.subtract(const Duration(days: 1));
      case 'W':
        return now.subtract(const Duration(days: 7));
      case 'M':
        return now.subtract(const Duration(days: 30));
      case 'Y':
        return now.subtract(const Duration(days: 365));
      case 'A':
        return _timelineStart;
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
  final Color? color;
  final Color? backgroundColor;
  final Color? foregroundColor;
  List<TimelineSegment>? segments;

  TimeLinePainter({
    required this.actions,
    required this.startTime,
    required this.endTime,
    required this.zoomLevel,
    this.color,
    this.backgroundColor,
    this.foregroundColor,
    this.segments,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double padding = 60.0;
    final totalDuration = endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch;
    final double centerX = size.width / 2;

    // Paints
    final Paint axisPaint = Paint()..color = color ?? Colors.black26..strokeWidth = 2.0;
    final Paint cardPaint = Paint()..color = backgroundColor ?? Colors.white..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()..color = foregroundColor ?? Colors.blue..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final TextStyle textStyle = TextStyle(color: foregroundColor ?? Colors.blue, fontSize: 14);

    // 1. Draw Segments (Full-bleed, mapped to total height)
    if (segments != null) {
      for (TimelineSegment seg in segments!) {
        final startProgress = (seg.starts.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch) / totalDuration;
        final endProgress = (seg.ends.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch) / totalDuration;

        final double yStart = size.height * startProgress * zoomLevel;
        final double yEnd = size.height * endProgress * zoomLevel;

        final Paint segPaint = Paint()..color = seg.backgroundColor ?? Colors.grey.shade100..style = PaintingStyle.fill;

        paintSegment(
          canvas: canvas,
          text: seg.name,
          segmentPaint: segPaint,
          x: 0.0,
          y: yStart,
          width: size.width,
          height: (yEnd - yStart).abs(),
        );
      }
    }

    // 2. Draw Axis (Full height)
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height * zoomLevel + padding + 12), axisPaint);

    // 3. Draw Tags (Mapped to total height, but clamped)
    for (var action in actions) {
      final progress = ((action.occurred * 1000) - startTime.millisecondsSinceEpoch) / totalDuration;

      // Map directly to the same scale as segments
      final double rawY = size.height * progress * zoomLevel;

      // Clamp the Y so it never goes above 60 or below (height - 60)
      // This keeps the tags "safe" without shifting the entire coordinate system
      final double y = rawY.clamp(padding, (size.height * zoomLevel) - padding);

      drawTimeTag(centerX, 100, y, 40, canvas, cardPaint, borderPaint, action, textStyle);
      drawActionTag(centerX, 184, y, 40, canvas, cardPaint, borderPaint, action, textStyle);
    }
  }

  void paintSegment({
    required Canvas canvas,
    required String text,
    required Paint segmentPaint,
    required double y,
    required double x,
    required double width,
    required double height,
  }) {
    // 1. Draw the background rectangle
    final Rect rect = Rect.fromLTWH(x, y, width, height);
    canvas.drawRect(rect, segmentPaint);

    // 2. Configure the text
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.black54, // Or your theme's foreground color
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);

    // 3. Layout the text
    textPainter.layout(minWidth: 0, maxWidth: width);

    // 4. Paint the text at the top-left (with a little padding)
    textPainter.paint(canvas, Offset(x + 12, y + 6));
  }

  void drawActionTag(
    double centerX,
    double actionBoxWidth,
    double y,
    double boxHeight,
    Canvas canvas,
    Paint cardPaint,
    Paint borderPaint,
    PatientAction action,
    TextStyle textStyle,
  ) {
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

  void drawTimeTag(
    double centerX,
    double dateBoxWidth,
    double y,
    double boxHeight,
    Canvas canvas,
    Paint cardPaint,
    Paint borderPaint,
    PatientAction action,
    TextStyle textStyle,
  ) {
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
  }

  @override
  bool shouldRepaint(TimeLinePainter oldDelegate) {
    // You MUST check all variables that affect the visual output
    return oldDelegate.zoomLevel != zoomLevel || oldDelegate.startTime != startTime || oldDelegate.endTime != endTime;
  }
}
