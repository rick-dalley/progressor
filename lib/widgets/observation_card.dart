import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../screens/observation.dart';

/// Generates clean item blocks for the narrative feed tracking system
class ObservationCard extends StatelessWidget {
  final ObservationNote note;

  const ObservationCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        "${note.timestamp.day.toString().padLeft(2, '0')}/${note.timestamp.month.toString().padLeft(2, '0')}/${note.timestamp.year} • "
        "${note.timestamp.hour.toString().padLeft(2, '0')}:${note.timestamp.minute.toString().padLeft(2, '0')}";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.cardBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  note.authorName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                Text(timeStr, style: const TextStyle(fontSize: 12, color: AppTheme.darkSlate)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              note.authorRole,
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.deepCharcoal),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(height: 1, thickness: 0.5)),
            Text(note.content, style: const TextStyle(fontSize: 14, height: 1.45, color: AppTheme.darkSlate)),
          ],
        ),
      ),
    );
  }
}
