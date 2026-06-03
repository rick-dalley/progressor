import 'package:flutter/material.dart';
import 'package:triage/widgets/pulsing_icon.dart';
import '../app_theme.dart';
import '../classes/acuity.dart';

class AcuityViewer extends StatefulWidget {
  final Acuity acuity;

  const AcuityViewer({super.key, required this.acuity});

  @override
  State<StatefulWidget> createState() => AcuityViewerState();
}

class AcuityViewerState extends State<AcuityViewer> {
  @override
  Widget build(BuildContext context) {
    Acuity acuity = widget.acuity;
    final double notchPadding = MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top : 47.0;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: MediaQuery.of(context).padding.copyWith(top: notchPadding)),
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          primary: true,
          title: const Text("Acuity"),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
          actions: [],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Container
                Container(
                  width: double.infinity,
                  color: AppTheme.acuityBackgroundColors[acuity.level],
                  padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).hintColor.withAlpha(60),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Row(
                        children: [
                          acuity.level == AcuityLevel.notUrgent
                              ? PulsingIcon(
                                  icon: AppTheme.acuityIcons[acuity.level]!,
                                  color: AppTheme.acuityColors[acuity.level]!,
                                  size: 32,
                                )
                              : Icon(
                                  AppTheme.acuityIcons[acuity.level],
                                  size: 32,
                                  color: AppTheme.acuityColors[acuity.level],
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withAlpha(64),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4.0,
                                    ),
                                  ],
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              acuity.statusName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Body Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "INTERVENTION WINDOW",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${acuity.interventionWindow} minutes",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                      ),
                      const SizedBox(height: 24.0),
                      const Text(
                        "CLINICAL PICTURE",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        acuity.clinicalPicture,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(210),
                        ),
                      ),
                      buildDescriptorList(acuity.presentingWith, "Presenting With"),
                      buildDescriptorList(acuity.secondaryModifiers, "Secondary Modifiers"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
