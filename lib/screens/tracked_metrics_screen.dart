import 'package:flutter/material.dart';
import 'package:carbon_ui/carbon_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/tracked_metric.dart';

// Lets the clinician choose what to track for this patient — modeled on
// Ally's MetricExpandableCard pattern (a card per metric with an inline
// "add a reading" input, not a popup dialog), but deliberately without
// Ally's thresholds/targets/reminders/source picker — those are patient
// self-care conveniences beyond "track whatever's relevant and see it."
class TrackedMetricsScreen extends StatefulWidget {
  final String patientUuid;
  final String patientName;

  const TrackedMetricsScreen({super.key, required this.patientUuid, required this.patientName});

  @override
  State<TrackedMetricsScreen> createState() => _TrackedMetricsScreenState();
}

class _TrackedMetricsScreenState extends State<TrackedMetricsScreen> {
  // Matched by name rather than the seeder's catalog ids — stays correct even if
  // those ids are ever renumbered, since this only cares which definitions exist,
  // not what row they landed on.
  static const List<String> _vitalsSuiteNames = ['Systolic BP', 'Diastolic BP', 'Pulse', 'O2 Saturation', 'Temperature'];

  List<TrackedMetricDefinition> _all = [];
  Set<int> _trackedIds = {};
  Map<int, Map<String, dynamic>> _ranges = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await TrackedMetrics.allDefinitions();
    final trackedIds = await TrackedMetrics.trackedMetricIdsFor(widget.patientUuid);
    final ranges = await DatabaseManager().getTrackedMetricRangesForPatient(widget.patientUuid);
    if (!mounted) return;
    setState(() {
      _all = all;
      _trackedIds = trackedIds.toSet();
      _ranges = ranges;
      _loading = false;
    });
  }

  Future<void> _toggleTracking(TrackedMetricDefinition metric, bool track) async {
    if (track) {
      await TrackedMetrics.track(patientUuid: widget.patientUuid, metricId: metric.id);
    } else {
      await TrackedMetrics.untrack(patientUuid: widget.patientUuid, metricId: metric.id);
    }
    await _load();
  }

  Future<void> _logReading(TrackedMetricDefinition metric, String rawValue) async {
    final double? value = double.tryParse(rawValue);
    if (value == null) return;
    await TrackedMetrics.addReading(patientUuid: widget.patientUuid, metricId: metric.id, value: value);
    await _load();
  }

  bool get _allVitalsTracked =>
      _all.where((m) => _vitalsSuiteNames.contains(m.name)).every((m) => _trackedIds.contains(m.id));

  Future<void> _trackVitalsSuite() async {
    final toTrack = _all.where((m) => _vitalsSuiteNames.contains(m.name) && !_trackedIds.contains(m.id));
    for (final metric in toTrack) {
      await TrackedMetrics.track(patientUuid: widget.patientUuid, metricId: metric.id);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final double notchPadding = MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top : 47.0;
    final List<TrackedMetricDefinition> tracked = _all.where((m) => _trackedIds.contains(m.id)).toList();
    final List<TrackedMetricDefinition> available = _all.where((m) => !_trackedIds.contains(m.id)).toList();

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: MediaQuery.of(context).padding.copyWith(top: notchPadding)),
      child: Scaffold(
        backgroundColor: AppTheme.clinicalWhite,
        appBar: AppBar(
          title: Text("Tracked Metrics — ${widget.patientName}", style: const TextStyle(fontSize: 16)),
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          backgroundColor: AppTheme.clinicalWhite,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CarbonCompactButton(
                    icon: Symbols.vital_signs,
                    label: "Vitals Suite",
                    style: CarbonButtonStyle.primary,
                    onTap: _allVitalsTracked ? null : _trackVitalsSuite,
                  ),
                  const SizedBox(height: 24),
                  if (tracked.isNotEmpty) ...[
                    Text("TRACKED", style: CarbonTheme.carbonLabelTextStyle),
                    const SizedBox(height: 8),
                    for (final metric in tracked)
                      _TrackedMetricCard(
                        metric: metric,
                        range: _ranges[metric.id],
                        onUntrack: () => _toggleTracking(metric, false),
                        onLogReading: (value) => _logReading(metric, value),
                      ),
                    const SizedBox(height: 24),
                  ],
                  Text("AVAILABLE", style: CarbonTheme.carbonLabelTextStyle),
                  const SizedBox(height: 8),
                  for (final metric in available)
                    CarbonCheckboxListTile(
                      value: false,
                      onChanged: (_) => _toggleTracking(metric, true),
                      title: Text(metric.name),
                    ),
                ],
              ),
      ),
    );
  }
}

class _TrackedMetricCard extends StatefulWidget {
  final TrackedMetricDefinition metric;
  final Map<String, dynamic>? range;
  final VoidCallback onUntrack;
  final ValueChanged<String> onLogReading;

  const _TrackedMetricCard({
    required this.metric,
    required this.range,
    required this.onUntrack,
    required this.onLogReading,
  });

  @override
  State<_TrackedMetricCard> createState() => _TrackedMetricCardState();
}

class _TrackedMetricCardState extends State<_TrackedMetricCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    widget.onLogReading(_controller.text);
    _controller.clear();
    setState(() {});
  }

  void _cancel() => setState(() => _controller.clear());

  @override
  Widget build(BuildContext context) {
    final double? current = (widget.range?['current_value'] as num?)?.toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: widget.metric.color.withAlpha(120)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarbonCheckbox(value: true, onChanged: (_) => widget.onUntrack()),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.metric.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      current != null ? "${current.toStringAsFixed(1)} ${widget.metric.unit}" : "No readings yet",
                      style: CarbonTheme.carbonHelperTextStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CarbonNumberInput(
                  label: "New reading (${widget.metric.unit})",
                  controller: _controller,
                  accentColor: widget.metric.color,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_controller.text.isNotEmpty) ...[
                IconButton(icon: const Icon(Symbols.close, size: 18, color: carbonColorIconSecondary), onPressed: _cancel),
                IconButton(icon: const Icon(Symbols.check, size: 20, color: carbonColorSupportSuccess), onPressed: _confirm),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
