


import 'package:triage/classes/database_manager.dart';

class TemplateText{
  final String code;
  final String text;

  TemplateText({required this.code, required this.text});

  factory TemplateText.fromJson(Map<String, dynamic> item){
    return TemplateText(code: item["code"], text: item["text"]);
  }

  Future<String> getTextForCode({required String code}) async {
    String? dbText =  await DatabaseManager().getTemplateTextForCode(code);
    return dbText ?? "";
  }

  Map<String, dynamic> toJson() {
    return {
      "code": code,
      "text": text,
    };
  }
}

