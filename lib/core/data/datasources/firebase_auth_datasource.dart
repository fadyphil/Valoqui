// lib/core/data/datasources/firebase_auth_datasource.dart
//
// The ONLY file in the project that touches the Firebase Auth SDK
// and the Google Sign-In SDK. All Firebase types stop here —
// they are converted to domain types before leaving this class.

import "package:firebase_auth/firebase_auth.dart";
import "package:fpdart/fpdart.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/models/app_user.dart";

class FirebaseAuthDatasource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _googleSignIn.initialize();
      _initialized = true;
    }
  }

  // ── Auth state stream ─────────────────────────────────
  Stream<AppUser?> get authStateChanges => _auth.authStateChanges().map(
    (user) => user == null ? null : _toAppUser(user),
  );

  // ── Sign in ───────────────────────────────────────────
  Future<Either<AppFailure, AppUser>> signInWithGoogle() async {
    try {
      await _ensureInitialized();
      final googleUser = await _googleSignIn.authenticate(
        scopeHint: const ["email", "profile"],
      );

      final googleAuth = googleUser.authentication;
      final authzClient = googleUser.authorizationClient;
      final authz =
          await authzClient.authorizationForScopes(const [
            "email",
            "profile",
          ]) ??
          await authzClient.authorizeScopes(const ["email", "profile"]);

      final credential = GoogleAuthProvider.credential(
        accessToken: authz.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return right(_toAppUser(userCredential.user!));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return left(const AppFailure.signInCancelled());
      }
      return left(AppFailure.authFailure(message: "Google Sign-In failed."));
    } on FirebaseAuthException catch (e) {
      return left(
        AppFailure.authFailure(message: e.message ?? "Authentication failed."),
      );
    } catch (e) {
      return left(AppFailure.authFailure(message: e.toString()));
    }
  }

  // ── Sign out ──────────────────────────────────────────
  Future<Either<AppFailure, void>> signOut() async {
    try {
      await _ensureInitialized();
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      return right(null);
    } catch (e) {
      return left(AppFailure.authFailure(message: "Sign out failed: $e"));
    }
  }

  // ── Firebase User → AppUser ───────────────────────────
  AppUser _toAppUser(User user) => AppUser(
    uid: user.uid,
    displayName: user.displayName ?? "",
    email: user.email ?? "",
  );
}
