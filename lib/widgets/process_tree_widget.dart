// import 'package:flutter/material.dart';
// import '../app_theme.dart';
// import '../classes/database_manager.dart';
// import '../classes/process_step.dart';
//
// class ProcessTreeOverlay extends StatelessWidget {
//   final String patientUuid;
//   final int processStepId;
//   final VoidCallback onProcessStepTapped;
//
//   const ProcessTreeOverlay({
//     super.key,
//     required this.patientUuid,
//     required this.processStepId,
//     required this.onProcessStepTapped,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final Map<int, ProcessStep> bluePrint = DatabaseManager().processBlueprint;
//
//     ProcessStep? currentStepNode = DatabaseManager().getProcessStepForId(processStepId);
//     final List<int> requiredNext = currentStepNode?.requiredNext ?? const [];
//     final List<int> possibleNext = currentStepNode?.possibleNext ?? const [];
//
//     // Convert the top-level phase map values to a list for positional index rendering
//     final List<ProcessStep> phasesList = bluePrint.values.toList();
//
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
//       itemCount: phasesList.length,
//       itemBuilder: (context, index) {
//         final ProcessStep phase = phasesList[index];
//
//         // 👈 UPDATED: children is now a Map<int, ProcessStep>
//         final Map<int, ProcessStep> stepChildrenMap = phase.children;
//
//         // 👈 UPDATED: Direct O(1) map lookup replaces linear collection .any() scans
//         final bool containsActiveStep = stepChildrenMap.containsKey(processStepId);
//
//         return Card(
//           margin: const EdgeInsets.only(bottom: 12.0),
//           elevation: containsActiveStep ? 1 : 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//             side: BorderSide(
//               color: containsActiveStep ? AppTheme.processStepPrimary.withAlpha(128) : AppTheme.processStepPrimary,
//               width: containsActiveStep ? 1.5 : 1,
//             ),
//           ),
//           child: ExpansionTile(
//             initiallyExpanded: containsActiveStep,
//             title: Text(
//               phase.name,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 15,
//                 color: containsActiveStep ? Colors.deepPurple.shade800 : Colors.black87,
//               ),
//             ),
//             // Fallback checking utilizing direct property dot-notation
//             subtitle: (phase.requirement.isNotEmpty && phase.requirement.first != phase.name)
//                 ? Text(phase.requirement.first, style: const TextStyle(fontSize: 12, color: Colors.grey))
//                 : null,
//             shape: const Border(),
//             collapsedShape: const Border(),
//             childrenPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
//             // Route through .values to loop over the child map steps safely
//             children: stepChildrenMap.values.map((step) {
//               final bool isCurrentStep = step.id == processStepId;
//               final bool isRequiredNext = requiredNext.contains(step.id);
//               final bool isPossibleNext = possibleNext.contains(step.id);
//               final bool isClickable = isRequiredNext || isPossibleNext;
//               Color fontColor = AppTheme.processStepPlain;
//               Color stepBorderColor = AppTheme.processStepPlain;
//               Color stepBgColor = AppTheme.canvasColor;
//               VoidCallback? onStepSelected;
//
//               if (isCurrentStep) {
//                 stepBorderColor = AppTheme.processStepActive;
//                 stepBgColor = Colors.white;
//                 fontColor = AppTheme.processStepActive;
//               } else if (isRequiredNext) {
//                 stepBorderColor = AppTheme.processStepRequired;
//                 stepBgColor = AppTheme.processStepRequired.withAlpha(5);
//                 fontColor = AppTheme.processStepRequired;
//                 onStepSelected = () => _handleStepSelection(context, step.id, currentStepNode);
//               } else if (isPossibleNext) {
//                 stepBorderColor = AppTheme.processStepPossible;
//                 stepBgColor = AppTheme.processStepPossible.withAlpha(5);
//                 fontColor = AppTheme.processStepPossible;
//                 onStepSelected = () => _handleStepSelection(context, step.id, currentStepNode);
//               }
//
//               return Opacity(
//                 opacity: (isCurrentStep || isClickable) ? 1.0 : 0.5,
//                 child: Container(
//                   margin: const EdgeInsets.only(bottom: 8.0),
//                   decoration: BoxDecoration(
//                     color: stepBgColor,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: stepBorderColor, width: isCurrentStep ? 1.5 : 1),
//                   ),
//                   child: InkWell(
//                     onTap: onStepSelected,
//                     borderRadius: BorderRadius.circular(8),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12.0),
//                       child: Row(
//                         children: [
//                           Icon(
//                             isCurrentStep ? Icons.play_circle_filled_rounded : Icons.radio_button_off,
//                             color: fontColor,
//                             size: 16,
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   step.name,
//                                   style: TextStyle(
//                                     fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.w600,
//                                     color: fontColor,
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   step.description,
//                                   style: TextStyle(
//                                       fontSize: 11,
//                                       fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.w600,
//                                       color:fontColor,
//                                       height: 1.2),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           if (isCurrentStep)
//                             _buildChipBadge(text: "CURRENT", color: AppTheme.processStepActive)
//                           else if (isRequiredNext)
//                             _buildChipBadge(text: "REQUIRED", color: AppTheme.processStepRequired)
//                           else if (isPossibleNext)
//                             _buildChipBadge(text: "POSSIBLE", color: AppTheme.processStepPossible),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         );
//       },
//     );
//   }
//
//   void _handleStepSelection(BuildContext context, int targetStepId, ProcessStep? activeNode) async {
//     final List<int> requiredNext = activeNode?.requiredNext ?? const [];
//     final List<int> possibleNext = activeNode?.possibleNext ?? const [];
//
//     final bool isValidRoute = requiredNext.contains(targetStepId) || possibleNext.contains(targetStepId);
//
//     if (!isValidRoute) {
//       debugPrint("UI Warning: Selection step $targetStepId violates blueprint tracks.");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("This step is out of sequence for the patient's current tracking pathway."),
//           duration: Duration(seconds: 2),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }
//
//     final bool isSaveSuccessful = await DatabaseManager().updatePatientProcessStep(
//       uuid: patientUuid,
//       targetStepId: targetStepId,
//     );
//
//     if (isSaveSuccessful && context.mounted) {
//       onProcessStepTapped();
//       Navigator.pop(context);
//     } else if (context.mounted) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Failed to update patient step. Please try again.")));
//     }
//   }
//
//   Widget _buildChipBadge({required String text, required Color color}) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
//       decoration: BoxDecoration(
//         color: color.withAlpha(26),
//         borderRadius: BorderRadius.circular(4),
//         border: Border.all(color: color.withAlpha(102), width: 0.5),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.2),
//       ),
//     );
//   }
// }
