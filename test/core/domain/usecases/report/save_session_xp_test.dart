import "package:flutter_test/flutter_test.dart";
import "package:fpdart/fpdart.dart";
import "package:mocktail/mocktail.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/usecases/report/save_session_xp.dart";

import "../../../../mocks/mock_services.dart";

void main() {
  late MockUserRepository mockUserRepository;
  late SaveSessionXp useCase;

  const uid = "u1";
  const xp = 120;

  setUp(() {
    mockUserRepository = MockUserRepository();
    useCase = SaveSessionXp(userRepository: mockUserRepository);
  });

  test("writes session XP to repository and returns success", () async {
    when(
      () => mockUserRepository.addXp(uid: uid, xp: xp),
    ).thenAnswer((_) async => const Right<AppFailure, void>(null));

    final result = await useCase.execute(uid: uid, xp: xp);

    expect(result, const Right<AppFailure, void>(null));
    verify(() => mockUserRepository.addXp(uid: uid, xp: xp)).called(1);
  });

  test("returns repository failure unchanged", () async {
    const failure = AppFailure.databaseFailure(message: "xp write failed");
    when(
      () => mockUserRepository.addXp(uid: uid, xp: xp),
    ).thenAnswer((_) async => const Left<AppFailure, void>(failure));

    final result = await useCase.execute(uid: uid, xp: xp);

    expect(result, const Left<AppFailure, void>(failure));
    verify(() => mockUserRepository.addXp(uid: uid, xp: xp)).called(1);
  });
}
