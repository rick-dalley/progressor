import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../app_theme.dart';
import '../screens/observation.dart';

class NoteTaker extends StatefulWidget {
  final ObservationNote? currentNote;
  final bool useMicrophone;
  final Function(ObservationNote) onNoteEntered;
  const NoteTaker({super.key, required this.useMicrophone, this.currentNote, required this.onNoteEntered});

  @override
  State<NoteTaker> createState() => NoteTakerState();
}

class NoteTakerState extends State<NoteTaker> {
  // This guarantees text persistence across reactive UI rebuild frames.
  late final TextEditingController _localController;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _localController = TextEditingController(text: widget.currentNote?.content ?? "");
    // _speech = stt.SpeechToText();

    // 🟢 If user tapped the footer mic icon, immediately trigger initialization loop
    if (widget.useMicrophone) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _toggleVoiceDictation());
    }
  }

  Future<void> _toggleVoiceDictation() async {
    if (!_isListening) {
      // // Initialize system microphones and verify platform operating permissions
      // bool available = await _speech.initialize(
      //   onStatus: (status) {
      //     if (status == 'notListening') setState(() => _isListening = false);
      //   },
      //   onError: (val) => setState(() => _listeningError = val.errorMsg),
      // );
      //
      // if (available) {
      //   setState(() {
      //     _isListening = true;
      //     _listeningError = "";
      //   });
      //
      //   // Start capturing streaming audio buffers
      //   _speech.listen(
      //     onResult: (result) {
      //       setState(() {
      //         // Append or set text dynamically as user speaks words out loud
      //         _localController.text = result.recognizedWords;
      //         // Smoothly keep the blinking input cursor anchored at the end of text
      //         _localController.selection = TextSelection.fromPosition(
      //           TextPosition(offset: _localController.text.length),
      //         );
      //       });
      //     },
      //   );
      // }
    } else {
      // Explicit toggle off
      setState(() => _isListening = false);
      // _speech.stop();
    }
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
                    // Visual status text helper showing active listening state
                    Text(
                      _isListening ? "Listening..." : "Edit Observation",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _isListening ? Colors.red : Colors.white
                      ),
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