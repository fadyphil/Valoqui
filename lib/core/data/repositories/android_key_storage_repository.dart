// lib/core/data/repositories/android_key_storage_repository.dart
//
// Implements KeyStorageRepository using Android Keystore
// via SecureStorageDatasource. To swap to a different store
// (iOS Keychain native, hardware key, etc.), implement
// KeyStorageRepository and update service_locator.dart.
// Nothing else in the app changes.

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/data/datasources/secure_storage_datasource.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/repositories/key_storage_repository.dart";

class AndroidKeyStorageRepository implements KeyStorageRepository {
  final SecureStorageDatasource _datasource;

  const AndroidKeyStorageRepository({
    required SecureStorageDatasource datasource,
  }) : _datasource = datasource;

  @override
  Future<Either<AppFailure, void>> saveGroqKey(String key) =>
      _datasource.write(SecureStorageDatasource.groqKeyName, key);

  @override
  Future<Either<AppFailure, String?>> getGroqKey() =>
      _datasource.read(SecureStorageDatasource.groqKeyName);

  @override
  Future<Either<AppFailure, bool>> hasGroqKey() async {
    final result = await getGroqKey();
    return result.map((k) => k != null && k.isNotEmpty);
  }

  @override
  Future<Either<AppFailure, void>> saveGeminiKey(String key) =>
      _datasource.write(SecureStorageDatasource.geminiKeyName, key);

  @override
  Future<Either<AppFailure, String?>> getGeminiKey() =>
      _datasource.read(SecureStorageDatasource.geminiKeyName);

  @override
  Future<Either<AppFailure, void>> markOnboardingComplete() =>
      _datasource.write(SecureStorageDatasource.onboardedKeyName, "true");

  @override
  Future<Either<AppFailure, bool>> isOnboardingComplete() async {
    final result = await _datasource.read(
      SecureStorageDatasource.onboardedKeyName,
    );
    return result.map((v) => v == "true");
  }

  @override
  Future<Either<AppFailure, void>> clearAll() => _datasource.deleteAll();
}
