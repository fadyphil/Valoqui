// test/core/domain/usecases/auth/sign_in_with_google_test.dart

import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/usecases/auth/sign_in_with_google.dart";
import "package:valoqui/core/domain/models/app_user.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "../../../../mocks/mock_services.dart";

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockUserRepository mockUserRepository;
  late SignInWithGoogle useCase;

  final tUser = AppUser(
    uid: "123",
    displayName: "Test User",
    email: "test@example.com",
    currentCefrLevel: "A1",
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUserRepository = MockUserRepository();
    useCase = SignInWithGoogle(
      authRepository: mockAuthRepository,
      userRepository: mockUserRepository,
    );
  });

  group("SignInWithGoogle UseCase", () {
    test("should return AppUser when both repository calls succeed", () async {
      // ARRANGE
      when(
        () => mockAuthRepository.signInWithGoogle(),
      ).thenAnswer((_) async => right(tUser));
      when(
        () => mockUserRepository.createUserIfNotExists(
          uid: any(named: "uid"),
          displayName: any(named: "displayName"),
          email: any(named: "email"),
        ),
      ).thenAnswer((_) async => right(null));

      // ACT
      final result = await useCase.execute();

      // ASSERT
      expect(result, right(tUser));
      verify(() => mockAuthRepository.signInWithGoogle()).called(1);
      verify(
        () => mockUserRepository.createUserIfNotExists(
          uid: tUser.uid,
          displayName: tUser.displayName,
          email: tUser.email,
        ),
      ).called(1);
    });

    test("should return AppFailure when authRepository fails", () async {
      // ARRANGE
      const failure = AppFailure.signInCancelled();
      when(
        () => mockAuthRepository.signInWithGoogle(),
      ).thenAnswer((_) async => left(failure));

      // ACT
      final result = await useCase.execute();

      // ASSERT
      expect(result, left(failure));
      verify(() => mockAuthRepository.signInWithGoogle()).called(1);
      verifyZeroInteractions(mockUserRepository);
    });

    test("should return AppFailure when userRepository fails", () async {
      // ARRANGE
      const failure = AppFailure.databaseFailure(message: "DB Error");
      when(
        () => mockAuthRepository.signInWithGoogle(),
      ).thenAnswer((_) async => right(tUser));
      when(
        () => mockUserRepository.createUserIfNotExists(
          uid: any(named: "uid"),
          displayName: any(named: "displayName"),
          email: any(named: "email"),
        ),
      ).thenAnswer((_) async => left(failure));

      // ACT
      final result = await useCase.execute();

      // ASSERT
      expect(result, left(failure));
      verify(() => mockAuthRepository.signInWithGoogle()).called(1);
      verify(
        () => mockUserRepository.createUserIfNotExists(
          uid: tUser.uid,
          displayName: tUser.displayName,
          email: tUser.email,
        ),
      ).called(1);
    });
  });
}
