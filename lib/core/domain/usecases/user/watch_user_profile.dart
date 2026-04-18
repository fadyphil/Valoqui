// lib/core/domain/usecases/user/watch_user_profile.dart

import 'package:valoqui/core/domain/models/app_user.dart';
import 'package:valoqui/core/domain/repositories/user_repository.dart';

class WatchUserProfile {
  final UserRepository _userRepository;

  const WatchUserProfile({required UserRepository userRepository})
    : _userRepository = userRepository;

  Stream<AppUser?> execute(String uid) => _userRepository.watchUser(uid);
}
