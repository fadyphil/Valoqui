import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valoqui/core/domain/models/app_failure.dart';
import 'package:valoqui/core/domain/models/app_user.dart';
import 'package:valoqui/features/auth/bloc/auth_bloc.dart';

import '../../../mocks/mock_services.dart';

void main() {
  late AuthBloc authBloc;
  late MockSignInWithGoogle mockSignInWithGoogle;
  late MockSignOut mockSignOut;
  late MockWatchAuthState mockWatchAuthState;

  const tUser = AppUser(
    uid: '123',
    displayName: 'Test User',
    email: 'test@example.com',
  );

  setUp(() {
    mockSignInWithGoogle = MockSignInWithGoogle();
    mockSignOut = MockSignOut();
    mockWatchAuthState = MockWatchAuthState();

    // Default mock behavior for auth stream
    when(() => mockWatchAuthState.execute())
        .thenAnswer((_) => Stream.value(null));

    authBloc = AuthBloc(
      signInWithGoogle: mockSignInWithGoogle,
      signOut: mockSignOut,
      watchAuthState: mockWatchAuthState,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state should be AuthState.initial()', () {
      expect(authBloc.state, const AuthState.initial());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [authenticated] when AuthStarted is added and user is logged in',
      build: () {
        when(() => mockWatchAuthState.execute())
            .thenAnswer((_) => Stream.value(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [
        const AuthState.authenticated(user: tUser),
      ],
      verify: (_) {
        verify(() => mockWatchAuthState.execute()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [unauthenticated] when AuthStarted is added and user is not logged in',
      build: () {
        when(() => mockWatchAuthState.execute())
            .thenAnswer((_) => Stream.value(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [
        const AuthState.unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] when AuthSignInWithGoogle succeeds',
      build: () {
        when(() => mockSignInWithGoogle.execute())
            .thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSignInWithGoogle()),
      expect: () => [
        const AuthState.loading(),
        const AuthState.authenticated(user: tUser),
      ],
      verify: (_) {
        verify(() => mockSignInWithGoogle.execute()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated] when AuthSignInWithGoogle is cancelled',
      build: () {
        when(() => mockSignInWithGoogle.execute())
            .thenAnswer((_) async => const Left(AppFailure.signInCancelled()));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSignInWithGoogle()),
      expect: () => [
        const AuthState.loading(),
        const AuthState.unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when AuthSignInWithGoogle fails',
      build: () {
        when(() => mockSignInWithGoogle.execute())
            .thenAnswer((_) async => const Left(AppFailure.authFailure(message: 'Error')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSignInWithGoogle()),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error(message: 'Error'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when AuthSignOutRequested fails',
      build: () {
        when(() => mockSignOut.execute())
            .thenAnswer((_) async => const Left(AppFailure.authFailure(message: 'Error')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error(message: 'Error'),
      ],
      verify: (_) {
        verify(() => mockSignOut.execute()).called(1);
      },
    );

    // Note: Success of AuthSignOutRequested doesn't directly emit state from
    // the event handler, because _onAuthUserChanged handles it via the stream.
  });
}
