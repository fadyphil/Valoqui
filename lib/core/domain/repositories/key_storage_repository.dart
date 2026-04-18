// lib/core/domain/repositories/key_storage_repository.dart
//
// Defines the contract for storing sensitive API keys and onboarding state.
// The current implementation uses Android Keystore via flutter_secure_storage.
// Swapping to iOS Keychain, a hardware key, or any other store requires
// only a new implementation of this interface — nothing else changes.

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";

abstract interface class KeyStorageRepository {
  // ── Groq key ──────────────────────────────────────────
  Future<Either<AppFailure, void>> saveGroqKey(String key);
  Future<Either<AppFailure, String?>> getGroqKey();
  Future<Either<AppFailure, bool>> hasGroqKey();

  // ── Gemini key ────────────────────────────────────────
  Future<Either<AppFailure, void>> saveGeminiKey(String key);
  Future<Either<AppFailure, String?>> getGeminiKey();

  // ── Onboarding state ──────────────────────────────────
  Future<Either<AppFailure, void>> markOnboardingComplete();
  Future<Either<AppFailure, bool>> isOnboardingComplete();

  // ── Cleanup ───────────────────────────────────────────
  Future<Either<AppFailure, void>> clearAll();
}
