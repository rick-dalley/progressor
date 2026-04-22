import 'package:flutter/material.dart' show StatefulWidget, TextEditingController, State, BuildContext, Widget, Text, Divider, AppBar, Expanded, Column, Scaffold, ListView, EdgeInsets, TextStyle, CrossAxisAlignment, MainAxisAlignment, FontWeight, Colors, Row, FontStyle, Padding, Card, TextField, InputDecoration, SizedBox, Icon, OutlineInputBorder, ElevatedButton, Icons;

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

class ObservationScreen extends StatefulWidget {
  const ObservationScreen({super.key});

  @override
  State<ObservationScreen> createState() => _ObservationScreenState();
}

class _ObservationScreenState extends State<ObservationScreen> {
  final TextEditingController _noteController = TextEditingController();
  final List<ObservationNote> _history = [
  ]; // This would typically come from your DB

  void _saveNote() {
    if (_noteController.text
        .trim()
        .isEmpty) return;

    setState(() {
      _history.insert(0, ObservationNote(
        id: DateTime.now().toString(),
        timestamp: DateTime.now(),
        content: _noteController.text,
        authorName: "Richard Dalley",
        // Logic to pull current user
        authorRole: "Director of AI",
      ));
      _noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clinical Observations")),
      body: Column(
        children: [
          // 1. New Note Input Area
          _buildNoteInput(),
          const Divider(thickness: 2),
          // 2. Observation History Feed
          Expanded(child: _buildHistoryList()),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _noteController,
            maxLines: 5,
            minLines: 3,
            decoration: const InputDecoration(
              hintText: "Enter clinical observations, interview notes, or behavioral sightings...",
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveNote,
              icon: const Icon(Icons.add_comment),
              label: const Text("Log Observation"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final note = _history[index];
        // Format: Apr 22, 2026 • 11:45 AM
        final timeStr = "${note.timestamp.day}/${note.timestamp.month}/${note.timestamp.year} • "
            "${note.timestamp.hour}:${note.timestamp.minute.toString().padLeft(2, '0')}";

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      note.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  note.authorRole,
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                ),
                const Divider(),
                Text(
                  note.content,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}