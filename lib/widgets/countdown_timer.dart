import 'package:flutter/material.dart';


// Pulses every minute to update all timers in the app
// Add .asBroadcastStream() at the end
final Stream<DateTime> _heartbeat = Stream.periodic(
    const Duration(minutes: 1),
        (_) => DateTime.now()
).asBroadcastStream();

class CountdownTimer extends StatelessWidget {
  final DateTime admittedAt;
  final VoidCallback? onTap;

  const CountdownTimer({
    super.key,
    required this.admittedAt,
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _heartbeat,
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final elapsed = now.difference(admittedAt);
        final remaining = const Duration(hours: 48) - elapsed;

        // Calculate percentage for the "pie" (expired / 48)
        final percentExpired = (elapsed.inMinutes / (48 * 60)).clamp(0.0, 1.0);

        // Color logic based on urgency
        Color timerColor = Colors.green;
        if (remaining.inHours < 6) {
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
            child: Stack(
              children: [
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
                      color: timerColor, // Matches the pie slice color (Green/Orange/Red)
                      fontWeight: FontWeight.bold,
                      fontSize: 10, // Small enough to fit inside the 24px circle
                    ),
                  ),
                ),
              ],
            ),
          ),
          tooltip: 'Admitted: ${admittedAt.hour}:${admittedAt.minute.toString().padLeft(2, "0")}',
        );

      },
    );
  }
}