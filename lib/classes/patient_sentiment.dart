import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum Sentiment { happy, content, neutral, dissatisfied, sad, stressed }

class PatientSentiment {
  final IconData iconData;
  final double diameter;
  final Color color;

  const PatientSentiment({required this.iconData, required this.diameter, required this.color});

  Icon getIcon() {
    return Icon(iconData, size: diameter, color: color);
  }
}

Map<Sentiment, PatientSentiment> patientSentiments = {
  Sentiment.happy: PatientSentiment(iconData: Symbols.sentiment_calm, color: Color(0xFF0EBA00), diameter: 32),
  Sentiment.content: PatientSentiment(iconData: Symbols.sentiment_content, color: Colors.blue, diameter: 32),
  Sentiment.neutral: PatientSentiment(iconData: Symbols.sentiment_neutral, color: Colors.blueGrey, diameter: 32),
  Sentiment.dissatisfied: PatientSentiment(
    iconData: Symbols.sentiment_dissatisfied,
    color: Colors.purpleAccent,
    diameter: 32,
  ),
  Sentiment.sad: PatientSentiment(iconData: Symbols.sentiment_sad, color: Colors.orange, diameter: 32),
  Sentiment.stressed: PatientSentiment(iconData: Symbols.sentiment_stressed, color: Colors.red.shade900, diameter: 32),
};
