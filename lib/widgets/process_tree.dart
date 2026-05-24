import 'package:flutter/material.dart';
import '../classes/database_manager.dart';
import '../classes/process_step.dart';

class ProcessTreeOverlay extends StatelessWidget {
  final String patientUuid;
  final int processStepId;
  final VoidCallback onProcessStepTapped;
  const ProcessTreeOverlay({
    super.key,
    required this.patientUuid,
    required this.processStepId,
    required this.onProcessStepTapped
  });

  @override
  Widget build(BuildContext context) {
    // bluePrint is the top-level List<ProcessStep> containing your 5 Phases (id: 1, 2, 3, 4, 5)
    final List<ProcessStep> bluePrint = DatabaseManager().processBlueprint;

    // Use your extension method to find the active leaf step node anywhere in the document tree
    ProcessStep? currentStepNode;
    for (final phase in bluePrint) {
      final match = phase.findNode(processStepId);
      if (match != null) {
        currentStepNode = match;
        break;
      }
    }

    final List<int> requiredNext = currentStepNode?.requiredNext ?? const [];
    final List<int> possibleNext = currentStepNode?.possibleNext ?? const [];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      itemCount: bluePrint.length,
      itemBuilder: (context, index) {
        // Each top-level item in bluePrint is a structural Phase (e.g., Medical Triage, Containment)
        final ProcessStep phase = bluePrint[index];
        final List<ProcessStep> stepChildren = phase.children;

        // Correctly evaluate if this phase contains the patient's active leaf step (e.g., id: 201)
        final bool containsActiveStep = stepChildren.any((step) => step.id == processStepId);

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          elevation: containsActiveStep ? 1 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: containsActiveStep ? Colors.deepPurple.shade300 : Colors.grey.shade200,
              width: containsActiveStep ? 1.5 : 1,
            ),
          ),
          child: ExpansionTile(
            // Auto-expands the phase the patient is currently in (e.g., Containment)
            initiallyExpanded: containsActiveStep,
            title: Text(
              phase.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: containsActiveStep ? Colors.deepPurple.shade800 : Colors.black87,
              ),
            ),
            subtitle: phase.longName.isNotEmpty && phase.longName != phase.name
                ? Text(
              phase.longName,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
                : null,
            shape: const Border(), // Clears standard Flutter tile border line injection
            collapsedShape: const Border(),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            children: stepChildren.map((step) {
              final bool isCurrentStep = step.id == processStepId;
              final bool isRequiredNext = requiredNext.contains(step.id);
              final bool isPossibleNext = possibleNext.contains(step.id);
              final bool isClickable = isRequiredNext || isPossibleNext;

              Color stepBorderColor = Colors.grey.shade200;
              Color stepBgColor = Colors.grey.shade50;
              VoidCallback? onStepSelected;

              if (isCurrentStep) {
                stepBorderColor = Colors.deepPurple.shade400;
                stepBgColor = Colors.white;
              } else if (isRequiredNext) {
                stepBorderColor = Colors.amber.shade600;
                stepBgColor = Colors.amber.withAlpha(5);
                onStepSelected = () => _handleStepSelection(context, step.id, currentStepNode);
              } else if (isPossibleNext) {
                stepBorderColor = Colors.teal.shade300;
                stepBgColor = Colors.teal.withAlpha(5);
                onStepSelected = () => _handleStepSelection(context, step.id, currentStepNode);
              }

              return Opacity(
                opacity: (isCurrentStep || isClickable) ? 1.0 : 0.5,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  decoration: BoxDecoration(
                    color: stepBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: stepBorderColor, width: isCurrentStep ? 1.5 : 1),
                  ),
                  child: InkWell(
                    onTap: onStepSelected,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(
                            isCurrentStep ? Icons.play_circle_filled_rounded : Icons.radio_button_off,
                            color: isCurrentStep
                                ? Colors.deepPurple
                                : (isRequiredNext ? Colors.amber.shade700 : (isPossibleNext ? Colors.teal : Colors.grey)),
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.name,
                                  style: TextStyle(
                                    fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.w600,
                                    color: isCurrentStep ? Colors.black87 : Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                                if (step.description.isNotEmpty && isCurrentStep) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    step.description,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.2),
                                  ),
                                ]
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isCurrentStep)
                            _buildChipBadge(text: "CURRENT", color: Colors.deepPurple)
                          else if (isRequiredNext)
                            _buildChipBadge(text: "REQUIRED", color: Colors.amber.shade800)
                          else if (isPossibleNext)
                              _buildChipBadge(text: "POSSIBLE", color: Colors.teal),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _handleStepSelection(BuildContext context, int targetStepId, ProcessStep? activeNode) async {
    final List<int> requiredNext = activeNode?.requiredNext ?? const [];
    final List<int> possibleNext = activeNode?.possibleNext ?? const [];

    final bool isValidRoute = requiredNext.contains(targetStepId) ||
        possibleNext.contains(targetStepId);

    // Guard: If the step is invalid, warn the user but STAY in the modal
    if (!isValidRoute) {
      debugPrint("UI Warning: Selection step $targetStepId violates blueprint tracks.");

      // Provide explicit feedback so the clinician knows why the tap did nothing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This step is out of sequence for the patient's current tracking pathway."),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return; // Exit early. The modal remains open, waiting for a valid choice.
    }

    // Proceed only if the route is verified as valid
    final bool isSaveSuccessful = await DatabaseManager().updatePatientProcessStep(
      uuid: patientUuid,
      targetStepId: targetStepId,
    );

    // Only dismiss the view if the database transaction was successful
    if (isSaveSuccessful && context.mounted) {
      onProcessStepTapped();
      Navigator.pop(context);
    } else if (context.mounted) {
      // Handle rare database save failures cleanly
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update patient step. Please try again."),
        ),
      );
    }
  }

  Widget _buildChipBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // Absolute 0-255 scale matching your exact usage
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(102), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.2),
      ),
    );
  }
}