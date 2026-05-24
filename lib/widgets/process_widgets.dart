import 'package:flutter/material.dart';
import '../classes/database_manager.dart';
import '../classes/process_step.dart';

// Represents the macro phase block
class ProcessPhaseRail extends StatelessWidget {
  final int activePhaseId;
  final List<dynamic> phases;

  const ProcessPhaseRail({super.key, required this.activePhaseId, required this.phases});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: phases.map((phase) {
        // Use direct dot-notation property lookups instead of bracket strings
        final isCompleted = phase.id < activePhaseId;
        final isActive = phase.id == activePhaseId;

        return Expanded(
          flex: isActive ? 2 : 1, // Give the active phase extra real estate
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            height: 6.0,
            decoration: BoxDecoration(
              color: isActive ? Colors.blue.shade600 : (isCompleted ? Colors.green.shade400 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(3.0),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Micro step badge layout to render right below the tracking rail
class CompactStepBadge extends StatelessWidget {
  final String stepName;
  final String criticality;
  final String type;
  final bool isTerminalClosure;

  const CompactStepBadge({
    super.key,
    required this.stepName,
    required this.criticality,
    required this.type,
    this.isTerminalClosure = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color schemes based on execution states
    Color backgroundColor = Colors.grey.shade100;
    Color textColor = Colors.black87;

    if (isTerminalClosure) {
      if (criticality == 'terminal_active') {
        backgroundColor = Colors.teal.shade700;
        textColor = Colors.white;
      } else if (criticality == 'terminal_available') {
        backgroundColor = Colors.teal.shade50;
        textColor = Colors.teal.shade900;
      }
    } else {
      // Fall back to standard warning / high / standard color mappings
      if (criticality == 'warning') {
        backgroundColor = Colors.orange.shade600;
        textColor = Colors.white;
      } // ... other states
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        // Shape Transition: Terminal targets render as a strict rounded pill
        borderRadius: BorderRadius.circular(isTerminalClosure ? 20.0 : 6.0),
        border: isTerminalClosure && criticality == 'terminal_available'
            ? Border.all(color: Colors.teal.shade300, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stepName,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
            ),
          ),
          // Append trailing validation mark to clearly sign off on action completion
          if (isTerminalClosure) ...[
            const SizedBox(width: 4.0),
            Icon(
              Icons.check_circle_outline,
              size: 14.0,
              color: textColor,
            ),
          ],
        ],
      ),
    );
  }
}

class HorizontalStepViewer extends StatefulWidget {
  final List<dynamic> activePhaseStepsList;
  final int dynamicPatientStepId;

  const HorizontalStepViewer({
    super.key,
    required this.activePhaseStepsList,
    required this.dynamicPatientStepId,
  });

  @override
  State<HorizontalStepViewer> createState() => _HorizontalStepViewerState();
}

class _HorizontalStepViewerState extends State<HorizontalStepViewer> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Schedule an execution frame pass, then scroll to the active item position smoothly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveStep();
    });
  }

  @override
  void didUpdateWidget(HorizontalStepViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the step changed while the card was active, smoothly re-center the view
    if (oldWidget.dynamicPatientStepId != widget.dynamicPatientStepId) {
      _scrollToActiveStep();
    }
  }

  void _scrollToActiveStep() {
    if (!_scrollController.hasClients) return;

    // Standardize and chronologically sort the internal working list to find the true index
    final List<ProcessStep> typedSteps = widget.activePhaseStepsList
        .map((item) => item as ProcessStep)
        .toList();
    typedSteps.sort((a, b) => a.id.compareTo(b.id));

    // Find where our active item is sitting in the sorted layout sequence
    final int activeIndex = typedSteps.indexWhere((step) => step.id == widget.dynamicPatientStepId);

    // Fixed strict type safety validation check
    if (activeIndex != -1) {
      // Estimate the scroll position (approx. 125px per badge width + right padding offset)
      double estimatedOffset = activeIndex * 125.0;

      _scrollController.animateTo(
        estimatedOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild the registry matrix from the global blueprint layout
    final Map<int, ProcessStep> registry = {};
    for (final phase in DatabaseManager().processBlueprint) {
      registry.addAll(phase.generateRegistry());
    }

    final List<ProcessStep> typedSteps = widget.activePhaseStepsList
        .map((item) => item as ProcessStep)
        .toList();

    // FIXED: Sorted chronologically by sequence ID so elements maintain stable natural order
    typedSteps.sort((a, b) => a.id.compareTo(b.id));

    final ProcessStep? currentLocusStep = registry[widget.dynamicPatientStepId];

    return SizedBox(
      height: 38.0,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.black,
              Colors.black.withValues(alpha: 0.95),
              Colors.black.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.88, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          controller: _scrollController, // Connected automated tracking controller
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(right: 32.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: typedSteps.map<Widget>((stepItem) {
              final bool isCurrentStep = stepItem.id == widget.dynamicPatientStepId;

              // Evaluate Terminal Signature: next points explicitly to 0 with no alternatives
              final bool isTerminalStep = stepItem.requiredNext.length == 1 &&
                  stepItem.requiredNext.first == 0;

              String computedCriticality;

              if (isCurrentStep) {
                computedCriticality = isTerminalStep ? 'terminal_active' : 'warning';
              } else if (currentLocusStep != null && currentLocusStep.requiredNext.contains(stepItem.id)) {
                computedCriticality = isTerminalStep ? 'terminal_available' : 'high';
              } else if (currentLocusStep != null && currentLocusStep.possibleNext.contains(stepItem.id)) {
                computedCriticality = 'standard';
              } else {
                computedCriticality = 'inactive';
              }

              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: CompactStepBadge(
                  stepName: stepItem.name,
                  criticality: computedCriticality,
                  type: stepItem.requirement.isNotEmpty ? stepItem.requirement.first : 'general',
                  isTerminalClosure: isTerminalStep,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}