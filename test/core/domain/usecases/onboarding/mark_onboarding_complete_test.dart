import "package:flutter_test/flutter_test.dart";
import "package:fpdart/fpdart.dart";
import "package:mocktail/mocktail.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/usecases/onboarding/mark_onboarding_complete.dart";

import "../../../../mocks/mock_services.dart";

void main() {
  late MockKeyStorageRepository mockKeyStorageRepository;
  late MarkOnboardingComplete useCase;

  setUp(() {
    mockKeyStorageRepository = MockKeyStorageRepository();
    useCase = MarkOnboardingComplete(keyStorage: mockKeyStorageRepository);
  });

  test("marks onboarding complete when storage write succeeds", () async {
    when(
      () => mockKeyStorageRepository.markOnboardingComplete(),
    ).thenAnswer((_) async => const Right<AppFailure, void>(null));

    final result = await useCase.execute();

    expect(result, const Right<AppFailure, void>(null));
    verify(() => mockKeyStorageRepository.markOnboardingComplete()).called(1);
  });

  test("returns storage failure when mark write fails", () async {
    const failure = AppFailure.storageFailure(message: "write denied");
    when(
      () => mockKeyStorageRepository.markOnboardingComplete(),
    ).thenAnswer((_) async => const Left<AppFailure, void>(failure));

    final result = await useCase.execute();

    expect(result, const Left<AppFailure, void>(failure));
    verify(() => mockKeyStorageRepository.markOnboardingComplete()).called(1);
  });
}
