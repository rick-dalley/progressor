import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../app_theme.dart';
import '../classes/body_markers.dart';
import '../classes/body_zone.dart';
import '../classes/patient.dart';
import '../classes/patient_sentiment.dart';
import '../widgets/body_marker_modal.dart';

enum FlipDirection { none, flipX, flipY, flipXY }

enum AnatomyMapTapped { none, body, rightHand, leftHand, rightFoot, leftFoot, face }

class BodyOutlineScreen extends StatefulWidget {
  final Patient patient;

  const BodyOutlineScreen({super.key, required this.patient});

  @override
  State<BodyOutlineScreen> createState() => _BodyOutlineScreenState();
}

class _BodyOutlineScreenState extends State<BodyOutlineScreen> {
  // Example: Store marker points here
  final List<BodyMarker> _markers = [];
  AnatomyZoneMaps selectedMap = AnatomyZoneMaps.bodyFront;
  FlipDirection imageOrientation = FlipDirection.none;
  TouchImage? touchImage;
  Widget? anatomyImage;
  AnatomyMapTapped anatomyMapTapped = AnatomyMapTapped.body;
  BodyMarkerGroup markerGroup = BodyMarkerGroup.bodyFront;

  Offset orientOffset({
    required double height,
    required double width,
    required double imageHeight,
    required double imageWidth,
    required Offset offset,
    required FlipDirection flip,
    required AnatomyZoneMaps zoneMap,
  }) {
    // Define which maps support flipping
    final bool isFlippable = [
      AnatomyZoneMaps.handFront,
      AnatomyZoneMaps.handBack,
      AnatomyZoneMaps.footTop,
      AnatomyZoneMaps.footBottom,
    ].contains(zoneMap);

    if (!isFlippable || flip == FlipDirection.none) {
      return offset;
    }

    // Calculate new coordinates based on flip type
    double dx = (flip == FlipDirection.flipX || flip == FlipDirection.flipXY) ? width - offset.dx : offset.dx;

    double dy = (flip == FlipDirection.flipY || flip == FlipDirection.flipXY)
        ? height - offset.dy - ((height - imageHeight) * 0.5)
        : offset.dy;

    return Offset(dx, dy);
  }

  Zone _identifyZone(Offset tap) {
    for (var zone in touchImage!.zones) {
      if (zone.isIn(tap.dx, tap.dy) && zone.map == selectedMap) {
        //did the user tap on a zone that should bring up a map?
        if (zone.isLink) {
          setImageMapFromZone(zone);
          return touchImage!.zones.first;
        } else {
          return zone;
        }
      }
    }
    return touchImage!.zones.first;
  }

  void setImageMapFromZone(Zone zone) {
    AnatomyZoneMaps tappedMap = selectedMap;
    AnatomyMapTapped requested = anatomyMapTapped;
    FlipDirection selectedImageOrientation = imageOrientation;
    //did the user tap on a zone that should bring up a map?
    if (zone.name == "right hand") {
      requested = AnatomyMapTapped.rightHand;
      tappedMap = selectedMap == AnatomyZoneMaps.bodyFront ? AnatomyZoneMaps.handFront : AnatomyZoneMaps.handBack;
      selectedImageOrientation = FlipDirection.flipX;
      markerGroup = BodyMarkerGroup.rightHandFront;
    } else if (zone.name == "left hand") {
      requested = AnatomyMapTapped.leftHand;
      tappedMap = selectedMap == AnatomyZoneMaps.bodyFront ? AnatomyZoneMaps.handFront : AnatomyZoneMaps.handBack;
      selectedImageOrientation = FlipDirection.none;
      markerGroup = BodyMarkerGroup.leftHandFront;
    } else if (zone.name == "right foot") {
      requested = AnatomyMapTapped.rightFoot;
      tappedMap = selectedMap == AnatomyZoneMaps.bodyFront ? AnatomyZoneMaps.footTop : AnatomyZoneMaps.footBottom;
      selectedImageOrientation = FlipDirection.flipX;
      markerGroup = BodyMarkerGroup.rightFootBottom;
    } else if (zone.name == "left foot") {
      requested = AnatomyMapTapped.rightFoot;
      tappedMap = selectedMap == AnatomyZoneMaps.bodyFront ? AnatomyZoneMaps.footTop : AnatomyZoneMaps.footBottom;
      selectedImageOrientation = FlipDirection.none;
      markerGroup = BodyMarkerGroup.leftFootBottom;
    } else if (zone.name == "face") {
      requested = AnatomyMapTapped.face;
      tappedMap = AnatomyZoneMaps.face;
      selectedImageOrientation = FlipDirection.none;
      markerGroup = BodyMarkerGroup.leftFootBottom;
    }
    setState(() {
      anatomyMapTapped = requested;
      selectedMap = tappedMap;
      imageOrientation = selectedImageOrientation;
      touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
      anatomyImage = touchImage!.flip(imageOrientation);
      debugPrint("$markerGroup");
    });
  }

  @override
  void initState() {
    super.initState();
    imageOrientation = FlipDirection.none;
    selectedMap = AnatomyZoneMaps.bodyFront;
    touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap);
    anatomyImage = touchImage?.flip(imageOrientation);
  }

  @override
  Widget build(BuildContext context) {
    if (touchImage == null) {
      return Text("Touch Image not found!");
    }

    MediaQueryData mq = MediaQuery.of(context);
    final double notchPadding = mq.padding.top > 0 ? mq.padding.top : 47.0;

    return MediaQuery(
      data: mq.copyWith(padding: mq.padding.copyWith(top: notchPadding)),
      child: Scaffold(
        // Scaffold gives us full screen control
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          primary: true,
          title: Text("${widget.patient.firstName} ${widget.patient.lastName}"),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
          actions: [IconButton(onPressed: () {}, icon: Icon(Symbols.send, size: 30))],
        ),
        body: SafeArea(
          child: Container(
            color: Color(0xFFFFFFFF),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ROW OF ICON BUTTONS TO CHOOSE ANATOMY
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Symbols.accessibility,
                        size: anatomyMapTapped == AnatomyMapTapped.body ? 36 : 30,
                        color: anatomyMapTapped == AnatomyMapTapped.body ? AppTheme.deepLogicViolet : Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          anatomyMapTapped = AnatomyMapTapped.body;
                          selectedMap = AnatomyZoneMaps.bodyFront;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = touchImage?.flip(imageOrientation);
                          markerGroup = BodyMarkerGroup.bodyFront;
                        });
                      },
                    ),
                    //Right Hand
                    IconButton(
                      icon: Icon(
                        Symbols.front_hand,
                        size: anatomyMapTapped == AnatomyMapTapped.rightHand ? 36 : 30,
                        color: anatomyMapTapped == AnatomyMapTapped.rightHand ? AppTheme.deepLogicViolet : Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          anatomyMapTapped = AnatomyMapTapped.rightHand;
                          selectedMap = AnatomyZoneMaps.handFront;
                          imageOrientation = FlipDirection.flipX;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = touchImage?.flip(imageOrientation);
                          markerGroup = BodyMarkerGroup.rightHandFront;
                        });
                      },
                    ),
                    //Left Hand
                    IconButton(
                      icon: Transform.flip(
                        flipX: true,
                        child: Icon(
                          Symbols.front_hand,
                          size: anatomyMapTapped == AnatomyMapTapped.leftHand ? 36 : 30,
                          color: anatomyMapTapped == AnatomyMapTapped.leftHand
                              ? AppTheme.deepLogicViolet
                              : Colors.black,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          anatomyMapTapped = AnatomyMapTapped.leftHand;
                          selectedMap = AnatomyZoneMaps.handFront;
                          imageOrientation = FlipDirection.none;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = touchImage?.flip(imageOrientation);
                          markerGroup = BodyMarkerGroup.leftHandFront;
                        });
                      },
                    ),
                    IconButton(
                      icon: Transform.flip(
                        flipY: true,
                        child: Icon(
                          Symbols.barefoot,
                          size: anatomyMapTapped == AnatomyMapTapped.rightFoot ? 36 : 30,
                          color: anatomyMapTapped == AnatomyMapTapped.rightFoot
                              ? AppTheme.deepLogicViolet
                              : Colors.black,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          anatomyMapTapped = AnatomyMapTapped.rightFoot;
                          selectedMap = AnatomyZoneMaps.footBottom;
                          imageOrientation = FlipDirection.flipX;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = touchImage?.flip(imageOrientation);
                          markerGroup = BodyMarkerGroup.rightFootBottom;
                        });
                      },
                    ),
                    IconButton(
                      icon: Transform.flip(
                        flipX: true,
                        flipY: true,
                        child: Icon(
                          Symbols.barefoot,
                          size: anatomyMapTapped == AnatomyMapTapped.leftFoot ? 36 : 30,
                          color: anatomyMapTapped == AnatomyMapTapped.leftFoot
                              ? AppTheme.deepLogicViolet
                              : Colors.black,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          anatomyMapTapped = AnatomyMapTapped.leftFoot;
                          selectedMap = AnatomyZoneMaps.footBottom;
                          imageOrientation = FlipDirection.none;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = touchImage?.flip(imageOrientation);
                          markerGroup = BodyMarkerGroup.leftFootBottom;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Symbols.face,
                        size: anatomyMapTapped == AnatomyMapTapped.face ? 36 : 30,
                        color: anatomyMapTapped == AnatomyMapTapped.face ? AppTheme.deepLogicViolet : Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          anatomyMapTapped = AnatomyMapTapped.face;
                          selectedMap = AnatomyZoneMaps.face;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = touchImage?.flip(imageOrientation);
                          markerGroup = BodyMarkerGroup.face;
                        });
                      },
                    ),
                    Spacer(),

                    //Flip
                    IconButton(
                      icon: Icon(Symbols.flip, size: 30),
                      onPressed: () {
                        AnatomyZoneMaps tappedMap = selectedMap;
                        BodyMarkerGroup tappedMarkerGroup = markerGroup;
                        switch (anatomyMapTapped) {
                          case AnatomyMapTapped.body:
                            {
                              imageOrientation = FlipDirection.none;
                              tappedMap = selectedMap == AnatomyZoneMaps.bodyBack
                                  ? AnatomyZoneMaps.bodyFront
                                  : AnatomyZoneMaps.bodyBack;
                              tappedMarkerGroup = markerGroup == BodyMarkerGroup.bodyBack
                                  ? BodyMarkerGroup.bodyFront
                                  : BodyMarkerGroup.bodyBack;
                            }
                          case AnatomyMapTapped.face:
                            {
                              imageOrientation = FlipDirection.none;
                              tappedMap = AnatomyZoneMaps.face;
                              tappedMarkerGroup = BodyMarkerGroup.face;
                            }
                          case AnatomyMapTapped.rightHand:
                            {
                              imageOrientation = FlipDirection.flipX;
                              tappedMap = selectedMap == AnatomyZoneMaps.handBack
                                  ? AnatomyZoneMaps.handFront
                                  : AnatomyZoneMaps.handBack;
                              tappedMarkerGroup = markerGroup == BodyMarkerGroup.rightHandFront
                                  ? BodyMarkerGroup.rightHandBack
                                  : BodyMarkerGroup.rightHandFront;
                            }
                          case AnatomyMapTapped.leftHand:
                            {
                              imageOrientation = FlipDirection.none;
                              tappedMap = selectedMap == AnatomyZoneMaps.handFront
                                  ? AnatomyZoneMaps.handBack
                                  : AnatomyZoneMaps.handFront;
                              tappedMarkerGroup = markerGroup == BodyMarkerGroup.leftHandFront
                                  ? BodyMarkerGroup.leftHandBack
                                  : BodyMarkerGroup.leftHandFront;
                            }
                            tappedMarkerGroup = markerGroup == BodyMarkerGroup.bodyBack
                                ? BodyMarkerGroup.bodyFront
                                : BodyMarkerGroup.bodyBack;
                          case AnatomyMapTapped.rightFoot:
                            {
                              imageOrientation = FlipDirection.flipX;
                              tappedMap = selectedMap == AnatomyZoneMaps.footBottom
                                  ? AnatomyZoneMaps.footTop
                                  : AnatomyZoneMaps.footBottom;
                              tappedMarkerGroup = markerGroup == BodyMarkerGroup.rightFootBottom
                                  ? BodyMarkerGroup.rightFootTop
                                  : BodyMarkerGroup.rightFootBottom;
                            }
                          case AnatomyMapTapped.leftFoot:
                            {
                              imageOrientation = FlipDirection.none;
                              tappedMap = selectedMap == AnatomyZoneMaps.footBottom
                                  ? AnatomyZoneMaps.footTop
                                  : AnatomyZoneMaps.footBottom;
                              tappedMarkerGroup = markerGroup == BodyMarkerGroup.leftFootBottom
                                  ? BodyMarkerGroup.leftFootTop
                                  : BodyMarkerGroup.leftFootBottom;
                            }
                          case AnatomyMapTapped.none:
                            {
                              tappedMap == selectedMap;
                              tappedMarkerGroup = BodyMarkerGroup.none;
                            }
                        }
                        setState(() {
                          selectedMap = tappedMap;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = touchImage?.flip(imageOrientation);
                          markerGroup = tappedMarkerGroup;
                        });
                        // Use a fixed duration for the flip to ensure it feels like a physical movement
                      },
                    ),
                  ],
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // These are your TRUE dimensions for hit testing
                      final double containerWidth = constraints.maxWidth;
                      final double containerHeight = constraints.maxHeight;
                      Size size = touchImage!.getSizeFromContainer();
                      return Stack(
                        fit: StackFit.loose,
                        children: [
                          GestureDetector(
                            onTapDown: (TapDownDetails details) {
                              Offset tapPosition = details.localPosition;
                              tapPosition = orientOffset(
                                height: containerHeight,
                                width: containerWidth,
                                imageHeight: size.height,
                                imageWidth: size.width,
                                offset: tapPosition,
                                flip: imageOrientation,
                                zoneMap: selectedMap,
                              );
                              final zone = _identifyZone(tapPosition);

                              if (zone.name == "none" || zone.name.isEmpty) {
                                return;
                              }
                              setState(() {
                                final newMarker = BodyMarker(
                                  offset: details.localPosition,
                                  emoji: Sentiment.neutral,
                                  name: zone.name,
                                  medicalName: zone.latin,
                                  zoneMap: zone.map,
                                  group: markerGroup,
                                );

                                // Show the Modal
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  constraints: BoxConstraints(maxHeight: mq.size.height * 0.45),
                                  builder: (context) => BodyMarkerModal(
                                    initialMarker: newMarker,
                                    onSave: (updatedMarker) {
                                      // On Save, update the state to store the new marker
                                      setState(() {
                                        _markers.add(
                                          BodyMarker.fromOffset(
                                            details.localPosition,
                                            zone.name,
                                            zone.latin,
                                            selectedMap,
                                            markerGroup,
                                          ),
                                        );
                                      });
                                    },
                                  ),
                                );
                              });
                              // Here you would trigger your "Hot Button" modal
                            },
                            child: Align(
                              alignment: Alignment.center,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 600),
                                switchInCurve: Curves.easeInOut,
                                switchOutCurve: Curves.easeInOut,
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  final rotateAnim = Tween(begin: pi / 2, end: 0.0).animate(animation);
                                  return AnimatedBuilder(
                                    animation: rotateAnim,
                                    child: child,
                                    builder: (context, child) {
                                      return Transform(
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.001) // Perspective
                                          ..rotateY(rotateAnim.value),
                                        alignment: Alignment.center,
                                        child: child,
                                      );
                                    },
                                  );
                                },
                                // KeyedSubtree forces the animation to re-run whenever 'selectedMap' changes
                                child: KeyedSubtree(key: ValueKey(selectedMap), child: anatomyImage!),
                              ),
                            ),
                          ),

                          // Positioned.fill(
                          //   child: CustomPaint(
                          //     painter: PolygonPainter(
                          //       touchImage!,
                          //       imageOrientation,
                          //       mq.size.width,
                          //       mq.size.height,
                          //       size.height,
                          //     ),
                          //   ),
                          // ),
                          ..._markers
                              .where((marker) => marker.group == markerGroup)
                              .map(
                                (marker) => Positioned(
                                  left: marker.offset.dx - 12,
                                  top: marker.offset.dy - 12,
                                  child: const Icon(Icons.circle, color: Colors.red, size: 24),
                                ),
                              ),
                        ],
                      );
                    },
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
