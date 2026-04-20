import 'package:flutter/material.dart';

class AssessmentScreen extends StatefulWidget {
  final Map<String, dynamic> template;
  // CHANGE 1: Add this optional controller to the class
  final ScrollController? scrollController;

  const AssessmentScreen({
    super.key,
    required this.template,
    this.scrollController, // CHANGE 2: Add it to the constructor
  });

  @override
  _AssessmentScreenState createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  Map<String, int> answers = {};

  int get totalScore => answers.values.fold(0, (sum, val) => sum + val);

  @override
  Widget build(BuildContext context) {
    // Note: I removed Scaffold because the Modal provides its own container/background
    return Column(
      children: [
        // We keep the title but inside the column since Scaffold is gone
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(widget.template['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            // CHANGE 3: Plug the controller in here
            controller: widget.scrollController,
            itemCount: widget.template['questions'].length,
            itemBuilder: (context, index) {
              var q = widget.template['questions'][index];
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q['text'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(q['max_score'] + 1, (score) {
                        return ChoiceChip(
                          label: Text(score.toString()),
                          selected: answers[q['id']] == score,
                          onSelected: (selected) {
                            setState(() => answers[q['id']] = score);
                          },
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _buildScoreFooter(),
      ],
    );
  }

  Widget _buildScoreFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.blueGrey.shade50,
      child: Column(
        children: [
          Text("Current Score: $totalScore", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              print("Saving assessment with score: $totalScore");
              Navigator.pop(context); // Close the modal after saving
            },
            child: const Text("Finalize & Map to DSM"),
          )
        ],
      ),
    );
  }
}