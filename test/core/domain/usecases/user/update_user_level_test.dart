import "package:flutter_test/flutter_test.dart";
import "package:fpdart/fpdart.dart";
import "package:mocktail/mocktail.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/usecases/user/update_user_level.dart";

import "../../../../mocks/mock_services.dart";

void main() {
  late MockUserRepository mockUserRepository;
  late UpdateUserLevel useCase;

  const uid = "u1";

  setUp(() {
    mockUserRepository = MockUserRepository();
    useCase = UpdateUserLevel(userRepository: mockUserRepository);
  });

  test('normalizes "?" to "A1" before writing level', () async {
    when(() => mockUserRepository.updateLevel(uid, "A1"))
        .thenAnswer((_) async => const Right<AppFailure, void>(null));

    final result = await useCase.execute(uid, "?");

    expect(result, const Right<AppFailure, void>(null));
    verify(() => mockUserRepository.updateLevel(uid, "A1")).called(1);
    verifyNever(() => mockUserRepository.updateLevel(uid, "?"));
  });

  test("passes through already valid levels unchanged", () async {
    when(() => mockUserRepository.updateLevel(uid, "B1"))
        .thenAnswer((_) async => const Right<AppFailure, void>(null));

    final result = await useCase.execute(uid, "B1");

    expect(result, const Right<AppFailure, void>(null));
    verify(() => mockUserRepository.updateLevel(uid, "B1")).called(1);
  });

  test("returns repository failure unchanged", () async {
    const failure = AppFailure.databaseFailure(message: "write failed");
    when(() => mockUserRepository.updateLevel(uid, "A2"))
        .thenAnswer((_) async => const Left<AppFailure, void>(failure));

    final result = await useCase.execute(uid, "A2");

    expect(result, const Left<AppFailure, void>(failure));
    verify(() => mockUserRepository.updateLevel(uid, "A2")).called(1);
  });
}
