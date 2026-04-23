import 'package:flutter/material.dart';

class QuestionWidget extends StatefulWidget {
  final Map<String, dynamic> question;
  const QuestionWidget({super.key, required this.question});

  @override
  QuestionWidgetState createState() => QuestionWidgetState();
}

class QuestionWidgetState extends State<QuestionWidget> {
  bool _showNote = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ... The Question Text and ChoiceChips ...

        Row(
          children: [
            const Spacer(),
            IconButton(
              icon: Icon(Icons.edit_note, color: _showNote ? Colors.blue : Colors.grey),
              onPressed: () => setState(() => _showNote = !_showNote),
            ),
          ],
        ),

        if (_showNote || _noteController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: "Add margin note...",
                border: OutlineInputBorder(),
              ),
              maxLines: null, // Allows the note to grow as they type
            ),
          ),
      ],
    );
  }
}