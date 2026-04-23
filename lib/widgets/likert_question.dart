
import 'package:flutter/material.dart';

class LikertQuestionTile extends StatelessWidget {
  final Map<String, dynamic> q;
  final Map<String, dynamic> template;
  final int? currentValue;
  final bool showWarning;
  final Function(int) onChanged;

  const LikertQuestionTile({
    super.key,
    required this.q,
    required this.template,
    required this.currentValue,
    required this.onChanged,
    this.showWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final int maxScore = q['max_score'] ?? 3;

    // Safety check: Cast the headers as a List as seen in your GAD-7 JSON
    final List<dynamic> headers = template['column_headers'] as List<dynamic>;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: showWarning ? Colors.red.withValues(alpha:0.05) : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: showWarning ? Colors.red : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  q['text'] ?? "",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: showWarning ? Colors.red.shade900 : Colors.black,
                  ),
                ),
              ),
              if (showWarning)
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(maxScore + 1, (score) {
              // Your GAD-7 JSON has instructions at index 0.
              // Score 0 maps to Index 1 ("Not at all").
              // Score 1 maps to Index 2 ("Several days").
              final int headerIndex = score + 1;
              String labelText = "";

              if (headerIndex < headers.length) {
                labelText = headers[headerIndex].toString();
              }

              final bool isSelected = currentValue == score;

              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labelText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.1,
                        color: isSelected ? Colors.blueAccent : Colors.black54,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ChoiceChip(
                      label: Text(
                        score.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent,
                      onSelected: (selected) => onChanged(score),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}