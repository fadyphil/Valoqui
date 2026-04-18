// lib/features/auth/bloc/auth_bloc.dart

import "dart:async";
import "package:equatable/equatable.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import 'package:valoqui/core/domain/models/app_user.dart';
import 'package:valoqui/core/domain/usecases/auth/sign_in_with_google.dart';
import 'package:valoqui/core/domain/usecases/auth/sign_out.dart';
import 'package:valoqui/core/domain/usecases/auth/watch_auth_state.dart';

part "auth_event.dart";
part "auth_state.dart";

part 'auth_bloc.freezed.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithGoogle _signInWithGoogle;
  final SignOut _signOut;
  final WatchAuthState _watchAuthState;
  StreamSubscription<AppUser?>? _authSubscription;

  AuthBloc({
    required SignInWithGoogle signInWithGoogle,
    required SignOut signOut,
    required WatchAuthState watchAuthState,
  }) : _signInWithGoogle = signInWithGoogle,
       _signOut = signOut,
       _watchAuthState = watchAuthState,
       super(const AuthState.initial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<_AuthUserChanged>(_onAuthUserChanged);
  }

  void _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) {
    _authSubscription?.cancel();
    _authSubscription = _watchAuthState.execute().listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  void _onAuthUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(AuthState.authenticated(user: event.user!));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signInWithGoogle.execute();

    result.fold((failure) {
      // Use Freezed's maybeWhen to catch specific cases
      failure.maybeWhen(
        signInCancelled: () => emit(const AuthState.unauthenticated()),
        orElse: () => emit(AuthState.error(message: failure.message)),
      );
    }, (user) => emit(AuthState.authenticated(user: user)));
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signOut.execute();
    result.fold(
      (failure) => emit(AuthState.error(message: failure.message)),
      (_) {}, // auth stream emits null → _onAuthUserChanged → unauthenticated
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

// Internal — not part of the public event API
class _AuthUserChanged extends AuthEvent {
  final AppUser? user;
  const _AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}
