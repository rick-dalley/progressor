import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../app_theme.dart';
import '../classes/tracked_metric.dart';

// Generalized version of Acuitage's vitals_trend_gaph.dart — same proven
// design (0-1 band normalized per metric, fixed out-of-bounds pixel margin,
// right-hand label gutter with collision avoidance), but for an arbitrary,
// per-patient set of tracked metrics instead of 5 fixed vitals. Two real
// differences from that design: (1) each metric can have its own reading
// count/times (not a shared batch reading_id), so the x-axis here is real
// elapsed time rather than a shared reading index; (2) a metric with no
// defined healthy range (e.g. Weight) falls back to its own observed
// min/max so it still gets a sensible band instead of crashing.

const double _bandMin = 0.0;
const double _bandMax = 1.0;
const double _outOfBoundsPixels = 16;
const double _gutterWidth = 56;
const double _gutterInset = 6;
const double _labelMinGap = 18;

class TrackedMetricSeries {
  final TrackedMetricDefinition definition;
  final List<Map<String, dynamic>> readings; // rows: {value, measured}
  const TrackedMetricSeries({required this.definition, required this.readings});
}

class TrackedMetricsTrendGraph extends StatefulWidget {
  final List<TrackedMetricSeries> series;
  const TrackedMetricsTrendGraph({super.key, required this.series});

  @override
  State<TrackedMetricsTrendGraph> createState() => _TrackedMetricsTrendGraphState();
}

class _TrackedMetricsTrendGraphState extends State<TrackedMetricsTrendGraph> {
  // Metric ids toggled off the chart via the legend chips. Empty = everything
  // tracked is plotted, which is the default.
  final Set<int> _hiddenMetricIds = {};

  @override
  Widget build(BuildContext context) {
    final double graphHeight = MediaQuery.of(context).size.height * 0.3;
    final List<TrackedMetricSeries> plottable = widget.series.where((s) => s.readings.isNotEmpty).toList();
    final List<TrackedMetricSeries> visible = plottable
        .where((s) => !_hiddenMetricIds.contains(s.definition.id))
        .toList();

    if (plottable.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text("No readings logged yet for anything tracked.")),
      );
    }

    DateTime? earliest;
    DateTime? latest;
    for (final s in plottable) {
      for (final r in s.readings) {
        final DateTime? t = DateTime.tryParse(r['measured']?.toString() ?? '');
        if (t == null) continue;
        if (earliest == null || t.isBefore(earliest)) earliest = t;
        if (latest == null || t.isAfter(latest)) latest = t;
      }
    }
    earliest ??= DateTime.now();
    latest ??= DateTime.now();
    // Minutes-since-earliest, not raw epoch milliseconds — fl_chart's curve
    // smoothing computes control points from data-space deltas, and epoch ms
    // (~1.7 trillion) next to a 0-1 Y range is such an extreme scale mismatch
    // that the interpolated curve can overshoot the plot area entirely, even
    // though every real data point is correctly in bounds.
    final DateTime chartEpoch = earliest;
    final double minXValue = 0.0;
    final double dataSpan = latest.difference(earliest).inMinutes.toDouble();

    final double bandPixels = (graphHeight - _outOfBoundsPixels * 2).clamp(1.0, graphHeight);
    final double marginFraction = _outOfBoundsPixels / bandPixels;
    final double axisMin = _bandMin - marginFraction;
    final double axisMax = _bandMax + marginFraction;

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 8, 24),
            child: SizedBox(
              height: graphHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double totalWidth = constraints.maxWidth;
                  final double plotWidth = (totalWidth - _gutterWidth).clamp(40.0, totalWidth);
                  final double effectiveSpan = dataSpan <= 0 ? 1.0 : dataSpan;
                  final double maxXValue = minXValue + effectiveSpan * totalWidth / plotWidth;

                  final List<_LastPointInfo> lastPoints = [];
                  final List<LineChartBarData> bars = [
                    for (final s in visible) _generateLine(s, lastPoints, axisMin, axisMax, chartEpoch),
                  ];

                  return Stack(
                    children: [
                      LineChart(
                        LineChartData(
                          backgroundColor: Colors.transparent,
                          minX: minXValue,
                          maxX: maxXValue,
                          minY: axisMin,
                          maxY: axisMax,
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          rangeAnnotations: RangeAnnotations(
                            horizontalRangeAnnotations: [
                              HorizontalRangeAnnotation(y1: _bandMin, y2: _bandMax, color: Colors.green.withAlpha(20)),
                            ],
                          ),
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(y: _bandMax, color: AppTheme.cardBorder, strokeWidth: 1, dashArray: [6, 4]),
                              HorizontalLine(y: _bandMin, color: AppTheme.cardBorder, strokeWidth: 1, dashArray: [6, 4]),
                            ],
                          ),
                          lineBarsData: bars,
                        ),
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          size: Size(totalWidth, graphHeight),
                          painter: _LastValueLabelsPainter(
                            points: lastPoints,
                            chartWidth: totalWidth,
                            chartHeight: graphHeight,
                            plotWidth: plotWidth,
                            minX: minXValue,
                            maxX: maxXValue,
                            axisMin: axisMin,
                            axisMax: axisMax,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(plottable),
          const SizedBox(height: 20),
          const Divider(height: 1),
          _buildReadingsTabs(plottable),
        ],
      ),
    );
  }

  LineChartBarData _generateLine(
    TrackedMetricSeries s,
    List<_LastPointInfo> lastPoints,
    double axisMin,
    double axisMax,
    DateTime chartEpoch,
  ) {
    // Oldest-first, so the line reads left-to-right like a normal timeline.
    final List<Map<String, dynamic>> sorted = [...s.readings]..sort((a, b) {
      final DateTime ta = DateTime.tryParse(a['measured']?.toString() ?? '') ?? DateTime.now();
      final DateTime tb = DateTime.tryParse(b['measured']?.toString() ?? '') ?? DateTime.now();
      return ta.compareTo(tb);
    });

    final List<double> values = sorted.map((r) => (r['value'] as num).toDouble()).toList();
    final double lower = s.definition.healthyLower ?? values.reduce((a, b) => a < b ? a : b);
    double upper = s.definition.healthyUpper ?? values.reduce((a, b) => a > b ? a : b);
    if (upper <= lower) upper = lower + 1; // guard a degenerate/zero-width band

    final List<FlSpot> points = [];
    for (final Map<String, dynamic> r in sorted) {
      final DateTime? t = DateTime.tryParse(r['measured']?.toString() ?? '');
      if (t == null) continue;
      final double value = (r['value'] as num).toDouble();
      // Clamped to the visible axis — several metrics share this one chart,
      // and a severe outlier (e.g. a systolic far past its healthy range)
      // would otherwise plot far off-canvas instead of just pinning against
      // the edge the way the compact card indicator already does.
      final double relative = ((value - lower) / (upper - lower)).clamp(axisMin, axisMax);
      points.add(FlSpot(t.difference(chartEpoch).inMinutes.toDouble(), relative));
    }

    if (points.isNotEmpty) {
      final FlSpot last = points.last;
      lastPoints.add(
        _LastPointInfo(
          dataX: last.x,
          relativeY: last.y,
          label: '${s.definition.symbol} ${values.last.toStringAsFixed(1)}',
          color: s.definition.color,
        ),
      );
    }

    return LineChartBarData(
      spots: points,
      // Straight segments, not a spline curve: with only a handful of sparse
      // readings per metric, a curve would invent motion between real data
      // points that was never actually observed — and straight lines can
      // never overshoot the plot area the way a curve's control points can.
      isCurved: false,
      color: s.definition.color,
      barWidth: 3,
      isStrokeCapRound: true,
      belowBarData: BarAreaData(show: false),
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) {
          final bool isLast = index == points.length - 1;
          return FlDotCirclePainter(
            radius: isLast ? 4 : 2.5,
            color: s.definition.color,
            strokeColor: Colors.white,
            strokeWidth: isLast ? 1.5 : 0,
          );
        },
      ),
    );
  }

  // Tappable — this is how a line gets shown/hidden on the chart above, not
  // just a static color key.
  Widget _buildLegend(List<TrackedMetricSeries> plottable) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: plottable.map((s) {
        final bool isVisible = !_hiddenMetricIds.contains(s.definition.id);
        return FilterChip(
          label: Text(
            '${s.definition.symbol} · ${s.definition.name}',
            style: TextStyle(
              color: isVisible ? Colors.white : s.definition.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          selected: isVisible,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _hiddenMetricIds.remove(s.definition.id);
              } else {
                _hiddenMetricIds.add(s.definition.id);
              }
            });
          },
          selectedColor: s.definition.color,
          backgroundColor: s.definition.color.withAlpha(20),
          checkmarkColor: Colors.white,
          side: BorderSide(color: s.definition.color),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  // Lets the doctor look through the actual values plotted above, one tab
  // per tracked metric — kept independent of the chip toggles above (hiding
  // a line from the chart doesn't mean its data shouldn't be reviewable).
  Widget _buildReadingsTabs(List<TrackedMetricSeries> plottable) {
    return DefaultTabController(
      length: plottable.length,
      child: SizedBox(
        height: 280,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              labelColor: AppTheme.deepLogicViolet,
              unselectedLabelColor: AppTheme.lightTheme.disabledColor,
              indicatorColor: AppTheme.deepLogicViolet,
              tabs: [for (final s in plottable) Tab(text: s.definition.symbol)],
            ),
            Expanded(
              child: TabBarView(
                children: [for (final s in plottable) _buildReadingsTable(s)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingsTable(TrackedMetricSeries s) {
    // Newest first — a review table reads better with the latest reading on
    // top, unlike the chart above which reads oldest-to-newest left to right.
    final List<Map<String, dynamic>> sorted = [...s.readings]..sort((a, b) {
      final DateTime ta = DateTime.tryParse(a['measured']?.toString() ?? '') ?? DateTime.now();
      final DateTime tb = DateTime.tryParse(b['measured']?.toString() ?? '') ?? DateTime.now();
      return tb.compareTo(ta);
    });

    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Value')),
        ],
        rows: [
          for (final r in sorted)
            DataRow(
              cells: [
                DataCell(Text(_formatMeasured(r['measured']))),
                DataCell(Text('${(r['value'] as num).toStringAsFixed(1)} ${s.definition.unit}')),
              ],
            ),
        ],
      ),
    );
  }

  String _formatMeasured(dynamic raw) {
    final DateTime? t = DateTime.tryParse(raw?.toString() ?? '');
    return t == null ? '—' : DateFormat('MMM d, h:mm a').format(t);
  }
}

class _LastPointInfo {
  final double dataX;
  final double relativeY;
  final String label;
  final Color color;
  const _LastPointInfo({required this.dataX, required this.relativeY, required this.label, required this.color});
}

class _LastValueLabelsPainter extends CustomPainter {
  final List<_LastPointInfo> points;
  final double chartWidth;
  final double chartHeight;
  final double plotWidth;
  final double minX;
  final double maxX;
  final double axisMin;
  final double axisMax;

  _LastValueLabelsPainter({
    required this.points,
    required this.chartWidth,
    required this.chartHeight,
    required this.plotWidth,
    required this.minX,
    required this.maxX,
    required this.axisMin,
    required this.axisMax,
  });

  double _pixelX(double dataX) {
    final double range = maxX - minX;
    return range <= 0 ? plotWidth : chartWidth * ((dataX - minX) / range);
  }

  double _pixelY(double relativeY) => chartHeight * (1 - (relativeY - axisMin) / (axisMax - axisMin));

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final List<({Offset source, String label, Color color})> entries = points
        .map((p) => (source: Offset(_pixelX(p.dataX), _pixelY(p.relativeY)), label: p.label, color: p.color))
        .toList()
      ..sort((a, b) => a.source.dy.compareTo(b.source.dy));

    final List<double> resolvedY = entries.map((e) => e.source.dy).toList();
    for (int i = 1; i < resolvedY.length; i++) {
      if (resolvedY[i] - resolvedY[i - 1] < _labelMinGap) {
        resolvedY[i] = resolvedY[i - 1] + _labelMinGap;
      }
    }
    final double overflow = resolvedY.last - (chartHeight - 8);
    if (overflow > 0) {
      for (int i = 0; i < resolvedY.length; i++) {
        resolvedY[i] -= overflow;
      }
    }

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final double labelY = resolvedY[i].clamp(8.0, chartHeight - 8.0);
      final Offset elbow = Offset(plotWidth + _gutterInset, labelY);

      canvas.drawLine(entry.source, elbow, Paint()
        ..color = entry.color.withAlpha(140)
        ..strokeWidth = 1);
      canvas.drawCircle(entry.source, 2.5, Paint()..color = entry.color);

      final TextPainter textPainter = TextPainter(
        text: TextSpan(text: entry.label, style: TextStyle(color: entry.color, fontSize: 12, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(elbow.dx + 4, labelY - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _LastValueLabelsPainter oldDelegate) => true;
}
