// lib/core/data/repositories/groq_llm_repository.dart
//
// Implements LlmRepository using Groq as primary and Gemini as fallback.
// The fallback is completely transparent — BLoCs and use cases call
// LlmRepository and never know which provider responded.
//
// Fallback trigger:
//   - streamResponse: if Groq yields AppFailure.rateLimitFailure(),
//     the stream switches to Gemini automatically.
//   - generateReport: if Groq returns any failure, retries via Gemini
//     if a Gemini key is configured.
//
// If both providers fail: yields/returns AppFailure.llmBothProvidersFailed().

import "package:flutter/foundation.dart";
import "package:fpdart/fpdart.dart";
import "package:valoqui/core/data/datasources/gemini_llm_datasource.dart";
import "package:valoqui/core/data/datasources/groq_llm_datasource.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/models/conversation_message.dart";
import "package:valoqui/core/domain/repositories/key_storage_repository.dart";
import "package:valoqui/core/domain/repositories/llm_repository.dart";

class GroqLlmRepository implements LlmRepository {
  final GroqLlmDatasource _groq;
  final GeminiLlmDatasource _gemini;
  final KeyStorageRepository _keyStorage;
  String? _cachedGeminiKey;

  GroqLlmRepository({
    required GroqLlmDatasource groq,
    required GeminiLlmDatasource gemini,
    required KeyStorageRepository keyStorage,
  }) : _groq = groq,
       _gemini = gemini,
       _keyStorage = keyStorage;

  // ── Streaming response with automatic fallback ────────
  @override
  Stream<Either<AppFailure, String>> streamResponse({
    required List<ConversationMessage> messages,
    required String systemPrompt,
    int maxTokens = 120,
  }) async* {
    bool hitFailure = false;

    // Attempt Groq first
    await for (final event in _groq.streamResponse(
      messages: messages,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
    )) {
      final shouldFallback = event.fold(
        (f) => f.maybeWhen(
          rateLimitFailure: () => true,
          llmFailure: (_) => true, // Fallback on server errors/timeouts
          networkFailure: (_) => true, // Fallback on connection issues
          orElse: () => false,
        ),
        (_) => false,
      );

      if (shouldFallback) {
        hitFailure = true;
        break; // Exit Groq stream — fall through to Gemini below
      }

      yield event;
    }

    if (!hitFailure) return; // Groq completed successfully

    // ── Groq failed — try Gemini ─────────────────
    debugPrint("[LLM] Groq failed — checking for Gemini fallback");

    final hasGemini = await _hasGeminiKey();
    if (!hasGemini) {
      debugPrint("[LLM] No Gemini key configured — both providers unavailable");
      yield left(const AppFailure.llmBothProvidersFailed());
      return;
    }

    debugPrint("[LLM] Switching to Gemini silently");
    yield* _gemini.streamResponse(
      messages: messages,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
    );
  }

  // ── Report generation with fallback ──────────────────
  @override
  Future<Either<AppFailure, String>> generateReport({
    required String transcript,
    required String userLevel,
  }) async {
    final prompt = _buildReportPrompt(transcript, userLevel);

    // Try Groq first
    final groqResult = await _groq.generateReport(prompt: prompt);

    if (groqResult.isRight()) return groqResult;

    // Groq failed — try Gemini if key is available
    debugPrint("[LLM] Groq report failed — trying Gemini fallback");
    final hasGemini = await _hasGeminiKey();
    if (!hasGemini) return groqResult; // Return original Groq failure

    return _gemini.generateReport(prompt: prompt);
  }

  // ── Helpers ───────────────────────────────────────────

  Future<bool> _hasGeminiKey() async {
    if (_cachedGeminiKey != null && _cachedGeminiKey!.isNotEmpty) return true;

    final result = await _keyStorage.getGeminiKey();
    _cachedGeminiKey = result.fold((_) => "", (key) => key ?? "");
    return _cachedGeminiKey!.isNotEmpty;
  }

  String _buildReportPrompt(String transcript, String userLevel) =>
      """
You are a certified Spanish language examiner trained on the Instituto Cervantes DELE framework.

Analyze the conversation transcript below. The learner's stated level is $userLevel.

Return ONLY a valid JSON object. No preamble, no markdown fences, no explanation. Just the raw JSON object starting with { and ending with }.

{
  "overall_grade": "B+",
  "fluency_score": 72,
  "grammar_score": 65,
  "vocabulary_score": 80,
  "session_duration_seconds": 430,
  "active_speaking_seconds": 247,
  "spanish_word_count": 143,
  "topics_covered": ["greetings", "daily routine", "hobbies"],
  "mistakes": [
    {
      "what_user_said": "Yo soy muy cansado",
      "correction": "Yo estoy muy cansado",
      "explanation": "Use estar for temporary states like tiredness. Ser is for permanent characteristics.",
      "category": "grammar",
      "severity": "minor"
    }
  ],
  "vocabulary_highlights": [
    {
      "word": "emocionado",
      "english": "excited",
      "context": "User learned this word mid-conversation",
      "used_correctly": true
    }
  ],
  "fluency_note": "Good sentence flow with natural rhythm. Hesitation on verb conjugations but recovers quickly.",
  "grammar_note": "Consistent ser/estar confusion. This is the highest-priority item to study next.",
  "vocabulary_note": "Strong range of everyday vocabulary. Begin incorporating connectors: sin embargo, por lo tanto, aunque.",
  "encouragement": "You held a 7-minute conversation entirely in Spanish and learned two new words mid-session. That is real progress.",
  "xp_breakdown": {
    "time_speaking_xp": 33,
    "spanish_words_xp": 28,
    "grammar_bonus_xp": 8,
    "vocabulary_bonus_xp": 15,
    "session_completion_xp": 25,
    "first_session_today_xp": 10,
    "total_xp": 119
  }
}

TRANSCRIPT:
$transcript
""";
}
