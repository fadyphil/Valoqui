// test/features/auth/auth_bloc_test.dart

import "package:bloc_test/bloc_test.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:fpdart/fpdart.dart";
import "package:valoqui/features/auth/bloc/auth_bloc.dart";
import "package:valoqui/core/domain/models/app_user.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "../../mocks/mock_services.dart";

void main() {
  late MockSignInWithGoogle mockSignInWithGoogle;
  late MockSignOut mockSignOut;
  late MockWatchAuthState mockWatchAuthState;

  final tUser = AppUser(
    uid: "123",
    displayName: "Test User",
    email: "test@example.com",
    currentCefrLevel: "A1",
  );

  setUp(() {
    mockSignInWithGoogle = MockSignInWithGoogle();
    mockSignOut = MockSignOut();
    mockWatchAuthState = MockWatchAuthState();
  });

  AuthBloc buildBloc() => AuthBloc(
    signInWithGoogle: mockSignInWithGoogle,
    signOut: mockSignOut,
    watchAuthState: mockWatchAuthState,
  );

  group("AuthBloc", () {
    test("initial state is AuthState.initial()", () {
      expect(buildBloc().state, const AuthState.initial());
    });

    group("AuthStarted", () {
      blocTest<AuthBloc, AuthState>(
        "emits authenticated when watchAuthState returns a user",
        build: () {
          when(() => mockWatchAuthState.execute())
              .thenAnswer((_) => Stream.value(tUser));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const AuthStarted()),
        expect: () => [AuthState.authenticated(user: tUser)],
        verify: (_) => verify(() => mockWatchAuthState.execute()).called(1),
      );

      blocTest<AuthBloc, AuthState>(
        "emits unauthenticated when watchAuthState returns null",
        build: () {
          when(() => mockWatchAuthState.execute())
              .thenAnswer((_) => Stream.value(null));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const AuthStarted()),
        expect: () => [const AuthState.unauthenticated()],
      );
    });

    group("AuthSignInWithGoogle", () {
      blocTest<AuthBloc, AuthState>(
        "emits [loading, authenticated] on successful sign in",
        build: () {
          when(() => mockSignInWithGoogle.execute())
              .thenAnswer((_) async => right(tUser));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const AuthSignInWithGoogle()),
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(user: tUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        "emits [loading, unauthenticated] when sign in is cancelled",
        build: () {
          when(() => mockSignInWithGoogle.execute())
              .thenAnswer((_) async => left(const AppFailure.signInCancelled()));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const AuthSignInWithGoogle()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        "emits [loading, error] on sign in failure",
        build: () {
          when(() => mockSignInWithGoogle.execute()).thenAnswer(
            (_) async => left(const AppFailure.authFailure(message: "Server Error")),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const AuthSignInWithGoogle()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error(message: "Server Error"),
        ],
      );
    });

    group("AuthSignOutRequested", () {
      blocTest<AuthBloc, AuthState>(
        "emits [loading] and waits for stream to emit null on success",
        build: () {
          when(() => mockSignOut.execute()).thenAnswer((_) async => right(null));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const AuthSignOutRequested()),
        expect: () => [const AuthState.loading()],
      );

      blocTest<AuthBloc, AuthState>(
        "emits [loading, error] on sign out failure",
        build: () {
          when(() => mockSignOut.execute()).thenAnswer(
            (_) async => left(const AppFailure.authFailure(message: "Sign Out Failed")),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const AuthSignOutRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error(message: "Sign Out Failed"),
        ],
      );
    });
  });
}
