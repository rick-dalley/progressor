import 'package:flutter/material.dart';
import 'package:triage/classes/patient_sentiment.dart';

import '../classes/body_markers.dart';

class BodyMarkerModal extends StatefulWidget {
  final BodyMarker initialMarker;
  final Function(BodyMarker) onSave;

  const BodyMarkerModal({super.key, required this.initialMarker, required this.onSave});

  @override
  State<BodyMarkerModal> createState() => _BodyMarkerModalState();
}

class _BodyMarkerModalState extends State<BodyMarkerModal> {
  late BodyMarker _currentMarker;

  @override
  void initState() {
    super.initState();
    _currentMarker = widget.initialMarker;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_currentMarker.name.toUpperCase()),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: patientSentiments[Sentiment.happy]!.getIcon(),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: patientSentiments[Sentiment.content]!.getIcon(),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: patientSentiments[Sentiment.neutral]!.getIcon(),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: patientSentiments[Sentiment.dissatisfied]!.getIcon(),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: patientSentiments[Sentiment.sad]!.getIcon(),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: patientSentiments[Sentiment.stressed]!.getIcon(),
                ),
              ],
            ),

            // Text("Edit ${widget.initialMarker.bodyZone?.name}", style: Theme.of(context).textTheme.titleLarge),
            DropdownButton<VerbalSeverity>(
              isExpanded: true,
              value: _currentMarker.severity,
              // Increase itemHeight to accommodate two lines of text
              itemHeight: 70,
              items: VerbalSeverity.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            severityExplanations[s]!,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2, // Ensures the text wraps
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _currentMarker = _updateMarker(severity: val)),
            ),

            // Frequency
            DropdownButton<Frequency>(
              isExpanded: true,
              hint: const Text("Select Frequency"),
              value: _currentMarker.frequency, // Ensure your BodyMarker class has this field
              items: Frequency.values.map((f) => DropdownMenuItem(value: f, child: Text(f.name))).toList(),
              onChanged: (val) => setState(() => _currentMarker = _updateMarker(frequency: val)),
            ),

            // Nature
            DropdownButton<Nature>(
              isExpanded: true,
              hint: const Text("Select Nature"),
              value: _currentMarker.nature, // Ensure your BodyMarker class has this field
              items: Nature.values.map((n) => DropdownMenuItem(value: n, child: Text(n.name))).toList(),
              onChanged: (val) => setState(() => _currentMarker = _updateMarker(nature: val)),
            ),

            const Spacer(),
            ElevatedButton(
              onPressed: () {
                widget.onSave(_currentMarker);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to maintain immutability while updating state
  BodyMarker _updateMarker({VerbalSeverity? severity, Frequency? frequency, Nature? nature}) {
    return BodyMarker(
      offset: _currentMarker.offset,
      emoji: _currentMarker.emoji,
      name: _currentMarker.name,
      medicalName: _currentMarker.medicalName,
      zoneMap: _currentMarker.zoneMap,
      severity: severity ?? _currentMarker.severity,
      group: _currentMarker.group,
    );
  }
}
