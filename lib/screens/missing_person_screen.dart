import 'package:flutter/material.dart';

class MissingPersonCaptureScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const MissingPersonCaptureScreen({super.key, this.scrollController});

  @override
  State<MissingPersonCaptureScreen> createState() => _MissingPersonCaptureScreenState();
}

class _MissingPersonCaptureScreenState extends State<MissingPersonCaptureScreen> {
  int _currentStep = 0;

  final _clothingController = TextEditingController();
  final _marksController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Stepper(
      controller: widget.scrollController,
      currentStep: _currentStep,
      onStepContinue: () {
        setState(() {
          if (_currentStep < 2) {
            _currentStep++;
          }
        });
      },
      onStepCancel: () {
        setState(() {
          if (_currentStep > 0) {
            _currentStep--;
          }
        });
      },
      controlsBuilder: (BuildContext context, ControlsDetails details) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            children: <Widget>[
              FilledButton(
                onPressed: details.onStepContinue,
                child: Text(_currentStep == 2 ? 'SUBMIT REPORT' : 'CONTINUE'),
              ),
              const SizedBox(width: 8),
              if (_currentStep > 0)
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('BACK'),
                ),
            ],
          ),
        );
      },
      steps: [
        Step(
          title: const Text("Physical Description"),
          content: Column(children: [
            TextField(controller: _clothingController, decoration: const InputDecoration(labelText: "Clothing Description")),
            TextField(controller: _marksController, decoration: const InputDecoration(labelText: "Identifying Marks")),
          ]),
        ),
        Step(
          title: const Text("Risk & Vulnerability"),
          content: Column(children: [
            SwitchListTile(title: const Text("Access to Means"), value: false, onChanged: (v){}),
            SwitchListTile(title: const Text("Disappeared Before"), value: false, onChanged: (v){}),
          ]),
        ),
        Step(
          title: const Text("Last Seen Info"),
          content: TextField(controller: _locationController, decoration: const InputDecoration(labelText: "Last Known Location")),
        ),
      ],
    );
  }
}