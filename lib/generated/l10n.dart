// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `How to Score the PHQ-9`
  String get phq9_header {
    return Intl.message(
      'How to Score the PHQ-9',
      name: 'phq9_header',
      desc: 'Instructional header for the PHQ-9 scoring',
      args: [],
    );
  }

  /// `If you checked off any problems, how difficult have these problems made it for you to do your work, take care of things at home, or get along with other people? `
  String get phq9_impact {
    return Intl.message(
      'If you checked off any problems, how difficult have these problems made it for you to do your work, take care of things at home, or get along with other people? ',
      name: 'phq9_impact',
      desc: '',
      args: [],
    );
  }

  /// `Not difficult at all`
  String get phq9_impact_chk0 {
    return Intl.message(
      'Not difficult at all',
      name: 'phq9_impact_chk0',
      desc: '',
      args: [],
    );
  }

  /// `Somewhat difficult`
  String get phq9_impact_chk1 {
    return Intl.message(
      'Somewhat difficult',
      name: 'phq9_impact_chk1',
      desc: '',
      args: [],
    );
  }

  /// `Very difficult`
  String get phq9_impact_chk2 {
    return Intl.message(
      'Very difficult',
      name: 'phq9_impact_chk2',
      desc: '',
      args: [],
    );
  }

  /// `Extremely difficult`
  String get phq9_impact_chk3 {
    return Intl.message(
      'Extremely difficult',
      name: 'phq9_impact_chk3',
      desc: '',
      args: [],
    );
  }

  /// `Major depressive disorder (MDD) is suggested if:`
  String get phq9_suggestion_1 {
    return Intl.message(
      'Major depressive disorder (MDD) is suggested if:',
      name: 'phq9_suggestion_1',
      desc: '',
      args: [],
    );
  }

  /// `Of the 9 items,5 or more are checked as at least more than half the days`
  String get phq9_suggestion_1_why_1 {
    return Intl.message(
      'Of the 9 items,5 or more are checked as at least more than half the days',
      name: 'phq9_suggestion_1_why_1',
      desc: '',
      args: [],
    );
  }

  /// `Either item 1 or 2 is checked as at least 'more than half the days'`
  String get phq9_suggestion_1_why_2 {
    return Intl.message(
      'Either item 1 or 2 is checked as at least \'more than half the days\'',
      name: 'phq9_suggestion_1_why_2',
      desc: '',
      args: [],
    );
  }

  /// `Other depressive syndrome is suggested if:`
  String get phq9_suggestion_2 {
    return Intl.message(
      'Other depressive syndrome is suggested if:',
      name: 'phq9_suggestion_2',
      desc: '',
      args: [],
    );
  }

  /// `Of the 9 items, between 2 to 4 are checked as at least more than half the days:`
  String get phq9_suggestion_2_why_1 {
    return Intl.message(
      'Of the 9 items, between 2 to 4 are checked as at least more than half the days:',
      name: 'phq9_suggestion_2_why_1',
      desc: '',
      args: [],
    );
  }

  /// `Either item 1 or 2 is checked as at least 'more than half the days'`
  String get phq9_suggestion_2_why_2 {
    return Intl.message(
      'Either item 1 or 2 is checked as at least \'more than half the days\'',
      name: 'phq9_suggestion_2_why_2',
      desc: '',
      args: [],
    );
  }

  /// `PHQ-9 scores can be used to plan and monitor treatment. To score the instrument, tally the numbers of all the checked responses under each heading (not at all=0, several days=1, more than half the days=2, and nearly every day=3). Add the numbers together to total the score on the bottom of the questionnaire. Interpret the score by using the guide listed below.  `
  String get phq9_scoring_instructions {
    return Intl.message(
      'PHQ-9 scores can be used to plan and monitor treatment. To score the instrument, tally the numbers of all the checked responses under each heading (not at all=0, several days=1, more than half the days=2, and nearly every day=3). Add the numbers together to total the score on the bottom of the questionnaire. Interpret the score by using the guide listed below.  ',
      name: 'phq9_scoring_instructions',
      desc: '',
      args: [],
    );
  }

  /// `PHQ-9 is adapted from PRIME MD TODAY, developed by Drs Spitzer, Williams, Kroenke and colleagues, with an educational grant from Pfizer Inc. Use of the PHQ-9 may only be made in accordance with the Terms of Use available at www.pfizer.com. Copyright © 1999 Pfizer Inc. All rights reserved. PRIME MD TODAY is a trademark of Pfizer Inc. `
  String get phq9_copyright {
    return Intl.message(
      'PHQ-9 is adapted from PRIME MD TODAY, developed by Drs Spitzer, Williams, Kroenke and colleagues, with an educational grant from Pfizer Inc. Use of the PHQ-9 may only be made in accordance with the Terms of Use available at www.pfizer.com. Copyright © 1999 Pfizer Inc. All rights reserved. PRIME MD TODAY is a trademark of Pfizer Inc. ',
      name: 'phq9_copyright',
      desc: '',
      args: [],
    );
  }

  /// `Guide for Interpreting PHQ-9 Scores`
  String get phq9_guide_ttl {
    return Intl.message(
      'Guide for Interpreting PHQ-9 Scores',
      name: 'phq9_guide_ttl',
      desc: '',
      args: [],
    );
  }

  /// `Score`
  String get phq9_guide_hdr0 {
    return Intl.message('Score', name: 'phq9_guide_hdr0', desc: '', args: []);
  }

  /// `Depression Severity`
  String get phq9_guide_hdr1 {
    return Intl.message(
      'Depression Severity',
      name: 'phq9_guide_hdr1',
      desc: '',
      args: [],
    );
  }

  /// `Action`
  String get phq9_guide_hdr2 {
    return Intl.message('Action', name: 'phq9_guide_hdr2', desc: '', args: []);
  }

  /// `0-4`
  String get phq9_guide_r0c0 {
    return Intl.message('0-4', name: 'phq9_guide_r0c0', desc: '', args: []);
  }

  /// `None-minimal`
  String get phq9_guide_r0c1 {
    return Intl.message(
      'None-minimal',
      name: 'phq9_guide_r0c1',
      desc: '',
      args: [],
    );
  }

  /// `Patient may not need depression treatment`
  String get phq9_guide_r0c2 {
    return Intl.message(
      'Patient may not need depression treatment',
      name: 'phq9_guide_r0c2',
      desc: '',
      args: [],
    );
  }

  /// `5-9`
  String get phq9_guide_r1c0 {
    return Intl.message('5-9', name: 'phq9_guide_r1c0', desc: '', args: []);
  }

  /// `Mild`
  String get phq9_guide_r1c1 {
    return Intl.message('Mild', name: 'phq9_guide_r1c1', desc: '', args: []);
  }

  /// `Use clinical judgment about treatment, based on patient's duration of symptoms and functional impairment`
  String get phq9_guide_r1c2 {
    return Intl.message(
      'Use clinical judgment about treatment, based on patient\'s duration of symptoms and functional impairment',
      name: 'phq9_guide_r1c2',
      desc: '',
      args: [],
    );
  }

  /// `10-14`
  String get phq9_guide_r2c0 {
    return Intl.message('10-14', name: 'phq9_guide_r2c0', desc: '', args: []);
  }

  /// `Moderate`
  String get phq9_guide_r2c1 {
    return Intl.message(
      'Moderate',
      name: 'phq9_guide_r2c1',
      desc: '',
      args: [],
    );
  }

  /// `Use clinical judgment about treatment, based on patient's duration of symptoms and functional impairment`
  String get phq9_guide_r2c2 {
    return Intl.message(
      'Use clinical judgment about treatment, based on patient\'s duration of symptoms and functional impairment',
      name: 'phq9_guide_r2c2',
      desc: '',
      args: [],
    );
  }

  /// `15-19`
  String get phq9_guide_r3c0 {
    return Intl.message('15-19', name: 'phq9_guide_r3c0', desc: '', args: []);
  }

  /// `Moderately Severe`
  String get phq9_guide_r3c1 {
    return Intl.message(
      'Moderately Severe',
      name: 'phq9_guide_r3c1',
      desc: '',
      args: [],
    );
  }

  /// `Treat using antidepressants, psychotherapy or a combination of treatment`
  String get phq9_guide_r3c2 {
    return Intl.message(
      'Treat using antidepressants, psychotherapy or a combination of treatment',
      name: 'phq9_guide_r3c2',
      desc: '',
      args: [],
    );
  }

  /// `20-27`
  String get phq9_guide_r4c0 {
    return Intl.message('20-27', name: 'phq9_guide_r4c0', desc: '', args: []);
  }

  /// `Severe`
  String get phq9_guide_r4c1 {
    return Intl.message('Severe', name: 'phq9_guide_r4c1', desc: '', args: []);
  }

  /// `Treat using antidepressants with or without psychotherapy`
  String get phq9_guide_r4c2 {
    return Intl.message(
      'Treat using antidepressants with or without psychotherapy',
      name: 'phq9_guide_r4c2',
      desc: '',
      args: [],
    );
  }

  /// `Mild Depression: Use clinical judgment about treatment...`
  String get phq9_score_mild {
    return Intl.message(
      'Mild Depression: Use clinical judgment about treatment...',
      name: 'phq9_score_mild',
      desc: '',
      args: [],
    );
  }

  /// `Functional Health Assessment`
  String get phq9_functional_health_assessment_ttl {
    return Intl.message(
      'Functional Health Assessment',
      name: 'phq9_functional_health_assessment_ttl',
      desc: '',
      args: [],
    );
  }

  /// `The instrument also includes a functional health assessment. This asks the patient how emotional difficulties or problems impact work, life at home, or relationships with other people. Patient response of ‘very difficult’ or ‘extremely difficult’ suggest that the patient’s functionality is impaired. After treatment begins, functional status and number score can be measured to assess patient improvement.`
  String get phq9_functional_health_assessment_dsc {
    return Intl.message(
      'The instrument also includes a functional health assessment. This asks the patient how emotional difficulties or problems impact work, life at home, or relationships with other people. Patient response of ‘very difficult’ or ‘extremely difficult’ suggest that the patient’s functionality is impaired. After treatment begins, functional status and number score can be measured to assess patient improvement.',
      name: 'phq9_functional_health_assessment_dsc',
      desc: '',
      args: [],
    );
  }

  /// `Note:`
  String get phq9_note_ttl {
    return Intl.message('Note:', name: 'phq9_note_ttl', desc: '', args: []);
  }

  /// `Depression should not be diagnosed or excluded solely on the basis of a PHQ-9 score. A PHQ-9 score  ≥ 10 has a sensitivity of 88% and a specificity of 88% for major depression.1 Since the questionnaire relies on patient self-report, the practitioner should verify all responses. A definitive diagnosis is made taking into account how well the patient understood the questionnaire, as well as other relevant information from the patient.`
  String get phq9_note_description {
    return Intl.message(
      'Depression should not be diagnosed or excluded solely on the basis of a PHQ-9 score. A PHQ-9 score  ≥ 10 has a sensitivity of 88% and a specificity of 88% for major depression.1 Since the questionnaire relies on patient self-report, the practitioner should verify all responses. A definitive diagnosis is made taking into account how well the patient understood the questionnaire, as well as other relevant information from the patient.',
      name: 'phq9_note_description',
      desc: '',
      args: [],
    );
  }

  /// `Kroenke K, Spitzer RL, Williams JB. The PHQ-9: Validity of a brief depression severity measure. J Gen Intern Med. 2001;16(9):606-613`
  String get phq9_reference {
    return Intl.message(
      'Kroenke K, Spitzer RL, Williams JB. The PHQ-9: Validity of a brief depression severity measure. J Gen Intern Med. 2001;16(9):606-613',
      name: 'phq9_reference',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[Locale.fromSubtags(languageCode: 'en')];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
