import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:triage/classes/vitals.dart';
import '../app_theme.dart';

class VitalsTrendGraph extends StatefulWidget {
  final List<VitalsRecord> history;
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
    return Card(
      // Extends the Monitor Black background to the entire widget area
      child: Column(
        children: [
          Padding(padding: EdgeInsets.all(24),
          child: SizedBox(
            height: graphHeight,
            child: LineChart(
              LineChartData(
                // Set to transparent so the Container color shows through
                backgroundColor: Colors.transparent,
                gridData: const FlGridData(show: true),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  if (showPulse) _generateLine(widget.history, MetricType.pulse, AppTheme.vitalsPulse),
                  if (showBP) _generateLine(widget.history, MetricType.systolic, AppTheme.vitalsBP),
                  if (showBP) _generateLine(widget.history, MetricType.diastolic, AppTheme.vitalsBP.withAlpha(168)),
                  if (showTemp) _generateLine(widget.history, MetricType.temperature, AppTheme.lightTheme.disabledColor),
                  if (showO2) _generateLine(widget.history, MetricType.spo2, AppTheme.vitalsOxygen),
                ],
              ),
            ),
          ),),
          const SizedBox(height: 16),
          // This will now sit on the black background
          _buildToggles(),
        ],
      ),
    );
  }

  LineChartBarData _generateLine(List<VitalsRecord> data, MetricType type, Color color) {
    final points = data.reversed.toList().asMap().entries.map((e) {
      final record = e.value;

      // Switch to get the specific metric object based on the type
      final Metric? metric = switch (type) {
        MetricType.temperature => record.temp,
        MetricType.systolic    => record.sys,
        MetricType.diastolic   => record.dia,
        MetricType.pulse       => record.pulse,
        MetricType.spo2        => record.o2,
        MetricType.unknown     => null,
      };

      // Return the value, defaulting to 0.0 or handling nulls as needed
      return FlSpot(e.key.toDouble(), metric?.value ?? 0.0);
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
        _toggleChip("Temp", showTemp, AppTheme.lightTheme.disabledColor, (v) => setState(() => showTemp = v)),
        _toggleChip("O2", showO2, AppTheme.vitalsOxygen, (v) => setState(() => showO2 = v)),
      ],
    );
  }

  Widget _toggleChip(String label, bool active, Color color, Function(bool) onToggle) {
    return FilterChip(
      label: Text(label, style: TextStyle(color: active ? Colors.white:Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
      selected: active,
      onSelected: onToggle,
      selectedColor: color,
      backgroundColor: Colors.transparent,
      checkmarkColor: Colors.black,
      shape: StadiumBorder(side: BorderSide(color: color)),
    );
  }
}