import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/tracked_metric.dart';
import '../widgets/tracked_metrics_trend_graph.dart';
import 'tracked_metrics_screen.dart';

// The trend view across everything a clinician has chosen to track for this
// patient — tapping the compact vitals-style widget on the card opens this.
class TrackedMetricsTrendScreen extends StatefulWidget {
  final String patientUuid;
  final String patientName;

  const TrackedMetricsTrendScreen({super.key, required this.patientUuid, required this.patientName});

  @override
  State<TrackedMetricsTrendScreen> createState() => _TrackedMetricsTrendScreenState();
}

class _TrackedMetricsTrendScreenState extends State<TrackedMetricsTrendScreen> {
  List<TrackedMetricSeries> _series = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<TrackedMetricDefinition> all = await TrackedMetrics.allDefinitions();
    final List<int> trackedIds = await TrackedMetrics.trackedMetricIdsFor(widget.patientUuid);
    final Map<int, TrackedMetricDefinition> byId = {for (final d in all) d.id: d};

    final List<TrackedMetricSeries> series = [];
    for (final int id in trackedIds) {
      final TrackedMetricDefinition? definition = byId[id];
      if (definition == null) continue;
      final readings = await TrackedMetrics.readingsFor(patientUuid: widget.patientUuid, metricId: id);
      series.add(TrackedMetricSeries(definition: definition, readings: readings));
    }

    if (!mounted) return;
    setState(() {
      _series = series;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double notchPadding = MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top : 47.0;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: MediaQuery.of(context).padding.copyWith(top: notchPadding)),
      child: Scaffold(
        backgroundColor: AppTheme.clinicalWhite,
        appBar: AppBar(
          title: Text("Trends — ${widget.patientName}", style: const TextStyle(fontSize: 16)),
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          backgroundColor: AppTheme.clinicalWhite,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: "Manage tracked metrics",
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppTheme.clinicalWhite,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                  builder: (context) => TrackedMetricsScreen(
                    patientUuid: widget.patientUuid,
                    patientName: widget.patientName,
                  ),
                );
                await _load();
              },
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: TrackedMetricsTrendGraph(series: _series),
              ),
      ),
    );
  }
}
