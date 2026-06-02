import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../classes/action.dart';
import '../classes/date_time.dart';
import '../widgets/timeline_widget.dart';

class PatientTimelineScreen extends StatefulWidget {
  final List<PatientAction> actions;
  final String patientName;

  const PatientTimelineScreen({super.key, required this.actions, required this.patientName});

  @override
  State<PatientTimelineScreen> createState() => PatientTimelineScreenState();
}

class PatientTimelineScreenState extends State<PatientTimelineScreen> {
  String _selectedRange = 'M';

  Widget _buildRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'D', label: Text('Day')),
          ButtonSegment(value: 'W', label: Text('Week')),
          ButtonSegment(value: 'M', label: Text('Month')),
          ButtonSegment(value: 'Y', label: Text('Year')),
        ],
        selected: {_selectedRange},
        onSelectionChanged: (newSelection) {
          setState(() {
            _selectedRange = newSelection.first;
            // This triggers the TimeLineWidget to rebuild with new dates
          });
        },
      ),
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

  @override
  Widget build(BuildContext context) {
    final double notchPadding = MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top : 47.0;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: MediaQuery.of(context).padding.copyWith(top: notchPadding)),
      child: Scaffold(
        backgroundColor: AppTheme.clinicalWhite,
        appBar: AppBar(
          title: Text("History of $widget.patientName", style: const TextStyle(fontSize: 18)),

          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close), // or Icons.arrow_back
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: AppTheme.clinicalWhite,
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildRangeSelector(),
            Expanded(
              child: TimeLineWidget(
                actions: widget.actions,
                // Ensure these match your actual requirements
                startTime: DTUtilities.aYearAgo(),
                endTime: DateTime.now(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
