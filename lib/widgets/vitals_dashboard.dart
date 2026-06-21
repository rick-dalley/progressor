import 'package:flutter/material.dart';

class VitalsDashboard extends StatefulWidget {
  final Map<String, TextEditingController> controllers;

  const VitalsDashboard({super.key, required this.controllers});

  @override
  State<VitalsDashboard> createState() => _VitalsDashboardState();
}

class _VitalsDashboardState extends State<VitalsDashboard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.blueGrey.shade900,
      child: Row(
        children: [
          _buildField("Temp", widget.controllers['temp']!),
          _buildField("HR", widget.controllers['hr']!),
          _buildField("BP", widget.controllers['bp']!),
          _buildField("RR", widget.controllers['rr']!),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
            border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
          keyboardType: TextInputType.number,
        ),
      ),
    );
  }
}
