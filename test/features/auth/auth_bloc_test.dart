// test/features/auth/auth_bloc_test.dart

import "package:bloc_test/bloc_test.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:valoqui/features/auth/bloc/auth_bloc.dart";
import "../../mocks/mock_services.dart";

class MockUser extends Mock implements User {}

void main() {
  late MockAuthService authService;
  late MockFirestoreService firestoreService;
  late MockSecureStorage secureStorage;

  setUp(() {
    authService = MockAuthService();
    firestoreService = MockFirestoreService();
    secureStorage = MockSecureStorage();
  });

  AuthBloc buildBloc() => AuthBloc(
    authService: authService,
    firestoreService: firestoreService,
    secureStorage: secureStorage,
  );

  group("AuthBloc", () {
    test("initial state is AuthState.initial()", () {
      expect(buildBloc().state, const AuthState.initial());
    });

    blocTest<AuthBloc, AuthState>(
      "emits unauthenticated when auth stream returns null",
      build: () {
        when(
          () => authService.authStateChanges,
        ).thenAnswer((_) => Stream.value(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [const AuthState.unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      "emits authenticated when auth stream returns user",
      build: () {
        final user = MockUser();
        when(
          () => authService.authStateChanges,
        ).thenAnswer((_) => Stream.value(user));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [isA<AuthAuthenticated>()],
    );
  });
}
