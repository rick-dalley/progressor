import 'package:flutter/material.dart';

class TriageHistoryDrawer extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final Function(int) onJump;

  const TriageHistoryDrawer({super.key, required this.history, required this.onJump});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            child: Center(
              child: Text("Assessment Audit Trail", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: history.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final entry = history[index];
                return ListTile(
                  leading: CircleAvatar(child: Text("${index + 1}")),
                  title: Text(entry['question'] ?? "Step ${index + 1}"),
                  subtitle: Text("Selected: ${entry['answer']}"),
                  onTap: () {
                    onJump(index);
                    Navigator.pop(context); // Close the drawer
                  },
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Tap a step to modify the triage path",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
