// lib/core/domain/usecases/onboarding/mark_onboarding_complete.dart

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/repositories/key_storage_repository.dart";

class MarkOnboardingComplete {
  final KeyStorageRepository _keyStorage;

  const MarkOnboardingComplete({required KeyStorageRepository keyStorage})
    : _keyStorage = keyStorage;

  Future<Either<AppFailure, void>> execute() =>
      _keyStorage.markOnboardingComplete();
}
