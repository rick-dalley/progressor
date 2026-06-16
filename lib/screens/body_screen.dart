import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/patient_sentiment.dart';
import '../classes/body_markers.dart';
import '../classes/body_zone.dart';
import '../classes/patient.dart';
import '../widgets/body_marker_modal.dart';

enum FlipDirection { none, flipX, flipY, flipXY }

class BodyOutlineScreen extends StatefulWidget {
  final Patient patient;

  const BodyOutlineScreen({super.key, required this.patient});

  @override
  State<BodyOutlineScreen> createState() => _BodyOutlineScreenState();
}

class _BodyOutlineScreenState extends State<BodyOutlineScreen> {
  // Example: Store marker points here
  final List<BodyMarker> _markers = [];
  ZoneMaps selectedMap = ZoneMaps.bodyFront;
  FlipDirection imageOrientation = FlipDirection.none;
  TouchImage? touchImage;
  Widget? anatomyImage;
  Offset orientOffset({
    required double height,
    required double width,
    required Offset offset,
    required FlipDirection flip,
    required ZoneMaps zoneMap,
  }) {
    // Define which maps support flipping
    final bool isFlippable = [
      ZoneMaps.handFront,
      ZoneMaps.handBack,
      ZoneMaps.footTop,
      ZoneMaps.footBottom
    ].contains(zoneMap);

    if (!isFlippable || flip == FlipDirection.none) {
      return offset;
    }

    // Calculate new coordinates based on flip type
    double dx = (flip == FlipDirection.flipX || flip == FlipDirection.flipXY)
        ? width - offset.dx
        : offset.dx;

    double dy = (flip == FlipDirection.flipY || flip == FlipDirection.flipXY)
        ? height - offset.dy
        : offset.dy;

    return Offset(dx, dy);
  }

  Widget? orientImage({required Widget? image, required FlipDirection flip}) {
    if (image == null) {
      return image;
    }
    switch (flip) {
      case FlipDirection.none:
        return image;
      case FlipDirection.flipX:
        return Transform.flip(flipX: true, child: image);
      case FlipDirection.flipY:
        return Transform.flip(flipY: true, child: image);
      case FlipDirection.flipXY:
        return Transform.flip(flipX: true, flipY: true, child: image);
    }
  }

  Zone _identifyZone(Offset tap, TouchImage touchImage) {
    ZoneMaps tappedMap = selectedMap;
    FlipDirection selectedImageOrientation = imageOrientation;

    for (var zone in touchImage.zones) {
      if (zone.isIn(tap.dx, tap.dy) && zone.map == selectedMap) {
        //did the user tap on a zone that should bring up a map?
        if (selectedMap == ZoneMaps.bodyFront) {
          if (zone.name == "right hand" || zone.name == "left hand") {
            tappedMap = ZoneMaps.handFront;
            selectedImageOrientation = zone.name == "right hand" && imageOrientation == FlipDirection.none
                ? FlipDirection.flipX
                : FlipDirection.none;
          }
          if (zone.name == "right foot" || zone.name == "left foot") {
            tappedMap = ZoneMaps.footBottom;
            selectedImageOrientation = zone.name == "right foot" && imageOrientation == FlipDirection.none
                ? FlipDirection.flipX
                : FlipDirection.none;
          }
          if (zone.name == "face") {
            tappedMap = ZoneMaps.face;
          }
          setState(() {
            selectedMap = tappedMap;
            imageOrientation = selectedImageOrientation;
            touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
            anatomyImage = orientImage(image: anatomyImage, flip: imageOrientation);
          });
        }
        return zone; // Returns the BodyZones enum
      }
    }
    return touchImage.zones[0];
  }

  @override
  void initState() {
    super.initState();
    imageOrientation = FlipDirection.none;
    selectedMap = ZoneMaps.bodyFront;
    touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap);
    anatomyImage = Image.asset(touchImage!.imagePath, fit: BoxFit.contain);
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
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Symbols.accessibility, size: 30),
                      onPressed: () {
                        setState(() {
                          selectedMap = ZoneMaps.bodyFront;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = Image.asset(touchImage!.imagePath, fit: BoxFit.contain);
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Symbols.front_hand, size: 30),
                      onPressed: () {
                        setState(() {
                          selectedMap = ZoneMaps.handFront;
                          imageOrientation = FlipDirection.flipX;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = orientImage(
                            image: Image.asset(touchImage!.imagePath, fit: BoxFit.contain),
                            flip: imageOrientation,
                          );
                        });
                      },
                    ),
                    IconButton(
                      icon: Transform.flip(flipX: true, child: Icon(Symbols.front_hand, size: 30)),
                      onPressed: () {
                        setState(() {
                          selectedMap = ZoneMaps.handFront;
                          imageOrientation = FlipDirection.none;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = orientImage(
                            image: Image.asset(touchImage!.imagePath, fit: BoxFit.contain),
                            flip: imageOrientation,
                          );
                        });
                      },
                    ),
                    IconButton(
                      icon: Transform.flip(flipY: true, child: Icon(Symbols.barefoot, size: 30)),
                      onPressed: () {
                        setState(() {
                          selectedMap = ZoneMaps.footBottom;
                          imageOrientation = FlipDirection.flipX;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = orientImage(
                            image: Image.asset(touchImage!.imagePath, fit: BoxFit.contain),
                            flip: imageOrientation,
                          );
                        });
                      },
                    ),
                    IconButton(
                      icon: Transform.flip(flipX: true, flipY: true, child: Icon(Symbols.barefoot, size: 30)),
                      onPressed: () {
                        setState(() {
                          selectedMap = ZoneMaps.footBottom;
                          imageOrientation = FlipDirection.none;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = orientImage(
                            image: Image.asset(touchImage!.imagePath, fit: BoxFit.contain),
                            flip: imageOrientation,
                          );
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Symbols.face, size: 30),
                      onPressed: () {
                        setState(() {
                          selectedMap = ZoneMaps.face;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = orientImage(
                            image: Image.asset(touchImage!.imagePath, fit: BoxFit.contain),
                            flip: imageOrientation,
                          );
                        });
                      },
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Symbols.flip, size: 30),
                      onPressed: () {
                        ZoneMaps tappedMap = selectedMap;
                        switch (selectedMap) {
                          case ZoneMaps.bodyFront:
                            {
                              imageOrientation = FlipDirection.flipX;
                              tappedMap = ZoneMaps.bodyBack;
                            }
                          case ZoneMaps.bodyBack:
                            {
                              imageOrientation = FlipDirection.flipX;
                              tappedMap = ZoneMaps.bodyFront;
                            }
                          case ZoneMaps.face:
                            {
                              imageOrientation = FlipDirection.none;
                              tappedMap = ZoneMaps.face;
                            }
                          case ZoneMaps.handFront:
                            {
                              imageOrientation = selectedMap == ZoneMaps.handBack ? FlipDirection.flipX : FlipDirection.flipXY;
                              tappedMap = ZoneMaps.handBack;
                            }
                          case ZoneMaps.handBack:
                            {
                              imageOrientation = selectedMap == ZoneMaps.handFront ? FlipDirection.flipXY : FlipDirection.flipX;
                              tappedMap = ZoneMaps.handFront;
                            }
                          case ZoneMaps.footTop:
                            {
                              imageOrientation = FlipDirection.flipX;
                              tappedMap = ZoneMaps.footBottom;
                            }
                          case ZoneMaps.footBottom:
                            {
                              imageOrientation = FlipDirection.flipX;
                              tappedMap = ZoneMaps.footTop;
                            }
                        }
                        setState(() {
                          selectedMap = tappedMap;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = orientImage(
                            image: Image.asset(touchImage!.imagePath, fit: BoxFit.contain),
                            flip: imageOrientation,
                          );
                        });
                      },
                    ),
                  ],
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Stack(
                    fit: StackFit.loose,
                    children: [
                      GestureDetector(
                        onTapDown: (TapDownDetails details) {
                          Offset tapPosition = details.localPosition;
                          tapPosition = orientOffset(
                            height: mq.size.height,
                            width: mq.size.width,
                            offset: tapPosition,
                            flip: imageOrientation,
                            zoneMap: selectedMap,
                          );
                          final zone = _identifyZone(tapPosition, touchImage!);
                          if (zone.name == "none" || zone.name.isEmpty) {
                            return;
                          }

                          setState(() {
                            final newMarker = BodyMarker(
                              offset: tapPosition,
                              emoji: Sentiment.neutral,
                              name: zone.name,
                              medicalName: zone.latin,
                              zoneMap: zone.map,
                            );

                            // 3. Show the Modal
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              constraints: BoxConstraints(maxHeight: mq.size.height * 0.45),
                              builder: (context) => BodyMarkerModal(
                                initialMarker: newMarker,
                                onSave: (updatedMarker) {
                                  // 4. On Save, update the state to store the new marker
                                  setState(() {
                                    _markers.add(BodyMarker.fromOffset(tapPosition, zone.name, zone.latin, zone.map));
                                    //_markers.add(updatedMarker);
                                  });
                                },
                              ),
                            );
                          });
                          // Here you would trigger your "Hot Button" modal
                        },
                        child: Align(alignment: Alignment.center, child: anatomyImage),
                      ),

                      // Positioned.fill(
                      //   child: CustomPaint(
                      //     painter: PolygonPainter(touchImage!.zones),
                      //   ),
                      // ),
                      ..._markers
                          .where((marker) => marker.zoneMap == selectedMap)
                          .map(
                            (marker) => Positioned(
                              left: marker.offset.dx - 12,
                              top: marker.offset.dy - 12,
                              child: const Icon(Icons.circle, color: Colors.red, size: 24),
                            ),
                          ),
                    ],
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
