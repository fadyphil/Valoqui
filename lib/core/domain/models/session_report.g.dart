// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionReport _$SessionReportFromJson(Map<String, dynamic> json) =>
    _SessionReport(
      overallGrade: json['overall_grade'] as String,
      fluencyScore: (json['fluency_score'] as num).toInt(),
      grammarScore: (json['grammar_score'] as num).toInt(),
      vocabularyScore: (json['vocabulary_score'] as num).toInt(),
      sessionDurationSeconds: (json['session_duration_seconds'] as num).toInt(),
      activeSpeakingSeconds: (json['active_speaking_seconds'] as num).toInt(),
      spanishWordCount: (json['spanish_word_count'] as num).toInt(),
      topicsCovered: (json['topics_covered'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      mistakes: (json['mistakes'] as List<dynamic>)
          .map((e) => MistakeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      vocabularyHighlights: (json['vocabulary_highlights'] as List<dynamic>)
          .map((e) => VocabularyHighlight.fromJson(e as Map<String, dynamic>))
          .toList(),
      fluencyNote: json['fluency_note'] as String,
      grammarNote: json['grammar_note'] as String,
      vocabularyNote: json['vocabulary_note'] as String,
      encouragement: json['encouragement'] as String,
      xpBreakdown: XpBreakdown.fromJson(
        json['xp_breakdown'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$SessionReportToJson(_SessionReport instance) =>
    <String, dynamic>{
      'overall_grade': instance.overallGrade,
      'fluency_score': instance.fluencyScore,
      'grammar_score': instance.grammarScore,
      'vocabulary_score': instance.vocabularyScore,
      'session_duration_seconds': instance.sessionDurationSeconds,
      'active_speaking_seconds': instance.activeSpeakingSeconds,
      'spanish_word_count': instance.spanishWordCount,
      'topics_covered': instance.topicsCovered,
      'mistakes': instance.mistakes,
      'vocabulary_highlights': instance.vocabularyHighlights,
      'fluency_note': instance.fluencyNote,
      'grammar_note': instance.grammarNote,
      'vocabulary_note': instance.vocabularyNote,
      'encouragement': instance.encouragement,
      'xp_breakdown': instance.xpBreakdown,
    };

_MistakeItem _$MistakeItemFromJson(Map<String, dynamic> json) => _MistakeItem(
  whatUserSaid: json['what_user_said'] as String,
  correction: json['correction'] as String,
  explanation: json['explanation'] as String,
  category: json['category'] as String,
  severity: json['severity'] as String,
);

Map<String, dynamic> _$MistakeItemToJson(_MistakeItem instance) =>
    <String, dynamic>{
      'what_user_said': instance.whatUserSaid,
      'correction': instance.correction,
      'explanation': instance.explanation,
      'category': instance.category,
      'severity': instance.severity,
    };

_VocabularyHighlight _$VocabularyHighlightFromJson(Map<String, dynamic> json) =>
    _VocabularyHighlight(
      word: json['word'] as String,
      english: json['english'] as String,
      context: json['context'] as String,
      usedCorrectly: json['used_correctly'] as bool,
    );

Map<String, dynamic> _$VocabularyHighlightToJson(
  _VocabularyHighlight instance,
) => <String, dynamic>{
  'word': instance.word,
  'english': instance.english,
  'context': instance.context,
  'used_correctly': instance.usedCorrectly,
};

_XpBreakdown _$XpBreakdownFromJson(Map<String, dynamic> json) => _XpBreakdown(
  timeSpeakingXp: (json['time_speaking_xp'] as num).toInt(),
  spanishWordsXp: (json['spanish_words_xp'] as num).toInt(),
  grammarBonusXp: (json['grammar_bonus_xp'] as num).toInt(),
  vocabularyBonusXp: (json['vocabulary_bonus_xp'] as num).toInt(),
  sessionCompletionXp: (json['session_completion_xp'] as num).toInt(),
  firstSessionTodayXp: (json['first_session_today_xp'] as num).toInt(),
  totalXp: (json['total_xp'] as num).toInt(),
);

Map<String, dynamic> _$XpBreakdownToJson(_XpBreakdown instance) =>
    <String, dynamic>{
      'time_speaking_xp': instance.timeSpeakingXp,
      'spanish_words_xp': instance.spanishWordsXp,
      'grammar_bonus_xp': instance.grammarBonusXp,
      'vocabulary_bonus_xp': instance.vocabularyBonusXp,
      'session_completion_xp': instance.sessionCompletionXp,
      'first_session_today_xp': instance.firstSessionTodayXp,
      'total_xp': instance.totalXp,
    };
