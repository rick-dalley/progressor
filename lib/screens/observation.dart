import 'package:flutter/material.dart';
import 'package:triage/widgets/observation_card.dart';

import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../widgets/note_taker.dart';

/// 1. Clean Data Model (Strictly for values, completely decoupled from UI scrolling)
class ObservationNote {
  final String id;
  final DateTime timestamp;
  final String content;
  final String authorName;
  final String authorRole; // e.g., "RN", "MD", "Triage Lead"

  ObservationNote({
    required this.id,
    required this.timestamp,
    required this.content,
    required this.authorName,
    required this.authorRole,
  });
}

/// 2. Primary Screen Component
class ObservationScreen extends StatefulWidget {
  final String patientUuid;
  final ScrollController scrollController; // Passed from the modal sheet parent framework

  const ObservationScreen({super.key, required this.patientUuid, required this.scrollController});

  @override
  State<ObservationScreen> createState() => _ObservationScreenState();
}

class _ObservationScreenState extends State<ObservationScreen> {

  List<ObservationNote> _history = [];
  List<ObservationNote> _filtered = [];
  bool _isLoading = true; // Tracks triage system load states cleanly

  @override
  void initState() {
    super.initState();
    _loadPatientObservations(widget.patientUuid); // 👈 Trigger the async load sequence on layout initialization
  }

  // Move this logic inside your text field's onChanged callback instead of a raw getter
  void _onSearchChanged(String val) {
    final lowerQuery = val.toLowerCase().trim();
    setState(() {
      if (lowerQuery.isEmpty) {
        _filtered = List.from(_history);
      } else {
        _filtered = _history
            .where(
              (note) =>
                  note.content.toLowerCase().contains(lowerQuery) || note.authorName.toLowerCase().contains(lowerQuery),
            )
            .toList();
      }
    });
  }
  void _deleteNoteFromSystem(ObservationNote targetNote) async {
    // 1. Instantly clean the item out of your memory state lists
    setState(() {
      _history.removeWhere((element) => element.id == targetNote.id);
      _filtered.removeWhere((element) => element.id == targetNote.id);
    });

    // 2. Fire-and-forget the delete operation to the SQLite disk array
    try {
      await DatabaseManager().deleteObservation(
        int.parse(targetNote.id), // Target the exact numerical primary key
      );
    } catch (e) {
      debugPrint("Failed to purge record from SQLite disk: $e");
      // Fallback: If disk write completely fails, reload truth from database
      _loadPatientObservations(widget.patientUuid);
    }
  }

  void _openNoteWorkspace(BuildContext context, ObservationNote? existingNote, bool useMicrophone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteTaker(
        currentNote: existingNote,
        useMicrophone: useMicrophone,
        onNoteEntered: (ObservationNote completeNote) async {

          if (existingNote == null) {
            // NEW NOTE (ID is empty)
            try {
              // Let the DB handle the autoincrement
              await DatabaseManager().insertObservation({
                'patient_uuid': widget.patientUuid,
                'content': completeNote.content,
                'author_name': completeNote.authorName,
                'author_role': completeNote.authorRole,
                'time_stamp': completeNote.timestamp.toUtc().toIso8601String(),
              });

              // Rebuild the list directly from the database source of truth
              await _loadPatientObservations(widget.patientUuid);
            } catch (e) {
              debugPrint("Failed to insert new note: $e");
            }

          } else {
            // EXISTING NOTE (ID is '1', '2', etc.)
            // Optimistically update the UI list instantly
            setState(() {
              final idx = _history.indexWhere((element) => element.id == completeNote.id);
              if (idx != -1) {
                _history[idx] = completeNote;
                _filtered = List.from(_history); // Repaint the screen immediately
              }
            });

            // Write the update to disk in the background
            try {
              await DatabaseManager().updateObservation(
                int.parse(completeNote.id),
                {
                  'content': completeNote.content,
                },
              );
            } catch (e) {
              debugPrint("Failed to update note on disk: $e");
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.canvasColor,
      child: Column(
        children: [
          // Title Bar & Text Search Layout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟢 Force the Column wrapper block to match the width of the screen boundaries
                Row(children: const [Spacer()]),

                const Text("Clinical Observations", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text("${_filtered.length} Notes", style: const TextStyle(fontSize: 13, color: AppTheme.deepCharcoal)),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // Main Historical Log Feed Viewport
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.amber, // Matches your Apple Notes theme accent color
                    ),
                  )
                : _filtered.isEmpty
                ? Center(
                    child: Text("Enter an observation or note.", style: TextStyle(color: AppTheme.deepCharcoal)),
                  )
                : ListView.builder(
                    // Core unified scroll hooks to eliminate skipping or snapping bugs
                    controller: widget.scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final tappedNote = _filtered[index];

                      // 🟢 Wrap the item in a Dismissible block for easy swiping
                      return Dismissible(
                        key: Key(tappedNote.id), // Tracks the unique primary key string ('1', '2', etc.)
                        direction: DismissDirection.endToStart, // Swipe right-to-left
                        background: Container(
                          color: Colors.red.shade800,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(Icons.delete_sweep, color: Colors.white, size: 26),
                        ),

                        // Fires immediately when the swipe animation completes
                        onDismissed: (direction) {
                          _deleteNoteFromSystem(tappedNote);
                        },

                        child: GestureDetector(
                          onTap: () => _openNoteWorkspace(context, tappedNote, false),
                          child: ObservationCard(note: tappedNote),
                        ),
                      );
                      },
                  ),
          ),

          // Anchored Apple Notes Style Sticky Utility Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: AppTheme.canvasColor),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 🟢 FIXED: Wrapped in Expanded so the TextField takes up the remaining available width safely
                  Expanded(
                    child: TextField(
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Search observations...",
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),
                  // Microphone Button with White Circular Background
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.mic_none_outlined, color: AppTheme.deepCharcoal, size: 26),
                      tooltip: "Dictate Observation",
                      // Open workspace and explicitly pass a custom flag to start recording immediately
                      onPressed: () => _openNoteWorkspace(context, null, true ),
                    ),
                  ),

                  const SizedBox(width: 8), // Cleaned up to an even 8px gap between buttons

                  // Edit Button with White Circular Background
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.deepCharcoal, size: 26),
                      tooltip: "New Observation",
                      onPressed: () => _openNoteWorkspace(context, null, false),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPatientObservations(String patientUuid) async {
    try {
      final List<Map<String, dynamic>> rawRows = await DatabaseManager().getObservationsForPatient(
       patientUuid,
      );

      final List<ObservationNote> loadedNotes = rawRows.map((row) {
        return ObservationNote(
          id: row['id'].toString(),
          timestamp: DateTime.parse(row['time_stamp']).toLocal(),
          content: row['content'] as String,
          authorName: row['author_name'] as String,
          authorRole: row['author_role'] as String,
        );
      }).toList();

      setState(() {
        _history = loadedNotes;
        _filtered = loadedNotes; // 👈 Initially, both lists are identical
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading triage notes: $e");
      setState(() => _isLoading = false);
    }
  }
}
