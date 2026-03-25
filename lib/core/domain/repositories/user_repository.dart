// lib/core/domain/repositories/user_repository.dart

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/models/app_user.dart";

abstract interface class UserRepository {
  /// Creates the Firestore user document on first sign-in.
  /// No-ops if the document already exists.
  Future<Either<AppFailure, void>> createUserIfNotExists({
    required String uid,
    required String displayName,
    required String email,
  });

  /// Real-time stream of the user's profile.
  /// Emits null if the document does not exist.
  Stream<AppUser?> watchUser(String uid);

  /// Updates the user's CEFR level in Firestore.
  Future<Either<AppFailure, void>> updateLevel(String uid, String level);

  /// Updates the key-configured flags in Firestore.
  /// Pass only the flags you want to change.
  Future<Either<AppFailure, void>> updateKeyConfigured(
    String uid, {
    bool? groqConfigured,
    bool? geminiConfigured,
  });

  /// Increments currentXP, totalSessionCount, and sets lastSessionDate.
  /// Called by SaveSessionXp use case after every completed session.
  Future<Either<AppFailure, void>> addXp({
    required String uid,
    required int xp,
  });
}
