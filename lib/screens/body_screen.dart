import 'package:flutter/material.dart';
import 'package:triage/classes/patient_sentiment.dart';

import '../classes/body_markers.dart';
import '../classes/body_zone.dart';
import '../classes/patient.dart';
import '../widgets/body_marker_modal.dart';

class BodyOutlineScreen extends StatefulWidget {
  final Patient patient;

  const BodyOutlineScreen({super.key, required this.patient});

  @override
  State<BodyOutlineScreen> createState() => _BodyOutlineScreenState();
}

class _BodyOutlineScreenState extends State<BodyOutlineScreen> {
  // Example: Store marker points here
  final List<Offset> _markers = [];

  BodyZones _identifyZone(Offset tap, ZoneMap zoneMap) {
    for (var entry in bodyZones.entries) {
      if (entry.value.isIn(tap.dx, tap.dy)) {
        return entry.key; // Returns the BodyZones enum
      }
    }
    return BodyZones.none;
  }

  @override
  Widget build(BuildContext context) {
    final double notchPadding = MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top : 47.0;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: MediaQuery.of(context).padding.copyWith(top: notchPadding)),
      child: Scaffold(
        // Scaffold gives us full screen control
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          primary: true,
          title: Text("${widget.patient.firstName} ${widget.patient.lastName}"),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
          actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})],
        ),
        body: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: patientSentiments[widget.patient.sentiment]!.getIcon(),
                    ),
                  ],
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: GestureDetector(
                  onTapDown: (TapDownDetails details) {
                    // Get the tap location relative to the container
                    setState(() {
                      _markers.add(details.localPosition);
                      final tappedOffset = details.localPosition;

                      // 1. Identify which zone was tapped (using your mapping logic)
                      final zone = _identifyZone(tappedOffset, ZoneMap.body);

                      // 2. Create a temporary marker
                      final newMarker = BodyMarker(
                        offset: tappedOffset,
                        emoji: Sentiment.neutral,
                        // Default value
                        bodyZone: zone,
                        headZone: HeadZones.none,
                        handZone: HandZones.none,
                        footZone: FootZones.none,
                      );

                      // 3. Show the Modal
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                        builder: (context) => BodyMarkerModal(
                          initialMarker: newMarker,
                          onSave: (updatedMarker) {
                            // 4. On Save, update the state to store the new marker
                            setState(() {
                              //_markers.add(updatedMarker);
                            });
                          },
                        ),
                      );
                    });
                    // Here you would trigger your "Hot Button" modal
                  },
                  child: Stack(
                    fit: StackFit.loose,
                    children: [
                      // Full screen body image
                      Image.asset('assets/images/body.png', fit: BoxFit.contain),
                      // Layer markers on top
                      ..._markers.map(
                            (offset) => Positioned(
                          left: offset.dx - 15,
                          top: offset.dy - 15,
                          child: const Icon(Icons.circle, color: Colors.red, size: 30),
                        ),
                      ),
                    ],
                  ),
                ),)
              ],
            ),
          )
        ),
      ),
    );
  }
}
