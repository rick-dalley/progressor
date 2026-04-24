import 'package:flutter/material.dart';

class LikertQuestionTile extends StatefulWidget {
  final Map<String, dynamic> q;
  final Map<String, dynamic> template;
  final int? currentValue;
  final String? currentText; // For restoring C-SSRS notes
  final bool showWarning;
  final Function(int) onChanged;
  final Function(String, String)? onDescriptionChanged;

  const LikertQuestionTile({
    super.key,
    required this.q,
    required this.template,
    required this.currentValue,
    required this.onChanged,
    this.currentText,
    this.onDescriptionChanged,
    this.showWarning = false,
  });

  @override
  State<LikertQuestionTile> createState() => _LikertQuestionTileState();
}

class _LikertQuestionTileState extends State<LikertQuestionTile> {
  bool _isExpanded = false;

  Widget _buildVerticalOption(int index, String text, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => widget.onChanged(index),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? Colors.blueAccent : Colors.grey,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blueAccent.shade700 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int maxScore = widget.q['max_score'] ?? 3;
    final String type = widget.q['type']?.toString() ?? '';
    final String description = widget.q['description']?.toString() ?? '';

    final bool isBoolean = type.contains('boolean');
    final bool needsText = type.contains('text');
    final bool listOptions = type.contains('choice');

    final List<dynamic> headers = widget.template['column_headers'] as List<dynamic>;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: widget.showWarning ? Colors.red.withValues(alpha: 0.05) : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: widget.showWarning ? Colors.red : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.q['text'] ?? "",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.showWarning ? Colors.red.shade900 : Colors.black,
                  ),
                ),
              ),
              if (description.isNotEmpty)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.blueAccent,
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              if (widget.showWarning)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Icon(Icons.error_outline, color: Colors.red, size: 20),
                ),
            ],
          ),

          // Collapsible Description
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
                ),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.blueGrey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),

          const SizedBox(height: 8),

          // --- THE LOGIC SPLIT ---
          if (listOptions)
          // Branch 1: Vertical List (Choice)
            ...[
              Column(
                children: List.generate((widget.q['options'] as List).length, (index) {
                  final List<dynamic> options = widget.q['options'] ?? [];
                  final bool isSelected = widget.currentValue == index;
                  final Map<String, dynamic> optionMap = options[index] as Map<String, dynamic>;
                  final String optionText = optionMap['label']?.toString() ?? "";
                  return _buildVerticalOption(index, optionText, isSelected);
                }),
              ),
            ]
          else
          // Branch 2: Horizontal Row (Likert/Boolean)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(maxScore + 1, (score) {
                final int headerIndex = score + 1;
                String labelText = headerIndex < headers.length ? headers[headerIndex].toString() : "";
                final bool isSelected = widget.currentValue == score;

                if (isBoolean) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        label: Center(
                          child: Text(
                            labelText,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.blueAccent,
                        onSelected: (selected) => widget.onChanged(score),
                      ),
                    ),
                  );
                }

                // Standard Likert
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
                        onSelected: (selected) => widget.onChanged(score),
                      ),
                    ],
                  ),
                );
              }),
            ),

          // Narrative Field
          if (needsText) ...[
            const SizedBox(height: 12),
            const Text(
              "If yes, describe:",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 4),
            TextFormField(
              initialValue: widget.currentText,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Enter patient's sentence or phrase...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (val) {
                widget.onDescriptionChanged?.call(widget.q['id'] ?? "", val);
              },
            ),
          ],
        ],
      ),
    );
  }
}