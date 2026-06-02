import 'package:flutter/material.dart';

class CalendarHeatMap extends StatelessWidget {
  final Map<DateTime, int> actionCounts;

  const CalendarHeatMap({super.key, required this.actionCounts});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, // 7 days a week
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: 30, // Show last 30 days
      itemBuilder: (context, index) {
        final date = DateTime.now().subtract(Duration(days: 30 - index));
        final dateKey = DateTime(date.year, date.month, date.day);
        final count = actionCounts[dateKey] ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: _getColorForCount(count),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  Color _getColorForCount(int count) {
    if (count == 0) return Colors.grey.shade200;
    if (count < 3) return Colors.blue.shade200;
    if (count < 6) return Colors.blue.shade400;
    return Colors.blue.shade800;
  }
}