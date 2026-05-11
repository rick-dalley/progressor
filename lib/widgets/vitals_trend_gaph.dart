import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart';

class VitalsTrendGraph extends StatefulWidget {
  final List<Map<String, dynamic>> history;
  const VitalsTrendGraph({super.key, required this.history});

  @override
  State<VitalsTrendGraph> createState() => _VitalsTrendGraphState();
}

class _VitalsTrendGraphState extends State<VitalsTrendGraph> {
  // Toggle states
  bool showPulse = true;
  bool showBP = true;
  bool showTemp = false;
  bool showO2 = false;

  @override
  Widget build(BuildContext context) {
    final double graphHeight = MediaQuery.of(context).size.height * 0.225;
    return Container(
      // Extends the Monitor Black background to the entire widget area
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.monitorBlack,
        borderRadius: BorderRadius.circular(12), // Matches your hardware-aligned curves
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Column(
        children: [
          SizedBox(
            height: graphHeight,
            child: LineChart(
              LineChartData(
                // Set to transparent so the Container color shows through
                backgroundColor: Colors.transparent,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  if (showPulse) _generateLine(widget.history, 'pulse', AppTheme.vitalsPulse),
                  if (showBP) _generateLine(widget.history, 'systolic', AppTheme.vitalsBP),
                  if (showBP) _generateLine(widget.history, 'diastolic', AppTheme.vitalsBP.withAlpha(168)),
                  if (showTemp) _generateLine(widget.history, 'temperature', AppTheme.vitalsTemp),
                  if (showO2) _generateLine(widget.history, 'o2', AppTheme.vitalsOxygen),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // This will now sit on the black background
          _buildToggles(),
        ],
      ),
    );
  }

  LineChartBarData _generateLine(List<Map<String, dynamic>> data, String key, Color color) {
    // Reverse data so it plots left-to-right (oldest to newest)
    final points = data.reversed.toList().asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value[key] as num).toDouble());
    }).toList();

    return LineChartBarData(
      spots: points,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildToggles() {
    return Wrap(
      spacing: 8,
      children: [
        _toggleChip("Pulse", showPulse, AppTheme.vitalsPulse, (v) => setState(() => showPulse = v)),
        _toggleChip("BP", showBP, AppTheme.vitalsBP, (v) => setState(() => showBP = v)),
        _toggleChip("Temp", showTemp, AppTheme.vitalsTemp, (v) => setState(() => showTemp = v)),
        _toggleChip("O2", showO2, AppTheme.vitalsOxygen, (v) => setState(() => showO2 = v)),
      ],
    );
  }

  Widget _toggleChip(String label, bool active, Color color, Function(bool) onToggle) {
    return FilterChip(
      label: Text(label, style: TextStyle(color: Colors.black, fontSize: 12)),
      selected: active,
      onSelected: onToggle,
      selectedColor: color,
      backgroundColor: Colors.transparent,
      checkmarkColor: Colors.black,
      shape: StadiumBorder(side: BorderSide(color: color)),
    );
  }
}