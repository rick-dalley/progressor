import 'package:flutter/material.dart';
import 'package:triage/app_theme.dart';

// PatientTimelineScreen
class PatientTimelineScreen extends StatelessWidget {
  final Map<String, dynamic> patient;

  const PatientTimelineScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    // Mocking the "Unified Stream"
    final List<Map<String, dynamic>> events = [
      {"type": "ED_ARRIV", "time": "10:30 AM", "label": "PHQ-9 Score", "value": "18 (Severe)", "color": Colors.orange},
      {"type": "LB_RESUL", "time": "09:15 AM", "label": "Sertraline", "value": "Increased: 50mg -> 100mg", "color": Colors.blue},
      {"type": "IM_START", "time": "08:00 AM", "label": "Vitals Taken", "value": "BP: 145/92 (High), HR: 88", "color": Colors.redAccent},
      {"type": "ED_BOARD", "time": "Yesterday", "label": "GAD-7 Score", "value": "12 (Moderate)", "color": Colors.green},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Timeline: ${patient['first_name']} ${patient['last_name']}"),
        backgroundColor: AppTheme.clinicalWhite,
        foregroundColor: AppTheme.deepCharcoal,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return IntrinsicHeight( // Ensures the vertical line stretches
            child: Row(
              children: [
                // The Timeline Line & Icon
                SizedBox(
                  width: 50,
                  child: Column(
                    children: [
                      Icon(AppTheme.eventIcons[event['type']], color: event['color']),
                      Expanded(
                        child: Container(width: 2, color: Colors.grey.shade300),
                      ),
                    ],
                  ),
                ),
                // The Content Card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(left: BorderSide(color: event['color'], width: 4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(event['label'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(event['time'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(event['value'], style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


}