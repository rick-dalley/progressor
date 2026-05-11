import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';

class ProcessPathway extends StatelessWidget {
  final String processKey;    // maps to 'status' in patient JSON
  final String currentStatus; // maps to 'path' in patient JSON

  const ProcessPathway({
    super.key,
    required this.processKey,
    required this.currentStatus,
  });
  @override
  Widget build(BuildContext context) {
    final allProcesses = DatabaseManager().processMaps;
    final activeProcess = allProcesses[processKey] ?? {};

    List<String> stages = [];
    if (activeProcess['steps_json'] != null) {
      // This decodes into a List<String>
      stages = List<String>.from(jsonDecode(activeProcess['steps_json']));
    }

    if (stages.isEmpty) return const SizedBox.shrink();

    // Demo logic
    final int demoStep = Random().nextInt(stages.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PATHWAY: ${activeProcess['label']?.toUpperCase() ?? ''}",
          style: GoogleFonts.inclusiveSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.deepLogicViolet,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(stages.length, (index) {
            // FIX: Access the string directly instead of ['label']
            final String label = stages[index];

            bool isCompleted = index < demoStep;
            bool isCurrent = index == demoStep;

            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle :
                        (isCurrent ? Icons.play_circle : Icons.circle_outlined),
                        size: 24,
                        color: isCompleted
                            ? Colors.green.shade400
                            : (isCurrent ? AppTheme.deepLogicViolet : Colors.grey.shade800),
                      ),
                      if (index < stages.length - 1)
                        Expanded(
                          child: Container(
                            height: 1.5,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            color: isCompleted ? Colors.green.shade400 : Colors.grey.shade900,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: isCurrent ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}