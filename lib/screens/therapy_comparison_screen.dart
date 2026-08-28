import 'package:flutter/material.dart';
import 'package:carbon_ui/carbon_ui.dart';

import '../app_theme.dart';
import '../classes/timeline_adapters.dart';

// Lets a clinician see how treatments (clinical actions, medication/prescription
// changes) stack up against objective patient events (tracked-metric readings) and
// the patient's care-phase periods, all on one shared timeline — via the widget
// externalized from Ally's own therapy-comparison tool.
class TherapyComparisonScreen extends StatefulWidget {
  final String patientUuid;
  final String patientName;

  const TherapyComparisonScreen({super.key, required this.patientUuid, required this.patientName});

  @override
  State<TherapyComparisonScreen> createState() => _TherapyComparisonScreenState();
}

class _TherapyComparisonScreenState extends State<TherapyComparisonScreen> {
  TherapyComparisonData? _data;

  @override
  void initState() {
    super.initState();
    loadTherapyComparisonData(widget.patientUuid).then((d) {
      if (mounted) setState(() => _data = d);
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
          title: Text("Comparing Therapies — ${widget.patientName}", style: const TextStyle(fontSize: 16)),
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          backgroundColor: AppTheme.clinicalWhite,
          elevation: 0,
        ),
        body: _data == null
            ? const Center(child: CircularProgressIndicator())
            : CarbonTimelineScroller(
                availableSpans: _data!.spans,
                points: _data!.points,
                startTime: _data!.startTime,
                endTime: _data!.endTime,
              ),
      ),
    );
  }
}
