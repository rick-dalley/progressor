import 'package:flutter/material.dart';

class BodyOutlineScreen extends StatefulWidget {
  const BodyOutlineScreen({super.key});

  @override
  State<BodyOutlineScreen> createState() => _BodyOutlineScreenState();
}

class _BodyOutlineScreenState extends State<BodyOutlineScreen> {
  // Example: Store marker points here
  final List<Offset> _markers = [];

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
          title: const Text("Vital Signs"),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
          actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})],
        ),
        body: SafeArea(
          child: GestureDetector(
            onTapDown: (TapDownDetails details) {
              // Get the tap location relative to the container
              setState(() {
                _markers.add(details.localPosition);
              });
              // Here you would trigger your "Hot Button" modal
            },
            child: Stack(
              children: [
                // Full screen body image
                Positioned.fill(child: Image.asset('assets/images/body.png', fit: BoxFit.contain)),
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
      ),
    );
  }
}
