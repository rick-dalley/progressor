import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/acuity.dart';

class AcuityWidget extends StatelessWidget {
  final Acuity acuity;

  const AcuityWidget({super.key, required this.acuity});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      // Ensure this matches the parent Card's radius
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(acuity, context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "INTERVENTION WINDOW",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                      ),
                      Spacer(),
                      Text(
                        "${acuity.interventionWindow} minutes",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                  _buildDescriptorList(acuity.presentingWith, "Presenting With"),
                  _buildDescriptorList(acuity.secondaryModifiers, "Secondary Modifiers"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Acuity acuity, BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.acuityBackgroundColors[acuity.level],
      padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
      child: Text(acuity.statusName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDescriptorList(List<Descriptor> descriptors, String title) {
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
