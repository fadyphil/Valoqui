// lib/core/data/repositories/firebase_user_repository.dart

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
}
