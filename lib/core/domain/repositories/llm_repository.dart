// lib/core/domain/repositories/llm_repository.dart
//
// Contract for the LLM layer.
// The implementation (GroqLlmRepository) owns the Groq → Gemini fallback
// logic internally. Every caller only sees this interface — they never
// know which provider responded.

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/models/conversation_message.dart";

abstract interface class LlmRepository {
  /// Streams the LLM response token by token.
  ///
  /// [messages] is the rolling 8-turn conversation history.
  /// [systemPrompt] is Lucia's full persona prompt (from LuciaPrompt.build).
  /// [maxTokens] defaults to 120 — enough for 2-3 conversational sentences.
  ///
  /// Yields [Right(token)] for each token.
  /// Yields [Left(AppFailure.rateLimitFailure())] if both providers are rate
  /// limited simultaneously (extremely rare with BYOK architecture).
  /// Yields [Left(AppFailure.llmBothProvidersFailed())] if both providers
  /// fail for any other reason.
  Stream<Either<AppFailure, String>> streamResponse({
    required List<ConversationMessage> messages,
    required String systemPrompt,
    int maxTokens = 120,
  });

  /// Single blocking call for report generation.
  /// Returns the raw JSON string from the LLM.
  /// The GenerateReport use case handles parsing and retry.
  ///
  /// [transcript] is the full session transcript formatted as plain text.
  /// [userLevel] is the user's CEFR level string, e.g. "A2".
  Future<Either<AppFailure, String>> generateReport({
    required String transcript,
    required String userLevel,
  });
}
