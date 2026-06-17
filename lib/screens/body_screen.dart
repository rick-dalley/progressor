import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../classes/body_markers.dart';
import '../classes/body_zone.dart';
import '../classes/patient.dart';
import '../widgets/body_marker_modal.dart';

enum FlipDirection { none, flipX, flipY, flipXY }
enum ZoneRequested { none, body, rightHand, leftHand, rightFoot, leftFoot, face}

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
  ZoneRequested zoneRequested = ZoneRequested.body;

  Offset orientOffset({
    required double height,
    required double width,
    required double imageHeight,
    required double imageWidth,
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
        ? height - offset.dy - ((height -imageHeight) * 0.5)
        : offset.dy;

    return Offset(dx, dy);
  }

  Zone _identifyZone(Offset tap) {

    for (var zone in touchImage!.zones) {
      if (zone.isIn(tap.dx, tap.dy) && zone.map == selectedMap) {
        //did the user tap on a zone that should bring up a map?
        if(zone.isLink){
          setImageMapFromZone(zone);
          return touchImage!.zones.first;
        } else {
          return zone;
        }
      }
    }
    return touchImage!.zones.first;
  }

  bool setImageMapFromZone(Zone zone) {
    ZoneMaps tappedMap = selectedMap;
    ZoneRequested requested = zoneRequested;
    bool isZoneAnImageHotspot = false;
    FlipDirection selectedImageOrientation = imageOrientation;
    //did the user tap on a zone that should bring up a map?
      if(zone.name == "right hand"){
        isZoneAnImageHotspot = true;
        requested = ZoneRequested.rightHand;
        tappedMap = selectedMap == ZoneMaps.bodyFront ? ZoneMaps.handFront : ZoneMaps.handBack;
        selectedImageOrientation = FlipDirection.flipX;
      } else if (zone.name == "left hand"){
        isZoneAnImageHotspot = true;
        requested = ZoneRequested.leftHand;
        tappedMap = selectedMap == ZoneMaps.bodyFront ? ZoneMaps.handFront : ZoneMaps.handBack;
        selectedImageOrientation = FlipDirection.none;
      } else if (zone.name == "right foot"){
        isZoneAnImageHotspot = true;
        requested = ZoneRequested.rightFoot;
        tappedMap = selectedMap == ZoneMaps.bodyFront ? ZoneMaps.footTop : ZoneMaps.footBottom;
        selectedImageOrientation = FlipDirection.flipX;
      } else if (zone.name == "left foot"){
        isZoneAnImageHotspot = true;
        requested = ZoneRequested.rightFoot;
        tappedMap = selectedMap == ZoneMaps.bodyFront ? ZoneMaps.footTop : ZoneMaps.footBottom;
        selectedImageOrientation = FlipDirection.none;
      } else if (zone.name == "face") {
        isZoneAnImageHotspot = true;
        requested = ZoneRequested.face;
        tappedMap = ZoneMaps.face;
        selectedImageOrientation = FlipDirection.none;
      }
    setState(() {
      zoneRequested = requested;
      selectedMap = tappedMap;
      imageOrientation = selectedImageOrientation;
      touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
      anatomyImage = touchImage!.flip(imageOrientation);
      debugPrint("$selectedMap");
    });
    return isZoneAnImageHotspot;
  }

  @override
  void initState() {
    super.initState();
    imageOrientation = FlipDirection.none;
    selectedMap = ZoneMaps.bodyFront;
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
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Symbols.accessibility, size: 30),
                      onPressed: () {
                        setState(() {
                          zoneRequested = ZoneRequested.body;
                          selectedMap = ZoneMaps.bodyFront;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = touchImage?.flip(imageOrientation);
                        });
                      },
                    ),
                    //Right Hand
                    IconButton(
                      icon: Icon(Symbols.front_hand, size: 30),
                      onPressed: () {
                        setState(() {
                          zoneRequested = ZoneRequested.rightHand;
                          selectedMap = ZoneMaps.handFront;
                          imageOrientation = FlipDirection.flipX;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = touchImage?.flip(imageOrientation);
                        });
                      },
                    ),
                    //Left Hand
                    IconButton(
                      icon: Transform.flip(flipX: true, child: Icon(Symbols.front_hand, size: 30)),
                      onPressed: () {
                        setState(() {
                          zoneRequested = ZoneRequested.leftHand;
                          selectedMap = ZoneMaps.handFront;
                          imageOrientation = FlipDirection.none;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = touchImage?.flip(imageOrientation);
                        });
                      },
                    ),
                    IconButton(
                      icon: Transform.flip(flipY: true, child: Icon(Symbols.barefoot, size: 30)),
                      onPressed: () {
                        setState(() {
                          zoneRequested = ZoneRequested.rightFoot;
                          selectedMap = ZoneMaps.footBottom;
                          imageOrientation = FlipDirection.flipX;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = touchImage?.flip(imageOrientation);
                        });
                      },
                    ),
                    IconButton(
                      icon: Transform.flip(flipX: true, flipY: true, child: Icon(Symbols.barefoot, size: 30)),
                      onPressed: () {
                        setState(() {
                          zoneRequested = ZoneRequested.leftFoot;
                          selectedMap = ZoneMaps.footBottom;
                          imageOrientation = FlipDirection.none;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = touchImage?.flip(imageOrientation);
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Symbols.face, size: 30),
                      onPressed: () {
                        setState(() {
                          zoneRequested = ZoneRequested.face;
                          selectedMap = ZoneMaps.face;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = touchImage?.flip(imageOrientation);
                        });
                      },
                    ),
                    Spacer(),

                    //Flip
                    IconButton(
                      icon: Icon(Symbols.flip, size: 30),
                      onPressed: () {
                        ZoneMaps tappedMap = selectedMap;
                        switch (zoneRequested) {
                          case ZoneRequested.body:
                            {
                              imageOrientation = FlipDirection.none;
                              tappedMap = selectedMap == ZoneMaps.bodyBack ? ZoneMaps.bodyFront : ZoneMaps.bodyBack;
                            }
                          case ZoneRequested.face:
                            {
                              imageOrientation = FlipDirection.none;
                              tappedMap = ZoneMaps.face;
                            }
                          case ZoneRequested.rightHand:
                            {
                              imageOrientation = FlipDirection.flipX ;
                              tappedMap = selectedMap == ZoneMaps.handBack ? ZoneMaps.handFront : ZoneMaps.handBack;
                            }
                          case ZoneRequested.leftHand:
                            {
                              imageOrientation = FlipDirection.none;
                              tappedMap = selectedMap == ZoneMaps.handFront ? ZoneMaps.handBack : ZoneMaps.handFront;
                            }
                          case ZoneRequested.rightFoot:
                            {
                              imageOrientation = FlipDirection.flipX;
                              tappedMap = selectedMap == ZoneMaps.footBottom ? ZoneMaps.footTop : ZoneMaps.footBottom;
                            }
                          case ZoneRequested.leftFoot:
                            {
                              imageOrientation = FlipDirection.none;
                              tappedMap = selectedMap == ZoneMaps.footBottom ? ZoneMaps.footTop : ZoneMaps.footBottom;
                            }
                          case ZoneRequested.none:
                            tappedMap == selectedMap;
                        }
                        setState(() {
                          selectedMap = tappedMap;
                          touchImage = TouchImageFactory.instance.getTouchImage(selection: selectedMap)!;
                          anatomyImage = touchImage?.flip(imageOrientation);
                        });
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
                                offset: tapPosition,
                                emoji: Sentiment.neutral,
                                name: zone.name,
                                medicalName: zone.latin,
                                zoneMap: zone.map,
                              );

                              // Show the Modal
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                constraints: BoxConstraints(maxHeight: mq.size.height * 0.45),
                                builder: (context) =>
                                    BodyMarkerModal(
                                      initialMarker: newMarker,
                                      onSave: (updatedMarker) {
                                        // On Save, update the state to store the new marker
                                        setState(() {
                                          _markers.add(
                                              BodyMarker.fromOffset(tapPosition, zone.name, zone.latin, zone.map));
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
                        //     painter: PolygonPainter(touchImage!, imageOrientation, mq.size.width, mq.size.height, size.height)
                        //   ),
                        // ),

                        ..._markers
                            .where((marker) => marker.zoneMap == selectedMap)
                            .map(
                              (marker) =>
                              Positioned(
                                left: marker.offset.dx - 12,
                                top: marker.offset.dy - 12,
                                child: const Icon(Icons.circle, color: Colors.red, size: 24),
                              ),
                        ),
                      ],
                    );
                  }
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
