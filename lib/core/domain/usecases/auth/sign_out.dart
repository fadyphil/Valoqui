// lib/core/domain/usecases/auth/sign_out.dart

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/repositories/auth_repository.dart";

class SignOut {
  final AuthRepository _authRepository;

  const SignOut({required AuthRepository authRepository})
    : _authRepository = authRepository;

  Future<Either<AppFailure, void>> execute() => _authRepository.signOut();
}
