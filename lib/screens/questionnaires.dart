import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:triage/screens/observations_screen.dart';
import 'package:triage/screens/physical_health.dart';

import '../app_theme.dart';
import '../classes/assessment_logic.dart';
import '../classes/templates.dart';
import 'observation.dart';

class AssessmentsScreen extends StatefulWidget {
  final String patientUuid;

  const AssessmentsScreen({super.key, required this.patientUuid});

  @override
  State<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends State<AssessmentsScreen> {
  late Future<Map<String, int>> _assessmentCountsFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future once
    _assessmentCountsFuture = DatabaseManager().countCompletedAssessments(widget.patientUuid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _assessmentCountsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Show loader while fetching
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error loading history: ${snapshot.error}"));
        }

        // Pre-process the maps once the data arrives
        final Map<String, int> counts = snapshot.data ?? {};
        final Map<String, bool> completed = counts.map((key, value) => MapEntry(key, value > 0));

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          decoration: BoxDecoration(
            color: AppTheme.canvasColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Modal Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppTheme.canvasColor, borderRadius: BorderRadius.circular(10)),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "ASSESSMENTS",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepLogicViolet, letterSpacing: 1.2),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // --- SECTION: PHYSICAL HEALTH (The "Total Picture") ---
                    _buildSectionHeader("PHYSICAL HEALTH"),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Card(
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            // Subtle border changes color when task is done
                            color: AppTheme.cardBorder,
                            width: 1.5,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _launchObservationsModal(context);
                          },
                          child: ListTile(
                            leading: _buildDynamicIcon(
                              isCompleted: true,
                              outlineIcon: Symbols.conditions,
                              solidIcon: Symbols.conditions_sharp,
                              activeColor: AppTheme.deepLogicViolet,
                            ),
                            title: const Text("Pre-existing Conditions"),
                            subtitle: const Text("Review & Update Physical Health History"),
                            onTap: () {
                              Navigator.pop(context);
                              _launchPhysicalHealthChecklist(context, widget.patientUuid);
                            },
                          ),
                        ),
                      ),
                    ),
                    // --- SECTION: CLINICAL OBSERVATIONS ---
                    _buildSectionHeader("CLINICAL NOTES"),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Card(
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            // Subtle border changes color when task is done
                            color: AppTheme.cardBorder,
                            width: 1.5,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _launchObservationsModal(context);
                          },
                          child: ListTile(
                            leading: _buildDynamicIcon(
                              isCompleted: true,
                              outlineIcon: Symbols.clinical_notes,
                              solidIcon: Symbols.clinical_notes_sharp,
                              activeColor: AppTheme.deepLogicViolet,
                            ),
                            title: const Text("Observations"),
                            subtitle: const Text("Individual observations of patient behaviour"),
                          ),
                        ),
                      ),
                    ),
                    // --- SECTION: PSYCHIATRIC SCALES ---
                    _buildSectionHeader("STANDARDIZED SCALES"),

                    _buildAssessmentTile(
                      context,
                      "PHQ-9",
                      widget.patientUuid,
                      "Patient Health Questionnaire -9\n(Objectifies degree of depression severity)",
                      "phq-9.json",
                      'assets/questions/phq9_score_guide.json',
                      completed["PHQ-9"] ?? false,
                      // The builder signature must match (String, dynamic, ScrollController)
                      (assessmentId, data, ctrl) => QuestionnaireSelectorScreen(
                        assessmentId: data["assessmentId"],
                        patientUuid: data["patientUuid"],
                        scoreGuidePath: data["scoreGuidePath"],
                        template: data["template"],
                        isReadOnly: data['isReadOnly'],
                        logic: PHQ9Logic(),
                        scrollController: ctrl,
                      ),
                    ),

                    _buildAssessmentTile(
                      context,
                      "GAD-7",
                      widget.patientUuid,
                      "General Anxiety Disorder-7)\nMeasures severity of anxiety.",
                      "gad-7.json",
                      'assets/questions/gad7_score_guide.json',
                      completed["GAD-7"] ?? false,
                      (assessmentId, data, ctrl) => QuestionnaireSelectorScreen(
                        assessmentId: data["assessmentId"],
                        patientUuid: data["patientUuid"],
                        scoreGuidePath: data["scoreGuidePath"],
                        template: data["template"],
                        isReadOnly: data['isReadOnly'],
                        logic: GAD7Logic(),
                        scrollController: ctrl,
                      ),
                    ),

                    _buildAssessmentTile(
                      context,
                      "C-SSRS",
                      widget.patientUuid,
                      "Columbia-Suicide Severity Rating Scale\nAssesses suicide risk, severity, and intent",
                      "c-ssrs.json",
                      null,
                      completed["C-SSRS"] ?? false,
                      (assessmentId, data, ctrl) => QuestionnaireSelectorScreen(
                        assessmentId: data["assessmentId"],
                        patientUuid: data["patientUuid"],
                        scoreGuidePath: data["scoreGuidePath"],
                        template: data["template"],
                        isReadOnly: data['isReadOnly'],
                        logic: CSSRSLogic(),
                        scrollController: ctrl,
                      ),
                    ),

                    _buildAssessmentTile(
                      context,
                      "DAST-10",
                      widget.patientUuid,
                      "Drug Abuse Screening Test\nScreen for the presence and severity of substance use ",
                      "dast-10.json",
                      'assets/questions/dast10_score_guide.json',
                      completed["DAST-10"] ?? false,
                      (assessmentId, data, ctrl) => QuestionnaireSelectorScreen(
                        assessmentId: data["assessmentId"],
                        patientUuid: data["patientUuid"],
                        scoreGuidePath: data["scoreGuidePath"],
                        template: data["template"],
                        isReadOnly: data['isReadOnly'],
                        logic: DAST10Logic(),
                        scrollController: ctrl,
                      ),
                    ),

                    _buildAssessmentTile(
                      context,
                      "ASRS-V1.1",
                      widget.patientUuid,
                      "Adult ADHD Self Report Scale\nVersion 1.1(",
                      "asrs.json",
                      'assets/questions/asrs_score_guide.json',
                      completed["ASRS-V1.1"] ?? false,
                      (assessmentId, data, ctrl) => QuestionnaireSelectorScreen(
                        assessmentId: data["assessmentId"],
                        patientUuid: data["patientUuid"],
                        scoreGuidePath: data["scoreGuidePath"],
                        template: data["template"],
                        isReadOnly: data['isReadOnly'],
                        logic: ASRS11Logic(),
                        scrollController: ctrl,
                      ),
                    ),

                    _buildAssessmentTile(
                      context,
                      "PCL-5",
                      widget.patientUuid,
                      "PTSD Checklist for DSM-5\nAssesses the 20 DSM-5 symptoms of PTSD",
                      "pcl-5.json",
                      'assets/questions/pcl5_score_guide.json',
                      completed["PCL-5"] ?? false,
                      (assessmentId, data, ctrl) => QuestionnaireSelectorScreen(
                        assessmentId: data["assessmentId"],
                        patientUuid: data["patientUuid"],
                        scoreGuidePath: data["scoreGuidePath"],
                        template: data["template"],
                        isReadOnly: data['isReadOnly'],
                        logic: PCL5Logic(),
                        scrollController: ctrl,
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper to keep the build method clean
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.deepCharcoal, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildAssessmentTile(
    BuildContext context,
    String assessmentName,
    String patientId,
    String subtitle,
    String template,
    String? scoreGuidePath, // ADD THIS
    bool isCompleted,
    Widget Function(String, Map<String, dynamic>, ScrollController) builder,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isCompleted ? AppTheme.clinicalCyan : AppTheme.cardBorder, width: 1.5),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Centered Status Icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Icon(
                    isCompleted ? Symbols.ballot : Symbols.ballot_sharp,
                    color: isCompleted ? AppTheme.clinicalCyan : AppTheme.deepCharcoal,
                    size: 32,
                  ),
                ),
              ),

              // 2. Centered Text Content Area
              Expanded(
                child: InkWell(
                  onTap: () => _launchAssessment(
                    context,
                    assessmentId: assessmentName,
                    patientId: patientId,
                    templateName: template,
                    scoreGuidePath: scoreGuidePath,
                    isReadOnly: isCompleted,
                    screenBuilder: builder,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0), // Consistent padding
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // VERTICAL CENTERING
                      crossAxisAlignment: CrossAxisAlignment.start, // LEFT ALIGN TEXT
                      children: [
                        Text(assessmentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Action Tab
              Material(
                color: AppTheme.deepLogicViolet,
                child: InkWell(
                  onTap: () => _launchAssessment(
                    context,
                    assessmentId: assessmentName,
                    patientId: patientId,
                    templateName: template,
                    isReadOnly: false,
                    screenBuilder: builder,
                    scoreGuidePath: scoreGuidePath,
                  ),
                  child: const SizedBox(width: 60, child: Icon(Icons.add, color: Colors.white, size: 30)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicIcon({
    required bool isCompleted,
    required IconData outlineIcon,
    required IconData solidIcon,
    required Color activeColor,
  }) {
    return Icon(
      isCompleted ? solidIcon : outlineIcon,
      color: isCompleted ? activeColor : AppTheme.deepCharcoal,
      size: 32,
    );
  }

  void _launchPhysicalHealthChecklist(BuildContext context, String patientUuid) async {
    final dynamic result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        snap: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.clinicalWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(10)),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey, size: 22),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: PhysicalHealthAssessment(
                    patientUuid: patientUuid,
                    scrollController: scrollController, // Matches your inner definition name
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _assessmentCountsFuture = DatabaseManager().countCompletedAssessments(patientUuid);
      });
    }
  }

  void _launchObservationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // ✅ Prevents accidental drag-down dismissals on the background area
      enableDrag: false,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        snap: false, // ✅ Smooth, non-snapping fluid track
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centered pull bar handle indicator
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                      ),
                      // ✅ Unified Top-Right Dismiss Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey, size: 22),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  // ✅ Pass the controller into the screen
                  child: ObservationScreen(patientUuid: widget.patientUuid, scrollController: scrollController),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchAssessment(
    BuildContext context, {
    required String assessmentId,
    required String patientId,
    required String templateName,
    required String? scoreGuidePath,
    required bool isReadOnly,
    required Widget Function(String assessmentId, Map<String, dynamic> template, ScrollController controller)
    screenBuilder,
  }) async {
    // 1. Fetch the requested template
    Map<String, dynamic> template = await Templates.getTemplate(templateName);
    // 2. Standardized Modal Plumbing
    if (!context.mounted) return;
    // We wrap the patientUuid and the read-only flag into the context map
    final Map<String, dynamic> patientContext = {
      'assessmentId': assessmentId,
      'patientUuid': patientId, // Put it in the envelope here
      'isReadOnly': isReadOnly,
      'scoreGuidePath': scoreGuidePath,
      'template': template,
    };

    final dynamic result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        snap: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.clinicalWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(10)),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.grey, // Or use AppTheme.subText
                      size: 22,
                    ),
                    tooltip: "Dismiss assessment",
                    // Closes the sheet instantly and flags a false result down to your database poker
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                Expanded(
                  // 3. Inject the specific screen here
                  child: screenBuilder(assessmentId, patientContext, scrollController),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _assessmentCountsFuture = DatabaseManager().countCompletedAssessments(
          widget.patientUuid,
        ); // This 'pokes' the UI to refresh icons
      });
    }
  }
}
