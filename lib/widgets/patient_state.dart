import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';


class PatientStateFlag {
  final String label;
  final int stateId;
  final bool isComplete;
  PatientStateFlag({required this.stateId, required this.label, required this.isComplete});

}

Map<int, IconData> flagIcons = {1:Symbols.cardiology, 2:Symbols.respiratory_rate};
Map<int, Color> flagColors = {1:Colors.green, 2:Colors.blue};

class PatientStateWidget extends StatefulWidget {
  final List<String> prompts; // [previous, current, next]
  final List<PatientStateFlag> flags;

  const PatientStateWidget({
    super.key,
    required this.prompts,
    required this.flags,
  });

  @override
  State<PatientStateWidget> createState() => _PatientStateWidgetState();
}

class _PatientStateWidgetState extends State<PatientStateWidget> {
  late PageController _promptController;

  @override
  void initState() {
    super.initState();
    // Start on index 1 (the 'current' prompt)
    _promptController = PageController(initialPage: 1, viewportFraction: 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60, // Fixed height for the row
      child: Row(
        children: [
          // Left Side: 50% width for the scrollable prompts
          SizedBox(height: 16,),
          Expanded(
            flex: 1,
            child: PageView.builder(
              controller: _promptController,
              itemCount: widget.prompts.length,
              itemBuilder: (context, index) {
                return Center(
                  child: Text(
                    widget.prompts[index],
                    style: TextStyle(fontWeight: index == 1 ? FontWeight.bold : FontWeight.normal),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          // Right Side: 50% width for horizontal icon list
          Expanded(
            flex: 1,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.flags.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final flag = widget.flags[index];
                return Icon(
                  flagIcons[flag.stateId],
                  color: flag.isComplete ? flagColors[flag.stateId] : Colors.grey,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StatusFlag {
  final IconData icon;
  final bool isCompleted;
  StatusFlag({required this.icon, required this.isCompleted});
}