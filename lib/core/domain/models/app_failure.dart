// lib/core/domain/models/app_failure.dart
//
// The single failure type for the entire app.
// All layers convert their own error types into AppFailure variants.
// BLoCs and use cases only ever see AppFailure — never FirebaseException,
// DioException, or any other SDK-specific error type.

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

  // ── Network (Sprint 2) ───────────────────────────────
  const factory AppFailure.networkFailure({required String message}) =
      _NetworkFailure;
  const factory AppFailure.rateLimitFailure() = _RateLimitFailure;

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
  );
}
