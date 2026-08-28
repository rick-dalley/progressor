import 'package:flutter/material.dart';

import '../classes/journey_stage.dart';

// Pulses every minute to update all timers in the app
// Add .asBroadcastStream() at the end
final Stream<DateTime> _heartbeat = Stream.periodic(
    const Duration(minutes: 1),
        (_) => DateTime.now()
).asBroadcastStream();

class CountdownTimer extends StatelessWidget {
  final DateTime admittedAt;
  // The outcome of the FIRST disposition decision only (see
  // patient_medical_card.dart) — null keeps the clock running; once set, the
  // dial stops counting and shows the fixed outcome icon instead, permanently
  // (a later ward→treatment transition must not un-swap it).
  final JourneyStage? firstDecisionOutcome;
  final VoidCallback? onTap;

  const CountdownTimer({
    super.key,
    required this.admittedAt,
    this.firstDecisionOutcome,
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    if (firstDecisionOutcome != null) {
      return IconButton(
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        icon: Icon(
          journeyStageIcons[firstDecisionOutcome],
          size: 24,
          color: journeyStageColors[firstDecisionOutcome],
        ),
        tooltip: '${journeyStageLabels[firstDecisionOutcome]} — disposition decided',
      );
    }

    return StreamBuilder<DateTime>(
      stream: _heartbeat,
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final elapsed = now.difference(admittedAt);
        // Legally, a physician must decide admit/transfer/release within 48 hours of
        // admission — this dial tracks that clock, not general time-in-department.
        final remaining = const Duration(hours: 48) - elapsed;
        final bool isOverdue = remaining <= Duration.zero;

        // Calculate percentage for the "pie" (expired / 48)
        final percentExpired = (elapsed.inMinutes / (48 * 60)).clamp(0.0, 1.0);

        // Color logic based on urgency: green until the last few hours, orange
        // through the last few hours, red inside the final hour, solid red with a
        // halo once the legal decision window has actually passed undisposed.
        Color timerColor = Colors.green;
        if (isOverdue || remaining.inMinutes <= 60) {
          timerColor = Colors.redAccent;
        } else if (remaining.inHours < 12) {
          timerColor = Colors.orangeAccent;
        }

        return IconButton(
          onPressed: onTap,
          visualDensity: VisualDensity.compact, // Matches your existing UI
          icon: SizedBox(
            height: 24,
            width: 24,
            child: Container(
              decoration: isOverdue
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.redAccent.withValues(alpha: 0.7), blurRadius: 8, spreadRadius: 2),
                      ],
                    )
                  : null,
              child: Stack(
                children: [
                  if (isOverdue)
                    const DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent))
                  else
                    CircularProgressIndicator(
                      value: percentExpired,
                      strokeWidth: 3,
                      color: timerColor,
                      backgroundColor: Colors.white10,
                    ),
                  Center(
                    child: Text(
                      "${remaining.inHours}h",
                      style: TextStyle(
                        color: isOverdue ? Colors.white : timerColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10, // Small enough to fit inside the 24px circle
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          tooltip: isOverdue
              ? 'Disposition decision overdue — admitted: ${admittedAt.hour}:${admittedAt.minute.toString().padLeft(2, "0")}'
              : 'Admitted: ${admittedAt.hour}:${admittedAt.minute.toString().padLeft(2, "0")}',
        );

      },
    );
  }
}