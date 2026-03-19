// lib/core/domain/models/app_user.dart
//
// The canonical user model for the entire app.
// Zero external imports — no Firebase, no Flutter, pure Dart + Freezed.
// The data layer converts Firebase types INTO this. Nothing outside
// the data layer ever touches Firebase's own User class.

import "package:freezed_annotation/freezed_annotation.dart";

part "app_user.freezed.dart";
part "app_user.g.dart";

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    required String displayName,
    required String email,
    @Default("A1") String currentCefrLevel,
    @Default(0) int currentXP,
    @Default(false) bool groqKeyConfigured,
    @Default(false) bool geminiKeyConfigured,
    @Default(0) int streakDays,
    @Default(0) int totalSessionCount,
    @Default(0) int totalSpeakingSeconds,
  }) = _AppUser;

  // Required for custom getters on Freezed classes
  const AppUser._();

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  // ── XP level thresholds ─────────────────────────────
  static int xpForLevel(String level) {
    const thresholds = {
      "A1": 0,
      "A2": 500,
      "B1": 1500,
      "B2": 3500,
      "C1": 7000,
      "C2": 13000,
    };
    return thresholds[level.toUpperCase()] ?? 0;
  }

  static int xpNextLevel(String level) {
    const thresholds = {
      "A1": 500,
      "A2": 1500,
      "B1": 3500,
      "B2": 7000,
      "C1": 13000,
      "C2": 20000,
    };
    return thresholds[level.toUpperCase()] ?? 500;
  }

  // ── Computed XP helpers ──────────────────────────────
  int get xpForCurrentLevel => xpForLevel(currentCefrLevel);
  int get xpForNextLevel => xpNextLevel(currentCefrLevel);

  double get levelProgress {
    final current = currentXP - xpForCurrentLevel;
    final needed = xpForNextLevel - xpForCurrentLevel;
    if (needed <= 0) return 1.0;
    return (current / needed).clamp(0.0, 1.0);
  }
}
