// lib/core/domain/usecases/onboarding/save_gemini_key.dart

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/repositories/key_storage_repository.dart";
import "package:valoqui/core/domain/repositories/user_repository.dart";

class SaveGeminiKey {
  final KeyStorageRepository _keyStorage;
  final UserRepository _userRepository;

  const SaveGeminiKey({
    required KeyStorageRepository keyStorage,
    required UserRepository userRepository,
  }) : _keyStorage = keyStorage,
       _userRepository = userRepository;

  Future<Either<AppFailure, void>> execute(String uid, String key) async {
    final saveResult = await _keyStorage.saveGeminiKey(key);
    return saveResult.fold(left, (_) async {
      await _userRepository.updateKeyConfigured(uid, geminiConfigured: true);
      return right(null);
    });
  }
}
