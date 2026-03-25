// lib/core/domain/usecases/report/save_session_xp.dart
//
// Writes the session XP total to Firestore after a session ends.
// Thin wrapper around UserRepository.addXp — keeps ReportBloc
// free of direct repository dependencies.

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/repositories/user_repository.dart";

class SaveSessionXp {
  final UserRepository _userRepository;

  const SaveSessionXp({required UserRepository userRepository})
      : _userRepository = userRepository;

  Future<Either<AppFailure, void>> execute({
    required String uid,
    required int xp,
  }) => _userRepository.addXp(uid: uid, xp: xp);
}
