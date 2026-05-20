import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../screens/observation.dart';

class NoteTaker extends StatefulWidget {
  final ObservationNote? currentNote;
  final Function(ObservationNote) onNoteEntered;
  const NoteTaker({super.key, this.currentNote, required this.onNoteEntered});

  @override
  State<NoteTaker> createState() => NoteTakerState();
}

class NoteTakerState extends State<NoteTaker> {
  // This guarantees text persistence across reactive UI rebuild frames.
  late final TextEditingController _localController;

  @override
  void initState() {
    super.initState();
    _localController = TextEditingController(text: widget.currentNote?.content ?? "");
  }

  @override
  void dispose() {
    _localController.dispose(); // Clean memory registers when dismissed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, localScrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header Controls Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 15)),
                    ),
                    Text(
                      widget.currentNote == null ? "New Observation" : "Edit Observation",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepCharcoal),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_localController.text.trim().isNotEmpty) {
                          widget.onNoteEntered(
                            ObservationNote(
                              id: widget.currentNote?.id ?? "",
                              timestamp: DateTime.now(),
                              content: _localController.text,
                              authorName: "Richard Dalley",
                              authorRole: "Director of AI",
                            ),
                          );
                        }
                        Navigator.pop(context); // Dismiss editor sheet view
                      },
                      child: const Text(
                        "Done",
                        style: TextStyle(color: AppTheme.deepLogicViolet, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Infinite Canvas Multi-line Input Field Frame
              Expanded(
                child: ListView(
                  controller: localScrollController,
                  padding: const EdgeInsets.all(18),
                  children: [
                    TextField(
                      controller: _localController,
                      maxLines: null,
                      minLines: null,
                      autofocus: true,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(fontSize: 16, height: 1.5, color: AppTheme.deepCharcoal),
                      decoration: const InputDecoration(
                        hintText: "Start typing observation notes or behavioral records...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none, // Clean writing pad paper appearance
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}