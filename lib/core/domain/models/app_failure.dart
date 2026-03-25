// lib/core/domain/models/app_failure.dart
//
// The single failure type for the entire app.
// All layers convert their own error types into AppFailure variants.
// BLoCs and use cases only ever see AppFailure — never FirebaseException,
// DioException, or any other SDK-specific error type.
//
// Sprint 2 additions:
//   STT  — sttPermissionDenied, sttNotAvailable, sttFailure
//   TTS  — ttsNotInitialized, ttsFailure
//   LLM  — llmFailure, llmBothProvidersFailed
//   Report — reportGenerationFailed, reportParsingFailed

import "package:freezed_annotation/freezed_annotation.dart";

part "app_failure.freezed.dart";

@freezed
sealed class AppFailure with _$AppFailure {
  const AppFailure._();

  // ── Auth ─────────────────────────────────────────────
  const factory AppFailure.signInCancelled() = _SignInCancelled;
  const factory AppFailure.authFailure({required String message}) =
      _AuthFailure;

  // ── Firestore ────────────────────────────────────────
  const factory AppFailure.userNotFound() = _UserNotFound;
  const factory AppFailure.databaseFailure({required String message}) =
      _DatabaseFailure;

  // ── Key storage ──────────────────────────────────────
  const factory AppFailure.storageFailure({required String message}) =
      _StorageFailure;

  // ── API keys ─────────────────────────────────────────
  const factory AppFailure.invalidApiKey() = _InvalidApiKey;

  // ── Network (generic) ────────────────────────────────
  const factory AppFailure.networkFailure({required String message}) =
      _NetworkFailure;
  const factory AppFailure.rateLimitFailure() = _RateLimitFailure;

  // ── STT ──────────────────────────────────────────────
  const factory AppFailure.sttPermissionDenied() = _SttPermissionDenied;
  const factory AppFailure.sttNotAvailable() = _SttNotAvailable;
  const factory AppFailure.sttFailure({required String message}) = _SttFailure;

  // ── TTS ──────────────────────────────────────────────
  const factory AppFailure.ttsNotInitialized() = _TtsNotInitialized;
  const factory AppFailure.ttsFailure({required String message}) = _TtsFailure;

  // ── LLM ──────────────────────────────────────────────
  const factory AppFailure.llmFailure({required String message}) = _LlmFailure;
  const factory AppFailure.llmBothProvidersFailed() = _LlmBothProvidersFailed;

  // ── Report ───────────────────────────────────────────
  const factory AppFailure.reportGenerationFailed({required String message}) =
      _ReportGenerationFailed;
  const factory AppFailure.reportParsingFailed() = _ReportParsingFailed;

  // ── Human-readable message for any variant ───────────
  String get message => when(
    signInCancelled: () => "Sign in was cancelled.",
    authFailure: (msg) => msg,
    userNotFound: () => "User profile not found.",
    databaseFailure: (msg) => msg,
    storageFailure: (msg) => msg,
    invalidApiKey: () =>
        "This key doesn't seem to work — try copying it again.",
    networkFailure: (msg) => msg,
    rateLimitFailure: () => "Rate limit reached. Try again shortly.",
    sttPermissionDenied: () =>
        "Microphone permission is required for conversations.",
    sttNotAvailable: () =>
        "Speech recognition is not available on this device.",
    sttFailure: (msg) => msg,
    ttsNotInitialized: () => "Voice output failed to initialize.",
    ttsFailure: (msg) => msg,
    llmFailure: (msg) => msg,
    llmBothProvidersFailed: () =>
        "Both AI providers are unavailable. Try again in a few minutes.",
    reportGenerationFailed: (msg) => msg,
    reportParsingFailed: () =>
        "Could not generate your report. Your XP has been saved.",
  );
}
