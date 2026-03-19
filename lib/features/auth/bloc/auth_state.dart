// lib/features/auth/bloc/auth_state.dart

part of "auth_bloc.dart";

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;

  // Carries AppUser — zero Firebase types in this state
  const factory AuthState.authenticated({required AppUser user}) =
      AuthAuthenticated;

  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.error({required String message}) = AuthError;
}
