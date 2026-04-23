import 'package:flutter/material.dart' show StatefulWidget, BuildContext, State, Widget, Text, AppBar, ListView, Scaffold;

class CSSRSAssessmentScreen extends StatefulWidget {
  @override
  _CSSRSAssessmentScreenState createState() => _CSSRSAssessmentScreenState();
}

class _CSSRSAssessmentScreenState extends State<CSSRSAssessmentScreen> {
  Map<String, dynamic> responses = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("C-SSRS Assessment")),
      body: ListView(
        children: [
          // SectionHeader(title: "Suicidal Ideation", subtitle: "Ask questions 1 and 2..."),
          //
          // BooleanWithDetail(
          //   title: "1. Wish to be Dead",
          //   onChanged: (val, desc) => _update('q1', val, desc),
          // ),
          //
          // BooleanWithDetail(
          //   title: "2. Non-Specific Active Thoughts",
          //   onChanged: (val, desc) => _update('q2', val, desc),
          // ),
          //
          // // Branching logic is now simple Dart code
          // if (responses['q2']?.value == true) ...[
          //   SectionHeader(title: "Follow-up Questions (Active Ideation)"),
          //   BooleanWithDetail(title: "3. Any Methods...", ...),
          //   BooleanWithDetail(title: "4. Some Intent...", ...),
          // ],

          // ... and so on
        ],
      ),
    );
  }

  void _update(String id, bool? value, String? desc) {
    setState(() {
      responses[id] = {'value': value, 'desc': desc};
    });
  }
}