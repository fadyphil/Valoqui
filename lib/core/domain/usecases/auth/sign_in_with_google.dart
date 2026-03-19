// lib/core/domain/usecases/auth/sign_in_with_google.dart
//
// Orchestrates the full sign-in flow:
// 1. Authenticate with Google via AuthRepository
// 2. Ensure the user document exists in Firestore via UserRepository
// This is the only place that knows both steps must happen together.

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/models/app_user.dart";
import "package:valoqui/core/domain/repositories/auth_repository.dart";
import "package:valoqui/core/domain/repositories/user_repository.dart";

class SignInWithGoogle {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  const SignInWithGoogle({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  }) : _authRepository = authRepository,
       _userRepository = userRepository;

  Future<Either<AppFailure, AppUser>> execute() async {
    final signInResult = await _authRepository.signInWithGoogle();

    return signInResult.fold(left, (user) async {
      final createResult = await _userRepository.createUserIfNotExists(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
      );
      return createResult.fold(left, (_) => right(user));
    });
  }
}
