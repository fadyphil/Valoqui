// lib/core/data/repositories/firebase_auth_repository.dart
//
// Implements AuthRepository using FirebaseAuthDatasource.
// Thin delegation layer — the datasource does the real work.
// This class exists to satisfy the Dependency Inversion Principle:
// the domain interface is implemented here in the data layer.

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/data/datasources/firebase_auth_datasource.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/models/app_user.dart";
import "package:valoqui/core/domain/repositories/auth_repository.dart";

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuthDatasource _datasource;

  const FirebaseAuthRepository({required FirebaseAuthDatasource datasource})
    : _datasource = datasource;

  @override
  Stream<AppUser?> get authStateChanges => _datasource.authStateChanges;

  @override
  Future<Either<AppFailure, AppUser>> signInWithGoogle() =>
      _datasource.signInWithGoogle();

  @override
  Future<Either<AppFailure, void>> signOut() => _datasource.signOut();
}
