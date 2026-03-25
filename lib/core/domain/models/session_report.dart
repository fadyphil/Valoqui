// lib/core/domain/models/session_report.dart
//
// The full graded session report returned by the LLM after a session ends.
// Placed in core/domain/models (not features/report/models) so that:
//   - GenerateReport use case can return it without importing from a feature layer
//   - ReportBloc, ReportScreen, and any future analytics feature can all import it
//     from a single stable location
//
// All field names use @JsonKey to map from the snake_case JSON the LLM returns.

import "package:freezed_annotation/freezed_annotation.dart";

part "session_report.freezed.dart";
part "session_report.g.dart";

// ── Top-level report ─────────────────────────────────────

@freezed
sealed class SessionReport with _$SessionReport {
  const factory SessionReport({
    @JsonKey(name: "overall_grade") required String overallGrade,
    @JsonKey(name: "fluency_score") required int fluencyScore,
    @JsonKey(name: "grammar_score") required int grammarScore,
    @JsonKey(name: "vocabulary_score") required int vocabularyScore,
    @JsonKey(name: "session_duration_seconds")
    required int sessionDurationSeconds,
    @JsonKey(name: "active_speaking_seconds")
    required int activeSpeakingSeconds,
    @JsonKey(name: "spanish_word_count") required int spanishWordCount,
    @JsonKey(name: "topics_covered") required List<String> topicsCovered,
    required List<MistakeItem> mistakes,
    @JsonKey(name: "vocabulary_highlights")
    required List<VocabularyHighlight> vocabularyHighlights,
    @JsonKey(name: "fluency_note") required String fluencyNote,
    @JsonKey(name: "grammar_note") required String grammarNote,
    @JsonKey(name: "vocabulary_note") required String vocabularyNote,
    required String encouragement,
    @JsonKey(name: "xp_breakdown") required XpBreakdown xpBreakdown,
  }) = _SessionReport;

  factory SessionReport.fromJson(Map<String, dynamic> json) =>
      _$SessionReportFromJson(json);
}

// ── Mistake item ─────────────────────────────────────────

@freezed
sealed class MistakeItem with _$MistakeItem {
  const factory MistakeItem({
    @JsonKey(name: "what_user_said") required String whatUserSaid,
    required String correction,
    required String explanation,
    required String category,
    required String severity,
  }) = _MistakeItem;

  factory MistakeItem.fromJson(Map<String, dynamic> json) =>
      _$MistakeItemFromJson(json);
}

// ── Vocabulary highlight ──────────────────────────────────

@freezed
sealed class VocabularyHighlight with _$VocabularyHighlight {
  const factory VocabularyHighlight({
    required String word,
    required String english,
    required String context,
    @JsonKey(name: "used_correctly") required bool usedCorrectly,
  }) = _VocabularyHighlight;

  factory VocabularyHighlight.fromJson(Map<String, dynamic> json) =>
      _$VocabularyHighlightFromJson(json);
}

// ── XP breakdown ─────────────────────────────────────────

@freezed
sealed class XpBreakdown with _$XpBreakdown {
  const factory XpBreakdown({
    @JsonKey(name: "time_speaking_xp") required int timeSpeakingXp,
    @JsonKey(name: "spanish_words_xp") required int spanishWordsXp,
    @JsonKey(name: "grammar_bonus_xp") required int grammarBonusXp,
    @JsonKey(name: "vocabulary_bonus_xp") required int vocabularyBonusXp,
    @JsonKey(name: "session_completion_xp") required int sessionCompletionXp,
    @JsonKey(name: "first_session_today_xp") required int firstSessionTodayXp,
    @JsonKey(name: "total_xp") required int totalXp,
  }) = _XpBreakdown;

  factory XpBreakdown.fromJson(Map<String, dynamic> json) =>
      _$XpBreakdownFromJson(json);
}
