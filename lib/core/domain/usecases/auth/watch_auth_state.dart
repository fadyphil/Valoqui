// lib/core/domain/usecases/auth/watch_auth_state.dart

import 'package:valoqui/core/domain/models/app_user.dart';
import 'package:valoqui/core/domain/repositories/auth_repository.dart';

class WatchAuthState {
  final AuthRepository _authRepository;

  const WatchAuthState({required AuthRepository authRepository})
    : _authRepository = authRepository;

  Stream<AppUser?> execute() => _authRepository.authStateChanges;
}
