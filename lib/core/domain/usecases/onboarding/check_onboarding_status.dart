// lib/core/domain/usecases/onboarding/check_onboarding_status.dart

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/repositories/key_storage_repository.dart";

class CheckOnboardingStatus {
  final KeyStorageRepository _keyStorage;

  const CheckOnboardingStatus({required KeyStorageRepository keyStorage})
    : _keyStorage = keyStorage;

  Future<Either<AppFailure, bool>> execute() =>
      _keyStorage.isOnboardingComplete();
}
