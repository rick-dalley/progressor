import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';

class ProcessTreeOverlay extends StatelessWidget {
  final String patientUuid;
  final Map<String, dynamic> processMap;
  final List<Map<String, dynamic>> patientEvents;

  const ProcessTreeOverlay({
    super.key,
    required this.patientUuid,
    required this.processMap,
    required this.patientEvents,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> protocolSteps = List<String>.from(
        jsonDecode(processMap['steps_json'] ?? '[]')
    );

    return Container(
      padding: const EdgeInsets.all(20),
      color: AppTheme.clinicWhite,
      child: ListView.builder(
        itemCount: protocolSteps.length,
        itemBuilder: (context, index) {
          final stepLabel = protocolSteps[index];
          // Find if this step exists in the patient's actual history
          final event = patientEvents.firstWhere(
                (e) => e['step_label'] == stepLabel,
            orElse: () => {},
          );

          final bool isDone = event.isNotEmpty;
          final bool isLastDone = isDone &&
              (index == protocolSteps.length - 1 ||
                  !patientEvents.any((e) => e['step_label'] == protocolSteps[index + 1]));

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The Timeline Column
                Column(
                  children: [
                    Icon(
                      isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isDone ? AppTheme.clinicalCyan : AppTheme.deepCharcoal,
                      size: 20,
                    ),
                    if (index != protocolSteps.length - 1)
                      Expanded(
                        child: VerticalDivider(
                          color: isDone ? AppTheme.clinicalCyan.withAlpha(128) : AppTheme.deepCharcoal,
                          thickness: 2,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // The Content Column
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Opacity(
                      opacity: isDone ? 1.0 : 0.4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stepLabel.toUpperCase(),
                            style: GoogleFonts.inclusiveSans(
                              fontWeight: isLastDone ? FontWeight.w900 : FontWeight.bold,
                              color: isLastDone ? AppTheme.clinicWhite : AppTheme.deepCharcoal,
                              fontSize: 13,
                            ),
                          ),
                          if (isDone) ...[
                            const SizedBox(height: 4),
                            Text(
                              "${event['timestamp']} • ${event['staff_name']} (${event['staff_role']})",
                              style: const TextStyle(color: AppTheme.clinicalCyan, fontSize: 10),
                            ),
                            if (event['notes'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  event['notes'],
                                  style: TextStyle(color: AppTheme.deepCharcoal, fontSize: 11, fontStyle: FontStyle.italic),
                                ),
                              ),
                          ] else
                            const Text("Pending in protocol", style: TextStyle(fontSize: 10, color: AppTheme.deepCharcoal)),
                        ],
                      ),
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