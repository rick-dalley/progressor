import 'package:flutter/material.dart';

class PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;

  const PatientCard({super.key, required this.patient});

  Color _getDispositionColor() {
    // Use local variables with null-safety defaults
    final List<dynamic> flags = patient['flags'] ?? [];
    final String path = patient['path'] ?? '';
    final String status = patient['status'] ?? '';

    // 1. Green = Certified (MHA Path)
    if (flags.contains('Form 4 Active')) {
      return Colors.green.shade600;
    }

    // 2. Red = Discharge Ready (Process Completion)
    if (path == 'GP-Handoff' || status == 'Discharge Prep') {
      return Colors.red.shade600;
    }

    // 3. Yellow = Undecided / Assessment (The Default)
    return Colors.yellow.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final String lastName = (patient['name']?['last'] ?? 'Patient').toString();
    final String firstName = (patient['name']?['first'] ?? 'Unknown').toString();
    final String phn = (patient['phn'] ?? '000-000-000').toString();
    final String status = (patient['status'] ?? 'Triage').toString();
    final List<dynamic> flags = patient['flags'] ?? [];
    final Color statusColor = _getDispositionColor();
    final isTriage = patient['status'] == 'Triage';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 3), // Strong color coding
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$lastName, $firstName",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha:0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.circle, color: statusColor, size: 16),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _buildInfoChip(Icons.badge, "PHN: $phn"),
                const SizedBox(width: 12),
                // Use 'status' instead of the missing 'zone'
                _buildInfoChip(Icons.location_on, status),
                const SizedBox(width: 12),
                // Added Acuity so you can see the 1-5 scale at a glance
                _buildInfoChip(Icons.speed, "Acuity: ${patient['current_acuity']}"),
              ],
            ),
            const SizedBox(height: 12),
            _buildVitalsBar(),
            const SizedBox(height: 8),
            Text(
              "Current Status: $status",
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6.0,
              children: flags.map((flag) {
                return Chip(
                  label: Text(flag, style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: Colors.blueGrey.shade700,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _buildProcessTimeline(isTriage)
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}

Widget _buildVitalsBar() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black26,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _vitalItem(Icons.favorite, "88", "bpm"),
        _vitalItem(Icons.speed, "120/80", "bp"),
        _vitalItem(Icons.thermostat, "36.8", "°C"),
        _vitalItem(Icons.air, "98", "%"),
      ],
    ),
  );
}

Widget _vitalItem(IconData icon, String value, String unit) {
  return Column(
    children: [
      Icon(icon, size: 14, color: Colors.blueGrey.shade300),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      Text(unit, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
    ],
  );
}

Widget _buildProcessTimeline(bool isTriage) {
  // Define the stages based on the current context
  final List<String> stages = isTriage
      ? ["Handoff", "Search", "Certify", "Admit"]
      : ["Stabilize", "Review", "Handoff", "Home"];

  // Logic to determine how far along they are
  int currentStep = isTriage ? 1 : 2;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("PROCESS PATHWAY", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
      const SizedBox(height: 8),
      Row(
        children: List.generate(stages.length, (index) {
          bool isCompleted = index < currentStep;
          bool isCurrent = index == currentStep;

          return Expanded(
            child: Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : (isCurrent ? Icons.play_circle : Icons.circle_outlined),
                  size: 16,
                  color: isCompleted ? Colors.green : (isCurrent ? Colors.yellow : Colors.grey),
                ),
                if (index < stages.length - 1)
                  Expanded(child: Container(height: 2, color: isCompleted ? Colors.green : Colors.grey.shade800)),
              ],
            ),
          );
        }),
      ),
    ],
  );
}