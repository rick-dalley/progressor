import 'package:flutter/material.dart';

import '../app_theme.dart';

class VerticalRangeIndicator extends StatelessWidget {
  final double current, min, max, clinicalMin, clinicalMax, height;
  final Color color;
  final bool showHistoricOutlierMarkers;
  final String? label;

  const VerticalRangeIndicator({
    super.key,
    required this.current,
    required this.min,
    required this.max,
    required this.clinicalMin,
    required this.clinicalMax,
    required this.color,
    this.showHistoricOutlierMarkers = false,
    this.label,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Determine if we are out of bounds for the ripple
    double margin = height * 0.25;
    double paintAreaHeight = height - (2 * margin);
    final bool isOutlier = current > clinicalMax || current < clinicalMin;
    String sanitizedLabel = label ?? "value";
    // 2. Calculate the same Y position as the painter
    final double range = clinicalMax - clinicalMin;
    double currentY;
    if (current > clinicalMax) {
      currentY = -(6.0 - margin*2);
    } else if (current < clinicalMin) {
      currentY = height + 6.0;
    }
    else {
      currentY = height - (((current - clinicalMin) / range) * height);
    }

    return Column(
      mainAxisSize: MainAxisSize.min, // Takes only the space it needs

      children: [
        // 1. The existing graph stack
        SizedBox(height: margin,),
        Container(
          color: AppTheme.lightTheme.scaffoldBackgroundColor,
          width: 48,
          height: paintAreaHeight,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(12, paintAreaHeight),
                painter: IndicatorPainter(
                  current: current,
                  min: min,
                  max: max,
                  clinicalMin: clinicalMin,
                  clinicalMax: clinicalMax,
                  color: color,
                    showHistoricOutlierMarkers: showHistoricOutlierMarkers,
                ),
              ),
              if (isOutlier)
                Positioned(
                  top: currentY - (margin*2)-12,
                  child: IgnorePointer(child: RippleIndicator(color: color)),
                ),
            ],
          ),
        ),
        // 2. The Label (Name of the vital)
        SizedBox(height: margin),
        Text(
          sanitizedLabel, // e.g., "HR" or "SpO2"
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w300),
        ),

        // 3. The Value (Current reading)
        Text(
          current.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color, // Keeps the color-coding consistent
          ),
        ),
      ],
    );
  }
}

class IndicatorPainter extends CustomPainter {
  final double current, min, max, clinicalMin, clinicalMax;
  final Color color;
final bool showHistoricOutlierMarkers;
  IndicatorPainter({
    required this.current,
    required this.min,
    required this.max,
    required this.clinicalMin,
    required this.clinicalMax,
    required this.color,
    this.showHistoricOutlierMarkers = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double range = clinicalMax - clinicalMin;
    final double barWidth = 12.0;
    final circleRadius = barWidth * 0.5;
    final double centerX = size.width / 2;
    final bool hasHistory = (min != 0 || max != 0);

    double getY(double value) {
      final double normalized = (value - clinicalMin) / range;
      return size.height - (normalized * size.height);
    }

    // Light Grey Clinical Container (Pill shape)
    // canvas.drawRRect(
    //   RRect.fromRectAndRadius(Rect.fromLTWH(centerX - circleRadius, 0, barWidth, size.height), Radius.circular(circleRadius)),
    //   Paint()..color = Colors.grey.shade300,
    // );
    // final borderRect = RRect.fromRectAndRadius(
    //   Rect.fromLTWH(centerX - circleRadius, 0, barWidth, size.height),
    //   Radius.circular(circleRadius),
    // );

    // 2. Dark Grey Historical Bar (Pill shape)
    if (hasHistory) {
      final Rect histRect = Rect.fromLTRB(
        centerX - circleRadius,
        getY(max).clamp(0.0, size.height - circleRadius),
        centerX + circleRadius,
        getY(min).clamp(0.0, size.height),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(histRect, Radius.circular(circleRadius)),
        Paint()..color = color.withAlpha(128),
      );

      if(showHistoricOutlierMarkers){
        // 3. Red Round Boundary Markers (Width matched to bar, but circular)
        final Paint redPaint = Paint()..color = Colors.red;
        double currentY;

        if (current > clinicalMax) {
          // Instead of 0, shift it down by radius to keep it inside the rounded top
          currentY = circleRadius;
        } else if (current < clinicalMin) {
          // Instead of size.height, shift it up by radius to keep it inside the rounded bottom
          currentY = size.height - circleRadius;
        } else {
          // For values inside the range, getY(current) is correct,
          // but we must ensure it doesn't overlap the caps if we want it strictly contained
          currentY = getY(current).clamp(circleRadius, size.height - circleRadius);
        }
        // Top marker: centered horizontally on the bar
        if (max > clinicalMax) {
          canvas.drawCircle(Offset(centerX, currentY), circleRadius, redPaint);
        }
        // Bottom marker: centered horizontally on the bar
        if (min < clinicalMin) {
          canvas.drawCircle(Offset(centerX, size.height - circleRadius), circleRadius, redPaint);
        }
      }

    }
    // canvas.drawRRect(
    //   borderRect,
    //   Paint()
    //     ..color = Colors.black
    //     ..style = PaintingStyle.stroke
    //     ..strokeWidth = 1.0, // Adjust this for thickness
    // );

    // 4. Current Status Dot
    double currentY;
    if (current > clinicalMax) {
      currentY = -circleRadius;
    }
    else if (current < clinicalMin) {
      currentY = size.height + circleRadius;
    }
    else {
      currentY = getY(current);
    }

    canvas.drawCircle(Offset(centerX, currentY), circleRadius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RippleIndicator extends StatefulWidget {
  final Color color;
  const RippleIndicator({super.key, required this.color});

  @override
  RippleIndicatorState createState() => RippleIndicatorState();
}

class RippleIndicatorState extends State<RippleIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 2000))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Opacity fades out as it grows
        final double opacity = (1.0 - _controller.value);
        // Scale grows from 0.2 to 1.0
        final double size = 16.0 + (12.0 * _controller.value);

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Solid color, no border, fading opacity
            color: widget.color.withValues(alpha:0.5 * opacity),
          ),
        );
      },
    );
  }
}
