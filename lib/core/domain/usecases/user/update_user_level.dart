// lib/core/domain/usecases/user/update_user_level.dart
//
// Business rule lives here: "?" maps to "A1".
// The BLoC dispatches whatever the user selected including "?".
// This use case normalizes it before hitting the repository.

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/repositories/user_repository.dart";

class UpdateUserLevel {
  final UserRepository _userRepository;

  const UpdateUserLevel({required UserRepository userRepository})
    : _userRepository = userRepository;

  Future<Either<AppFailure, void>> execute(String uid, String level) {
    final normalized = level == "?" ? "A1" : level;
    return _userRepository.updateLevel(uid, normalized);
  }
}
