import 'package:flutter/material.dart';
import 'package:triage/classes/patient_sentiment.dart';
import 'package:triage/widgets/card_flipper.dart';

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

  Zone _identifyZone(Offset tap, TouchImage touchImage) {
    for (var zone in touchImage.zones) {
      if (zone.isIn(tap.dx, tap.dy)) {
        debugPrint('Zone: ${zone.name}');
        return zone; // Returns the BodyZones enum
      }
    }
    return touchImage.zones[0];
  }

  @override
  Widget build(BuildContext context) {
    TouchImage? touchImage = TouchImageFactory.instance.getTouchImage(selection: ZoneMaps.footBottom);
    if (touchImage == null ){
      return Text("Touch Image not found!");
    }
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
          child: Container(
            color: Color(0xFFFFFFFF),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(width: 24,),
                    Text("Overall:"),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: patientSentiments[widget.patient.sentiment]!.getIcon(),
                    ),
                    Spacer(),
                    if (widget.patient.sentiment != Sentiment.happy)
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: patientSentiments[Sentiment.happy]!.getIcon(),
                    ),
                    if (widget.patient.sentiment != Sentiment.content)
                    IconButton(
                      onPressed: () {
                      },
                      icon: patientSentiments[Sentiment.content]!.getIcon(),
                    ),
                    if (widget.patient.sentiment != Sentiment.neutral)
                    IconButton(
                      onPressed: () {
                      },
                      icon: patientSentiments[Sentiment.neutral]!.getIcon(),
                    ),
                    if (widget.patient.sentiment != Sentiment.dissatisfied)
                    IconButton(
                      onPressed: () {
                      },
                      icon: patientSentiments[Sentiment.dissatisfied]!.getIcon(),
                    ),
                    if (widget.patient.sentiment != Sentiment.sad)
                    IconButton(
                      onPressed: () {
                      },
                      icon: patientSentiments[Sentiment.sad]!.getIcon(),
                    ),
                    if (widget.patient.sentiment != Sentiment.stressed)
                    IconButton(
                      onPressed: () {
                      },
                      icon: patientSentiments[Sentiment.stressed]!.getIcon(),
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
                        final zone = _identifyZone(tappedOffset, touchImage!);

                        // 2. Create a temporary marker
                        final newMarker = BodyMarker(
                          offset: tappedOffset,
                          emoji: Sentiment.neutral,
                          // Default value
                          zone: zone,
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
                    child:Stack(
                      fit: StackFit.loose,
                      children: [
                        // Full screen body image
                        Image.asset(touchImage!.imagePath, fit: BoxFit.contain),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: PolygonPainter(touchImage.zones),
                            ),
                          ),
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
