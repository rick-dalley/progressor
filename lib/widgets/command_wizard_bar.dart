import 'package:flutter/material.dart';

import 'assessment_wizard.dart';

class CommandWizardBar extends StatelessWidget {
  final AssessmentWizard wizard;
  final Function(String) onAdvance;
  final VoidCallback onBack;

  const CommandWizardBar({super.key, required this.wizard, required this.onAdvance, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final currentNode = wizard.currentNode;
    final options = currentNode['options'] as List;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Colors.grey, width: 2)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          // 1. Breadcrumb Strip (Top of Wizard)
          _buildBreadcrumbs(),

          // 2. Question Area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              currentNode['question'] ?? "No question",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),

          // 3. Action Buttons (Responsive Grid)
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 3,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: options
                  .map((opt) => ElevatedButton(onPressed: () => onAdvance(opt['label']), child: Text(opt['label'])))
                  .toList(),
            ),
          ),

          // 4. Navigation Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: onBack, child: const Text("Back")),
              Text("Step ${wizard.history.length + 1}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: wizard.history.length,
        separatorBuilder: (_, _) => const Icon(Icons.chevron_right, size: 16),
        itemBuilder: (context, index) {
          return Text(
            wizard.history[index]['node'].toString(),
            style: const TextStyle(fontSize: 12, color: Colors.blue),
          );
        },
      ),
    );
  }
}
