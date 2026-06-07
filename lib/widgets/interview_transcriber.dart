import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/patient.dart';

class InterviewModal extends StatefulWidget {
  final Patient patient;
  const InterviewModal({super.key, required this.patient});

  @override
  State<InterviewModal> createState() => _InterviewModalState();
}

class _InterviewModalState extends State<InterviewModal> {
  bool _isRecording = false;
  final TextEditingController _transcriptController = TextEditingController();
  final TextEditingController _observationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),

          // 1. LIVE TRANSCRIPT WINDOW
          Expanded(
            flex: 3,
            child: _buildTextWindow(
              label: "Live Transcript",
              controller: _transcriptController,
              hint: "Speech will appear here...",
              isLive: true,
            ),
          ),

          const SizedBox(height: 16),

          // 2. CLINICAL OBSERVATIONS
          Expanded(
            flex: 2,
            child: _buildTextWindow(
              label: "Clinical Observations",
              controller: _observationController,
              hint: "e.g., Patient avoiding eye contact, pacing...",
              isLive: false,
            ),
          ),

          const Divider(height: 40),

          // 3. MEDIA CONTROLS
          _buildMediaControls(),

          const SizedBox(height: 20),

          // 4. SAVE & PROCESS
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.auto_awesome),
            label: const Text("FINALIZE & SUMMARIZE"),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.replay_10), iconSize: 32),

        // Replaced FAB with a sleek Circle Container
        GestureDetector(
          onTap: () => setState(() => _isRecording = !_isRecording),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red : AppTheme.deepLogicViolet,
              shape: BoxShape.circle,
              border: Border.all(
                color: _isRecording ? Colors.red : AppTheme.deepLogicViolet,
                width: 2,
              ),
            ),
            child: Icon(
              _isRecording ? Icons.pause : Icons.mic,
              size: 32,
              color: AppTheme.clinicalWhite,
            ),
          ),
        ),

        IconButton(onPressed: () {}, icon: const Icon(Icons.forward_10), iconSize: 32),
        IconButton(
            onPressed: () => setState(() => _isRecording = false),
            icon: const Icon(Icons.stop_circle, color: Colors.red),
            iconSize: 40
        ),
      ],
    );
  }

  Widget _buildTextWindow({required String label, required TextEditingController controller, required String hint, bool isLive = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            decoration: InputDecoration(
              hintText: hint,
              fillColor: isLive ? AppTheme.deepLogicViolet.withAlpha(32) : AppTheme.clinicalWhite,
              filled: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.person_pin, size: 40, color: Color(0xFF1A365D)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${widget.patient.firstName} ${widget.patient.lastName}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Interview in Progress...", style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        const Spacer(),
        const Badge(label: Text("LIVE"), child: Icon(Icons.sensors)),
      ],
    );
  }
}