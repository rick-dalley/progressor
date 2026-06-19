import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/acuity.dart';
import 'package:triage/screens/missing_person_screen.dart';
import 'package:triage/widgets/toxidrome_test_widget.dart';

import '../app_theme.dart';
import '../classes/triage.dart';
import '../widgets/psychosis_assessment_widget.dart';
import '../widgets/pulsing_chip.dart';
import '../widgets/suicide_assessment_widget.dart';
import 'assessment_screen.dart';
import 'intake.dart';

class IncidentTriageScreen extends StatefulWidget {
  const IncidentTriageScreen({super.key});

  @override
  State<IncidentTriageScreen> createState() => _IncidentTriageScreenState();
}

class _IncidentTriageScreenState extends State<IncidentTriageScreen> {
  void _launchIntakeScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntakeScreen(),
        // This ensures the screen slides up like a focused task
        fullscreenDialog: true,
      ),
    );
  }

  TriageAssessmentResult _currentAssessment = TriageAssessmentResult();

  void _updateAssessment(TriageAssessmentResult newResult) {
    setState(() {
      _currentAssessment = newResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    AcuityLevel acuityLevel = AcuityLevel.notUrgent;
    Acuity? acuity = AcuityFactory.instance.getAcuity(level: acuityLevel);
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Intervention"),
        actions: [
          // The "John Doe" / Photo Quick-Capture Button
          IconButton(icon: const Icon(Icons.camera_alt), onPressed: () => _handleAnonymousCapture(context)),
        ],
      ),
      body: Column(
        children: [
          // 1. Quick Identity Header (Can be minimized or expanded)
          _buildIdentityHeader(context),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: PulsingChip(
              iconData: AppTheme.acuityIcons[acuityLevel]!,
              text: acuity != null ? "Acuity: ${acuity.statusName}" : "Acuity: pending",
              textColor: AppTheme.lightTheme.disabledColor,
              iconColor: AppTheme.acuityColors[acuityLevel],
              backgroundColor: AppTheme.acuityBackgroundColors[acuityLevel],
              pulse: acuityLevel == AcuityLevel.resuscitation,
              shadowText: false,
              onTap: () {},
            ),
          ),

          // 2. The Triage/Reason Selection Grid
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildReasonChip(
                  context: context,
                  title: "Toxidrome",
                  icon: Symbols.mixture_med,
                  color: Colors.teal,
                  assessment: AssessmentType.toxidrome,
                ),
                _buildReasonChip(
                  context: context,
                  title: "Psychotic Break",
                  icon: Symbols.psychology,
                  color: Colors.orange,
                  assessment: AssessmentType.psychosis,
                ),
                _buildReasonChip(
                  context: context,
                  title: "Suicide Risk",
                  icon: Symbols.skull,
                  color: Colors.black,
                  assessment: AssessmentType.suicide,
                ),
                _buildReasonChip(
                  context: context,
                  title: "Missing",
                  icon: Symbols.flashlight_on,
                  color: Colors.deepPurple,
                  assessment: AssessmentType.missing,
                ),
                _buildReasonChip(
                  context: context,
                  title: "Airway and Breathing",
                  icon: Symbols.pulmonology,
                  color: Colors.green,
                  assessment: AssessmentType.breathing,
                ),
                _buildReasonChip(
                  context: context,
                  title: "Circulation and Hemorrhage",
                  icon: Symbols.hematology,
                  color: Colors.red,
                  assessment: AssessmentType.bleeding,
                ),
                _buildReasonChip(
                  context: context,
                  title: "Consciousness",
                  icon: Symbols.neurology,
                  color: Colors.blue,
                  assessment: AssessmentType.consciousness,
                ),
                _buildReasonChip(
                  context: context,
                  title: "Systemic and Environmental",
                  icon: Symbols.body_system,
                  color: Colors.brown,
                  assessment: AssessmentType.systemic,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityHeader(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person_outline)),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Subject: John Doe", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Status: Unidentified", style: TextStyle(fontSize: 12)),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              _launchIntakeScreen(context);
            },
            child: const Text("EDIT"),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonChip({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required AssessmentType assessment,
  }) {
    return ElevatedButton(
      onPressed: () {
        switch (assessment) {
          case AssessmentType.toxidrome:
            _showAssessmentModal(context, ToxidromeAssessmentWidget());
          case AssessmentType.psychosis:
            _showAssessmentModal(context, PsychosisAssessmentWidget(subjectName: "subject"));
          case AssessmentType.suicide:
            _showAssessmentModal(context, SuicideAssessmentWidget(subjectName: ""));
          case AssessmentType.missing:
            _showAssessmentModal(context, MissingPersonCaptureScreen());
          case AssessmentType.breathing:
            _showAssessmentModal(context, AssessmentScreen(type: AssessmentType.breathing));
          case AssessmentType.bleeding:
            _showAssessmentModal(context, AssessmentScreen(type: AssessmentType.bleeding));
          case AssessmentType.consciousness:
            _showAssessmentModal(context, AssessmentScreen(type: AssessmentType.consciousness));
          case AssessmentType.systemic:
            _showAssessmentModal(context, AssessmentScreen(type: AssessmentType.systemic));
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _handleAnonymousCapture(BuildContext context) {
    // Quick camera logic would go here
  }

  // Add this variable to your State to track the modal
  BuildContext? _modalContext;

  void _showAssessmentModal(BuildContext context, Widget assessmentWidget) {
    // If a modal is open, close it before pushing the new route
    if (_modalContext != null) {
      Navigator.pop(_modalContext!);
      _modalContext = null;
    }

    // Push as a full-screen dialog route
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(body: assessmentWidget),
        fullscreenDialog: true, // This gives you the slide-up modal behavior
      ),
    );
  }
}
