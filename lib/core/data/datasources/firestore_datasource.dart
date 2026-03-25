// lib/core/data/datasources/firestore_datasource.dart
//
// The ONLY file that touches the Firestore SDK.
// All collection().doc().get() / .set() / .update() calls live here.
// Converts Firestore DocumentSnapshots into AppUser domain objects
// before returning them. Nothing outside this file knows Firestore exists.

import "package:cloud_firestore/cloud_firestore.dart";
import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/models/app_user.dart";

class FirestoreDatasource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Create user document on first sign-in ─────────────
  Future<Either<AppFailure, void>> createUserIfNotExists({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    try {
      final ref = _db.collection("users").doc(uid);
      if (!(await ref.get()).exists) {
        await ref.set({
          "displayName": displayName,
          "email": email,
          "selfReportedLevel": "unknown",
          "currentCefrLevel": "A1",
          "currentXP": 0,
          "groqKeyConfigured": false,
          "geminiKeyConfigured": false,
          "streakDays": 0,
          "totalSessionCount": 0,
          "totalSpeakingSeconds": 0,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
      return right(null);
    } catch (e) {
      return left(
        AppFailure.databaseFailure(message: "Failed to create user: $e"),
      );
    }
  }

  // ── Real-time profile stream ───────────────────────────
  Stream<AppUser?> watchUser(String uid) => _db
      .collection("users")
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? _toAppUser(doc) : null);

  // ── Update CEFR level ─────────────────────────────────
  Future<Either<AppFailure, void>> updateLevel(String uid, String level) async {
    try {
      await _db.collection("users").doc(uid).set({
        "selfReportedLevel": level.toLowerCase(),
        "currentCefrLevel": level.toUpperCase(),
      }, SetOptions(merge: true));
      return right(null);
    } catch (e) {
      return left(
        AppFailure.databaseFailure(message: "Failed to update level: $e"),
      );
    }
  }

  // ── Update key configuration flags ────────────────────
  Future<Either<AppFailure, void>> updateKeyConfigured(
    String uid, {
    bool? groqConfigured,
    bool? geminiConfigured,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (groqConfigured != null) data["groqKeyConfigured"] = groqConfigured;
      if (geminiConfigured != null) {
        data["geminiKeyConfigured"] = geminiConfigured;
      }
      if (data.isNotEmpty) {
        await _db
            .collection("users")
            .doc(uid)
            .set(data, SetOptions(merge: true));
      }
      return right(null);
    } catch (e) {
      return left(
        AppFailure.databaseFailure(message: "Failed to update key config: $e"),
      );
    }
  }

  // ── Add XP after a completed session ──────────────────
  // Uses FieldValue.increment so concurrent writes are safe.
  // Also bumps totalSessionCount and stamps lastSessionDate.
  Future<Either<AppFailure, void>> addXp({
    required String uid,
    required int xp,
  }) async {
    try {
      await _db.collection("users").doc(uid).update({
        "currentXP": FieldValue.increment(xp),
        "totalSessionCount": FieldValue.increment(1),
        "lastSessionDate": FieldValue.serverTimestamp(),
      });
      return right(null);
    } on FirebaseException catch (e) {
      return left(
        AppFailure.databaseFailure(
          message: "Failed to save XP [${e.code}]: ${e.message}",
        ),
      );
    } catch (e) {
      return left(
        AppFailure.databaseFailure(message: "Failed to save XP: $e"),
      );
    }
  }

  // ── DocumentSnapshot → AppUser ─────────────────────────
  AppUser _toAppUser(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser.fromJson({
      ...data,
      "uid": doc.id,
      // Guard every required String field against null —
      // Firestore documents created before these fields existed
      // will have them missing entirely, which json_serializable
      // casts as null → String crash
      "displayName": data["displayName"] ?? "",
      "email": data["email"] ?? "",
      "currentCefrLevel": data["currentCefrLevel"] ?? "A1",
    });
  }
}
