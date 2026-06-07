import 'package:flutter/material.dart';
import 'package:triage/classes/patient.dart';
import 'package:triage/widgets/acuity_widget.dart';
import '../app_theme.dart';
import '../classes/acuity.dart';
import '../widgets/acuity_change.dart';

class AcuityViewer extends StatefulWidget {
  final String patientUuid;
  final Acuity acuity;
  final PatientController patientController;
  final VoidCallback onAcuityUpdated;
  const AcuityViewer({super.key, required this.patientUuid, required this.acuity, required this.patientController, required this.onAcuityUpdated});

  @override
  State<StatefulWidget> createState() => AcuityViewerState();
}

class AcuityViewerState extends State<AcuityViewer> {
  bool _showAlternatives = false;
  late Acuity acuity;

  @override
  void initState() {
    super.initState();
  }

  @override

  Widget build(BuildContext context) {

    final double notchPadding = MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top : 47.0;
    return ListenableBuilder(
        listenable: widget.patientController, // Point it at the controller you passed in
        builder: (context, child){
          final currentLevel = widget.patientController.patient.acuityLevel;
          final acuity = AcuityFactory.instance.getAcuity(level: currentLevel);
          final otherAcuities = AcuityFactory.instance.getAllAcuitiesExcept(currentLevel);
          int initialIndex = otherAcuities.indexWhere((a) => a.level.index > acuity!.level.index);
          if (initialIndex == -1) initialIndex = otherAcuities.length - 1;
          final PageController controller = PageController(initialPage: initialIndex, viewportFraction: 0.85);
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(padding: MediaQuery.of(context).padding.copyWith(top: notchPadding)),
            child: Scaffold(
              appBar: AppBar(
                title: const Text("Acuity"),
                leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        _showAlternatives = !_showAlternatives;
                      });
                    },
                  ),
                ],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    // TOP PANE: 50% Height when showing alternatives - Scrollable for the full clinical details
                    Expanded(
                      child: _showAlternatives
                          ? Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: AcuityWidget(acuity: acuity!),
                        ),
                      )
                          : AcuityWidget(acuity: acuity!),
                    ),

                    // BOTTOM PANE: 50% Height - The Carousel
                    if (_showAlternatives)
                      Expanded(
                        child: Container(
                          color: AppTheme.lightTheme.scaffoldBackgroundColor,
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text("PROPOSED ALTERNATIVES", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: PageView.builder(
                                  controller: controller,
                                  itemCount: otherAcuities.length,
                                  itemBuilder: (context, index) {
                                    return InkWell(
                                      child: Card (
                                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        child: AcuityWidget(acuity: otherAcuities[index]),
                                      ),
                                      onTap: () async {
                                        // 1. Show the confirmation dialog and wait for the result
                                        final String? rationale = await showDialog<String>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Confirm Acuity Change"),
                                            content: AcuityChangeConfirmation(
                                              fromAcuity: acuity, // Current acuity
                                              toAcuity: otherAcuities[index], // Target acuity
                                              onConfirm: (text) => Navigator.pop(context, text), // Pass text back
                                            ),
                                          ),
                                        );

                                        // 2. Only proceed if rationale was returned (user didn't cancel)
                                        // 2. If valid, call the controller
                                        if (rationale != null && rationale.isNotEmpty) {
                                          // We replace the setState and the DatabaseManager call with this:
                                          await widget.patientController.addAcuity(otherAcuities[index], rationale);

                                          // 3. Optional UI feedback (only if needed)
                                          if(context.mounted){
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Acuity updated successfully.")),
                                            );
                                          }
                                          widget.onAcuityUpdated();
                                        }
                                      },
                                    );
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
    );

  }

  Widget buildDescriptorList(List<Descriptor> descriptors, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: descriptors.length,
          itemBuilder: (context, index) {
            final item = descriptors[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline, size: 20),
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(item.description),
            );
          },
        ),
      ],
    );
  }
}
