// lib/core/data/datasources/secure_storage_datasource.dart
//
// The ONLY file that touches flutter_secure_storage.
// Wraps raw read/write/delete in Either so errors surface
// as AppFailure instead of exceptions.

import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";

class SecureStorageDatasource {
  final FlutterSecureStorage _storage;

  SecureStorageDatasource({FlutterSecureStorage? storage})
    : _storage =
          storage ?? const FlutterSecureStorage(aOptions: AndroidOptions());

  // ── Key name constants ────────────────────────────────
  static const groqKeyName = "valoqui_groq_api_key";
  static const geminiKeyName = "valoqui_gemini_api_key";
  static const onboardedKeyName = "valoqui_onboarding_complete";

  // ── Primitive operations ──────────────────────────────
  Future<Either<AppFailure, void>> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return right(null);
    } on Exception catch (e) {
      return left(
        AppFailure.storageFailure(message: "Write failed for $key: $e"),
      );
    }
  }

  Future<Either<AppFailure, String?>> read(String key) async {
    try {
      return right(await _storage.read(key: key));
    } on Exception catch (e) {
      return left(
        AppFailure.storageFailure(message: "Read failed for $key: $e"),
      );
    }
  }

  Future<Either<AppFailure, void>> deleteAll() async {
    try {
      await _storage.deleteAll();
      return right(null);
    } on Exception catch (e) {
      return left(AppFailure.storageFailure(message: "Clear failed: $e"));
    }
  }
}
