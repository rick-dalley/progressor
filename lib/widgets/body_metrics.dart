import 'package:flutter/material.dart';

class BodyMetricsWidget extends StatefulWidget {
  final double? weight;
  final double? height;
  final String heightUom;
  final String weightUom;
  final Function(double? weight, double? height) onMetricsChanged;

  const BodyMetricsWidget({
    super.key,
    this.weight,
    this.height,
    this.heightUom = "cm",
    this.weightUom = "kg",
    required this.onMetricsChanged,
  });

  @override
  State<BodyMetricsWidget> createState() => _BodyMetricsWidgetState();
}

class _BodyMetricsWidgetState extends State<BodyMetricsWidget> {
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    // Controllers are instantiated EXACTLY ONCE here, preserving typed text safely
    _heightController = TextEditingController(text: widget.height?.toString() ?? '');
    _weightController = TextEditingController(text: widget.weight?.toString() ?? '');
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /// Grabs the live strings straight out of the controllers and emits them simultaneously
  void _submitData() {
    final double? parsedHeight = double.tryParse(_heightController.text);
    final double? parsedWeight = double.tryParse(_weightController.text);

    widget.onMetricsChanged(parsedWeight, parsedHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 1. HEIGHT SECTION
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Height',
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onFieldSubmitted: (_) => _submitData(),
                      ),
                    ),
                    Text(" (${widget.heightUom})"),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // 2. WEIGHT SECTION
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Weight',
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onFieldSubmitted: (_) => _submitData(),
                      ),
                    ),
                    Text(" (${widget.weightUom})"),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 3. EXPLICIT SAVE ACTION (Guarantees both items save at once)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _submitData,
              child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}