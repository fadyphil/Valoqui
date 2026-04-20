import "package:flutter_test/flutter_test.dart";
import "package:fpdart/fpdart.dart";
import "package:mocktail/mocktail.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/usecases/auth/sign_out.dart";

import "../../../../mocks/mock_services.dart";

void main() {
  late MockAuthRepository mockAuthRepository;
  late SignOut useCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = SignOut(authRepository: mockAuthRepository);
  });

  test("returns success when repository signOut succeeds", () async {
    when(() => mockAuthRepository.signOut())
        .thenAnswer((_) async => const Right<AppFailure, void>(null));

    final result = await useCase.execute();

    expect(result, const Right<AppFailure, void>(null));
    verify(() => mockAuthRepository.signOut()).called(1);
  });

  test("returns failure when repository signOut fails", () async {
    const failure = AppFailure.authFailure(message: "Sign out failed");
    when(() => mockAuthRepository.signOut())
        .thenAnswer((_) async => const Left<AppFailure, void>(failure));

    final result = await useCase.execute();

    expect(result, const Left<AppFailure, void>(failure));
    verify(() => mockAuthRepository.signOut()).called(1);
  });
}
