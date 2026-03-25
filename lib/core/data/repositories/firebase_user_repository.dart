// lib/core/data/repositories/firebase_user_repository.dart
//
// Implements UserRepository by delegating every operation to
// FirestoreDatasource. To swap to a different database (Supabase,
// SQLite, etc.), implement UserRepository and update service_locator.dart.
// Nothing else in the app changes.

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/data/datasources/firestore_datasource.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/models/app_user.dart";
import "package:valoqui/core/domain/repositories/user_repository.dart";

class FirebaseUserRepository implements UserRepository {
  final FirestoreDatasource _datasource;

  const FirebaseUserRepository({required FirestoreDatasource datasource})
      : _datasource = datasource;

  @override
  Future<Either<AppFailure, void>> createUserIfNotExists({
    required String uid,
    required String displayName,
    required String email,
  }) => _datasource.createUserIfNotExists(
    uid: uid,
    displayName: displayName,
    email: email,
  );

  @override
  Stream<AppUser?> watchUser(String uid) => _datasource.watchUser(uid);

  @override
  Future<Either<AppFailure, void>> updateLevel(String uid, String level) =>
      _datasource.updateLevel(uid, level);

  @override
  Future<Either<AppFailure, void>> updateKeyConfigured(
    String uid, {
    bool? groqConfigured,
    bool? geminiConfigured,
  }) => _datasource.updateKeyConfigured(
    uid,
    groqConfigured: groqConfigured,
    geminiConfigured: geminiConfigured,
  );

  @override
  Future<Either<AppFailure, void>> addXp({
    required String uid,
    required int xp,
  }) => _datasource.addXp(uid: uid, xp: xp);
}
