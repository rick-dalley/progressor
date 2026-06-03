import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/phase_state_handlers.dart';

import '../app_theme.dart';

Map<PhaseIdentifier, IconData> patientStateIcons = {
  PhaseIdentifier.arrival: Symbols.emergency,
  PhaseIdentifier.registration: Symbols.conditions,
  PhaseIdentifier.triage: Symbols.diagnosis,
  PhaseIdentifier.intervention: Symbols.stethoscope,
  PhaseIdentifier.holding: Symbols.bed,
  PhaseIdentifier.disposition: Symbols.arrow_split,
};


class PatientStateWidget extends StatefulWidget {
  final List<String> prompts; // [previous, current, next]

  const PatientStateWidget({super.key, required this.prompts});

  @override
  State<PatientStateWidget> createState() => _PatientStateWidgetState();
}

class _PatientStateWidgetState extends State<PatientStateWidget> {
  late PageController _promptController;
  late Phase activePhase;
  late IconData activeIcon;
  late List<String> prompts = widget.prompts;

  @override
  void initState() {
    super.initState();
    // Start on index 1 (the 'current' prompt)
    int randomNumber = Random().nextInt(6);
    PhaseIdentifier activeStatePhase = PhaseIdentifier.values[randomNumber];
    activeIcon = patientStateIcons[activeStatePhase] ?? Symbols.local_police;
    activePhase = PhasesFactory.instance.getPhase(activeStatePhase);
    prompts[1] = activePhase.label;
    _promptController = PageController(initialPage: 1, viewportFraction: 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final List<Event> eventList = activePhase.events?.values.toList() ?? [];
    return SizedBox(
      height: 60, // Fixed height for the row
      child: Row(
        children: [
          // Left Side: 50% width for the scrollable prompts
          SizedBox(height: 16),
          Expanded(
            flex: 1,
            child: PageView.builder(
              controller: _promptController,
              itemCount: widget.prompts.length,
              itemBuilder: (context, index) {
                return Center(
                  child: Row(
                    children: [
                      Icon(activeIcon),
                      const SizedBox(width: 8), // Added a little spacing for a cleaner UI
                      Expanded( // This is the crucial fix
                        child: Text(
                          widget.prompts[index],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Right Side: 50% width for horizontal icon list
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: eventList.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final event = eventList[index];
                  final IconData iconData = AppTheme.eventIcons[event.id] ?? Symbols.unknown_document;
                  return SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(
                      iconData,
                      size: 32,
                      color: Colors.green,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
