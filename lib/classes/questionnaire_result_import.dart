import 'dart:convert';

// The receiving half of Ally's completed-questionnaire handoff — no shared backend,
// Ally emails the provider whose body carries a
// progressor://questionnaireResult?data=... deep link. Key names here must match
// Ally's questionnaire_result_export.dart exactly.
class QuestionnaireResultPayload {
  final String patientName;
  final String templateId;
  final int score;
  final String summary;
  final String? action;
  final DateTime answeredAt;

  const QuestionnaireResultPayload({
    required this.patientName,
    required this.templateId,
    required this.score,
    required this.summary,
    this.action,
    required this.answeredAt,
  });

  // Returns null rather than throwing — a malformed or truncated link shouldn't crash
  // the app that just opened it (same reasoning as EmsHandoffImportPayload).
  static QuestionnaireResultPayload? tryParse(Uri uri) {
    final String? encoded = uri.queryParameters['data'];
    if (encoded == null) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(utf8.decode(base64Url.decode(encoded))) as Map<String, dynamic>;
      final String? templateId = json['templateId'] as String?;
      final int? score = json['score'] as int?;
      final String? summary = json['summary'] as String?;
      if (templateId == null || score == null || summary == null) return null;
      return QuestionnaireResultPayload(
        patientName: json['patientName'] as String? ?? 'Unknown Patient',
        templateId: templateId,
        score: score,
        summary: summary,
        action: json['action'] as String?,
        answeredAt: DateTime.tryParse(json['answeredAt'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
