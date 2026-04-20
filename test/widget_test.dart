import 'package:flutter/material.dart';
import 'package:triage/screens/patient_roster.dart';

void main() {
  runApp(const LuminescaApp());
}

class LuminescaApp extends StatelessWidget {
  const LuminescaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luminesca - Triage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212), // Deep black for OLED
      ),
      home: const PatientRoster(),
    );
  }
}