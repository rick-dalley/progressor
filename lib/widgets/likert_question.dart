import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/assessment_logic.dart';

class LikertQuestionTile extends StatefulWidget {
  final Map<String, dynamic> q;
  final Map<String, dynamic> template;
  final AssessmentAnswer? currentAnswer;
  final bool showWarning;
  final Function(int)? onChanged; // Made nullable for read-only support
  final Function(String, String)? onDescriptionChanged;

  const LikertQuestionTile({
    super.key,
    required this.q,
    required this.template,
    required this.currentAnswer,
    required this.onChanged,
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
        onTap: widget.onChanged != null ? () => widget.onChanged!(index) : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.clinicalCyan.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.clinicalCyan : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppTheme.clinicalCyan : Colors.grey,
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
                    color: isSelected ? AppTheme.clinicalCyan : Colors.black87,
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
    final String answerType = widget.q['type']?.toString() ?? '';
    final String description = widget.q['description']?.toString() ?? '';

    final bool isBoolean = answerType.contains('boolean');
    final bool needsText = answerType.contains('text');
    final bool listOptions = answerType.contains('choice');

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
                    color: AppTheme.clinicalCyan, // Changed from blueAccent
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
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
                  color: AppTheme.clinicalCyan.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.clinicalCyan.withValues(alpha: 0.1)),
                ),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.clinicalCyan,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),

          const SizedBox(height: 8),

          if (listOptions)
            Column(
              children: List.generate((widget.q['options'] as List).length, (index) {
                final List<dynamic> options = widget.q['options'] ?? [];
                final bool isSelected = widget.currentAnswer?.value == index;
                final Map<String, dynamic> optionMap = options[index] as Map<String, dynamic>;
                final String optionText = optionMap['label']?.toString() ?? "";
                return _buildVerticalOption(index, optionText, isSelected);
              }),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(maxScore + 1, (score) {
                final int headerIndex = score + 1;
                String labelText = headerIndex < headers.length ? headers[headerIndex].toString() : "";
                final bool isSelected = widget.currentAnswer?.value == score;

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
                        selectedColor: AppTheme.clinicalCyan, // FIX: Use Theme Color
                        checkmarkColor: Colors.white,
                        onSelected: widget.onChanged != null
                            ? (selected) => widget.onChanged!(score)
                            : null,
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
                          color: isSelected ? AppTheme.clinicalCyan : Colors.black54, // FIX
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ChoiceChip(
                        label: Text(
                          score.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.clinicalCyan, // FIX
                        checkmarkColor: Colors.white,
                        onSelected: widget.onChanged != null
                            ? (selected) => widget.onChanged!(score)
                            : null,
                      ),
                    ],
                  ),
                );
              }),
            ),

          if (needsText) ...[
            const SizedBox(height: 12),
            const Text(
              "If yes, describe:",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.clinicalCyan),
            ),
            const SizedBox(height: 4),
            TextFormField(
              enabled: widget.onChanged != null, // Disable if read-only
              initialValue: widget.currentAnswer?.text,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.clinicalCyan),
                ),
              ),
              onChanged: (val) => widget.onDescriptionChanged?.call(widget.q['id'] ?? "", val),
            ),
          ],
        ],
      ),
    );
  }
}