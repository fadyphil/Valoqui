// lib/core/domain/models/conversation_message.dart
//
// A single turn in a conversation — either user or Lucia.
// Used for:
//   - the rolling 8-turn LLM history (SpeakingBloc)
//   - the full session transcript (passed to ReportBloc)
//   - the transcript display in SpeakingScreen and ReportScreen

import "package:freezed_annotation/freezed_annotation.dart";

part "conversation_message.freezed.dart";
part "conversation_message.g.dart";

@freezed
sealed class ConversationMessage with _$ConversationMessage {
  const factory ConversationMessage({
    /// "user" or "assistant" — matches the role strings expected by the
    /// Groq / Gemini chat API.
    required String role,
    required String content,
    required DateTime timestamp,
  }) = _ConversationMessage;

  factory ConversationMessage.fromJson(Map<String, dynamic> json) =>
      _$ConversationMessageFromJson(json);
}

// ── Convenience constructors ────────────────────────────
extension ConversationMessageX on ConversationMessage {
  bool get isUser => role == "user";
  bool get isAssistant => role == "assistant";
}

/// Factory helpers used throughout the codebase.
/// Using top-level functions keeps call sites readable.
ConversationMessage userMessage(String content) => ConversationMessage(
  role: "user",
  content: content,
  timestamp: DateTime.now(),
);

ConversationMessage assistantMessage(String content) => ConversationMessage(
  role: "assistant",
  content: content,
  timestamp: DateTime.now(),
);
