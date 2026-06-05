import 'package:flutter/material.dart';
import '../classes/acuity.dart';

// 1. Extracted TextField to prevent global dialog rebuilds
class RationaleInputField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const RationaleInputField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      onChanged: onChanged,
      // Disabling autocorrect/suggestions can significantly reduce input latency
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: "Clinical Rationale",
        border: OutlineInputBorder(),
      ),
    );
  }
}

// 2. Updated Parent Widget



class AcuityChangeConfirmation extends StatefulWidget {
  final Acuity fromAcuity;
  final Acuity toAcuity;
  final Function(String rationale) onConfirm;

  const AcuityChangeConfirmation({
    super.key,
    required this.fromAcuity,
    required this.toAcuity,
    required this.onConfirm,
  });

  @override
  State<AcuityChangeConfirmation> createState() => _AcuityChangeConfirmationState();
}

class _AcuityChangeConfirmationState extends State<AcuityChangeConfirmation> {
  final TextEditingController _controller = TextEditingController();
  bool _canSubmit = false;
  bool _isEmergency = false;

  late final bool _isBigJumpUp; // 3/4 -> 1/2
  late final bool _isSignificantDrop; // Drop by >= 2 levels

  @override
  void initState() {
    super.initState();
    _isBigJumpUp = (widget.fromAcuity.level.index >= 2 && widget.toAcuity.level.index <= 1);
    _isSignificantDrop = (widget.fromAcuity.level.index - widget.toAcuity.level.index) >= 2;

    _controller.addListener(() {
      setState(() => _canSubmit = _controller.text.trim().isNotEmpty);
    });
  }

  String _getMessage() {
    if (_isBigJumpUp) return "CRITICAL: You are escalating to an emergent status. This requires immediate clinical intervention.";
    if (_isSignificantDrop) return "Caution: You are significantly decreasing acuity. Please ensure the patient is stabilized.";
    return "You are updating the acuity level. This will trigger system-wide notification updates.";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_getMessage(), style: TextStyle(fontWeight: _isBigJumpUp ? FontWeight.bold : FontWeight.normal)),
        ),

        if (_isBigJumpUp)
          CheckboxListTile(
            title: const Text("EMERGENCY OVERRIDE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            value: _isEmergency,
            onChanged: (val) => setState(() {
              _isEmergency = val!;
              if (_isEmergency) {
                _controller.text = "EMERGENCY: Immediate triage reassessment. Status escalated due to acute clinical deterioration.";
              }
            }),
          ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: RationaleInputField(
            controller: _controller,
            onChanged: (text) {
              // Only trigger setState when validation status changes,
              // not on every single character typed
              final isValid = text.trim().isNotEmpty;
              if (isValid != _canSubmit) {
                setState(() => _canSubmit = isValid);
              }
            },
          ),
        ),

        ElevatedButton(
          onPressed: _canSubmit ? () => widget.onConfirm(_controller.text.trim()) : null,
          child: const Text("Commit Change"),
        ),
      ],
    );
  }
}