import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:triage/widgets/vitals_trend_gaph.dart';

import '../app_theme.dart';
import '../classes/database_manager.dart';

class VitalsHistoryView extends StatelessWidget {
  final String patientUuid;

  const VitalsHistoryView({super.key, required this.patientUuid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseManager().getVitalsForPatient(patientUuid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final history = snapshot.data!;

        return Container(
          // Using your preferred 70% height logic
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "CLINICAL TRENDS",
                style: GoogleFonts.inclusiveSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              // The graph widget we built earlier
              VitalsTrendGraph(history: history),

              const Divider(height: 30),

              Text(
                "VITALS HISTORY",
                style: GoogleFonts.inclusiveSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              const Divider(),

              Expanded(
                child: ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final record = history[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "${record['systolic']}/${record['diastolic']} BP | ${record['pulse']} Pulse",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Recorded: ${record['recorded_at']}"),
                      trailing: Text(
                        "${record['temperature']}°C",
                        style: TextStyle(
                          color: AppTheme.vitalsTemp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}