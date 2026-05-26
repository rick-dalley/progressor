import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/process_category.dart';
import '../classes/process_step.dart';

// Represents the macro phase block
class ProcessPhaseRail extends StatelessWidget {
  final int currentPhaseId;
  final Map<int, ProcessStep> phases;

  const ProcessPhaseRail({super.key, required this.currentPhaseId, required this.phases});

  @override
  Widget build(BuildContext context) {
    return Row(
      // 👈 FIXED: Route through .values to map the data models directly into your Widgets
      children: phases.values.map<Widget>((phase) {
        // Now direct dot-notation property lookups work perfectly
        final isCompleted = phase.id < currentPhaseId;
        final isActive = phase.id == currentPhaseId;

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
  final ProcessStep currentStep;
  final bool isConcurrent;
  final String criticality;
  final String type;
  final bool isCurrentStep;
  final bool isTerminalClosure;
  final bool isFirstInPhase;
  final bool isFirstInProcess;

  const CompactStepBadge({
    super.key,
    required this.currentStep,
    required this.isConcurrent,
    required this.criticality,
    required this.type,
    this.isCurrentStep = false,
    this.isTerminalClosure = false,
    this.isFirstInPhase = false,
    this.isFirstInProcess = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color schemes based on execution states
    Color textColor = isCurrentStep ? Colors.white : Colors.black;
    Color backgroundColor = isCurrentStep ? AppTheme.processStepActive : AppTheme.canvasColor;
    Color borderColor = isCurrentStep ? AppTheme.deepCharcoal : AppTheme.processStepPlain;

    if (isTerminalClosure) {
      backgroundColor = isCurrentStep ? AppTheme.processStepTerminal : AppTheme.processStepTerminal.withAlpha(96);
      textColor = isCurrentStep ? Colors.white : AppTheme.processStepTerminal;
      borderColor = AppTheme.processStepTerminal;
    } else {
      if (isFirstInProcess) {
        backgroundColor = isCurrentStep ? AppTheme.processStepPrimary : AppTheme.processStepPrimary.withAlpha(96);
        textColor = isCurrentStep ? Colors.white : AppTheme.processStepPrimary;
        borderColor = AppTheme.processStepPrimary.withAlpha(96);
      } else {
        backgroundColor = isCurrentStep ? AppTheme.processStepActive : AppTheme.canvasColor;
        textColor = isCurrentStep ? Colors.white : Colors.black;
        borderColor = Colors.grey;
      }
    }


    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        // Shape Transition: Terminal targets render as a strict rounded pill
        borderRadius: BorderRadius.circular(isTerminalClosure ? 20.0 : 6.0),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Text(
              currentStep.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // This will now trigger reliably
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12.0),
            ),
          ),
          // Append trailing validation mark to clearly sign off on action completion
          if (isTerminalClosure) ...[
            const SizedBox(width: 4.0),
            Icon(Icons.check_circle_outline, size: 14.0, color: textColor),
          ],
        ],
      ),
    );
  }
}

class HorizontalStepViewer extends StatefulWidget {
  final ProcessStep? thisStep;
  final ProcessStep? previousStep;
  final Map<int, ProcessStep>? siblings;

  const HorizontalStepViewer({super.key, required this.thisStep, required this.previousStep, required this.siblings});

  @override
  State<HorizontalStepViewer> createState() => _HorizontalStepViewerState();
}

class _HorizontalStepViewerState extends State<HorizontalStepViewer> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveStep());
  }

  @override
  void didUpdateWidget(HorizontalStepViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thisStep?.id != widget.thisStep?.id) {
      _scrollToActiveStep();
    }
  }

  void _scrollToActiveStep() {
    if (!_scrollController.hasClients || widget.siblings == null || widget.thisStep == null) return;

    final stepList = widget.siblings!.values.toList();
    List<int> concurrentStepIds = [];

    double calculatedXOffset = 0.0;
    bool targetFound = false;

    for (final stepItem in stepList) {
      final flags = ProcessFlags.fromProcessStep(stepItem);

      if (flags.branches) {
        concurrentStepIds.addAll(stepItem.requiredNext);
      }

      final bool isConcurrent = concurrentStepIds.contains(stepItem.id);

      if (isConcurrent) {
        concurrentStepIds.remove(stepItem.id);
      }

      // 👈 STOP CALCULATION: If this is our target step, we have our exact X position
      if (stepItem.id == widget.thisStep!.id) {
        targetFound = true;
        break;
      }

      // Progress the layout tracker forward ONLY when passing true sequential base steps
      if (!isConcurrent) {
        calculatedXOffset += 125.0; // Matches your horizontal baseline stride exactly
      }
    }

    if (targetFound) {
      // Subtract a small buffer (e.g., 20.0 to 40.0) if you want the active card
      // to sit slightly padded from the left edge of the screen instead of hard-flush.
      double finalScrollTarget = calculatedXOffset;

      _scrollController.animateTo(
        finalScrollTarget.clamp(0.0, _scrollController.position.maxScrollExtent),
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
    final Map<int, ProcessStep> stepsMap = widget.siblings ?? {};
    List<int> concurrentStepIds = [];
    return SizedBox(
      height: 64.0,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.black, Colors.black.withValues(alpha: 0.95), Colors.black.withValues(alpha: 0.0)],
            stops: const [0.0, 0.88, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(right: 32.0, bottom: 16.0),
          child: Builder(
            builder: (context) {
              final List<ProcessStep> stepsList = stepsMap.values.toList();
              List<int> concurrentStepIds = [];

              double xOffset = 128;
              int stackDepthCounter = 0;
              double leftPosition = xOffset * -1;
              double topPosition = 0;

              return SizedBox(
                width: (stepsList.length * 136.0),
                height: 76.0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: stepsList.map((stepItem) {
                    final bool isCurrentStep = stepItem.id == widget.thisStep?.id;
                    final flags = ProcessFlags.fromProcessStep(stepItem);
                    final String computedCriticality = isCurrentStep ? 'warning' : 'inactive';

                    if (flags.branches) {
                      concurrentStepIds.addAll(stepItem.requiredNext);
                    }

                    final bool isConcurrent = concurrentStepIds.contains(stepItem.id);

                    if (isConcurrent) {
                      concurrentStepIds.remove(stepItem.id);
                      if (stackDepthCounter == 0) {
                        leftPosition += xOffset;
                      }
                      leftPosition += (8.0 * stackDepthCounter);
                      topPosition += (6.0 * stackDepthCounter);
                      stackDepthCounter = 1;
                    } else {
                      leftPosition += xOffset;
                      topPosition = 0;
                      stackDepthCounter = 0;
                    }

                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      left: leftPosition,
                      top: topPosition,
                      child: SizedBox(
                        width: 130.0,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: CompactStepBadge(
                            currentStep: stepItem,
                            isConcurrent: isConcurrent,
                            criticality: computedCriticality,
                            type: stepItem.requirement.isNotEmpty ? stepItem.requirement.first : 'general',
                            isCurrentStep: isCurrentStep,
                            isTerminalClosure: flags.isTerminal,
                            isFirstInProcess: flags.isPrimary,
                            isFirstInPhase: flags.isFirst,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
