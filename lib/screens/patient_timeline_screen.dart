import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../classes/action.dart';
import '../classes/date_time_utilities.dart';
import '../widgets/timeline_widget.dart';

class PatientTimelineScreen extends StatefulWidget {
  final List<PatientAction> actions;
  final String patientName;

  const PatientTimelineScreen({super.key, required this.actions, required this.patientName});

  @override
  State<PatientTimelineScreen> createState() => PatientTimelineScreenState();
}

class PatientTimelineScreenState extends State<PatientTimelineScreen> {


  @override
  Widget build(BuildContext context) {
    final double notchPadding = MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top : 47.0;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: MediaQuery.of(context).padding.copyWith(top: notchPadding)),
      child: Scaffold(
        backgroundColor: AppTheme.clinicalWhite,
        appBar: AppBar(
          title: Text("History of ${widget.patientName}", style: const TextStyle(fontSize: 18)),

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
            Expanded(
              child: TimeLineWidget(
                actions: widget.actions,
                startTime: DTUtilities.aYearAgo(),
                endTime: DateTime.now(),
                timelineColor:Colors.black26,

              ),
            ),
          ],
        ),
      ),
    );
  }
}
