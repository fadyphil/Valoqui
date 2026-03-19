// lib/core/domain/usecases/onboarding/save_groq_key.dart
//
// Business rule: Groq keys must start with "gsk_".
// Saves to device storage AND updates the Firestore flag.
// Both must succeed — if storage succeeds but Firestore fails,
// the key is still usable; the flag is cosmetic, so we return
// success regardless of the Firestore update result to avoid
// blocking the user on a non-critical write.

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/repositories/key_storage_repository.dart";
import "package:valoqui/core/domain/repositories/user_repository.dart";

class SaveGroqKey {
  final KeyStorageRepository _keyStorage;
  final UserRepository _userRepository;

  const SaveGroqKey({
    required KeyStorageRepository keyStorage,
    required UserRepository userRepository,
  }) : _keyStorage = keyStorage,
       _userRepository = userRepository;

  Future<Either<AppFailure, void>> execute(String uid, String key) async {
    if (!key.startsWith("gsk_")) {
      return left(const AppFailure.invalidApiKey());
    }

    final saveResult = await _keyStorage.saveGroqKey(key);

    return saveResult.fold(left, (_) async {
      // Best-effort Firestore flag update — failure does not block onboarding
      await _userRepository.updateKeyConfigured(uid, groqConfigured: true);
      return right(null);
    });
  }
}
