// lib/core/domain/repositories/auth_repository.dart
//
// Defines WHAT auth can do. Says nothing about HOW.
// The data layer provides the concrete implementation.
// BLoCs and use cases depend only on this interface.

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/models/app_user.dart";

abstract interface class AuthRepository {
  /// Emits the current user on subscription, then again on every auth change.
  /// Emits null when signed out.
  Stream<AppUser?> get authStateChanges;

  Future<Either<AppFailure, AppUser>> signInWithGoogle();

  Future<Either<AppFailure, void>> signOut();
}
