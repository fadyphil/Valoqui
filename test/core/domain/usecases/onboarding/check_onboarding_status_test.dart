import "package:flutter_test/flutter_test.dart";
import "package:fpdart/fpdart.dart";
import "package:mocktail/mocktail.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/usecases/onboarding/check_onboarding_status.dart";

import "../../../../mocks/mock_services.dart";

void main() {
  late MockKeyStorageRepository mockKeyStorageRepository;
  late CheckOnboardingStatus useCase;

  setUp(() {
    mockKeyStorageRepository = MockKeyStorageRepository();
    useCase = CheckOnboardingStatus(keyStorage: mockKeyStorageRepository);
  });

  test("returns onboarding complete status when storage succeeds", () async {
    when(() => mockKeyStorageRepository.isOnboardingComplete())
        .thenAnswer((_) async => const Right<AppFailure, bool>(true));

    final result = await useCase.execute();

    expect(result, const Right<AppFailure, bool>(true));
    verify(() => mockKeyStorageRepository.isOnboardingComplete()).called(1);
  });

  test("returns storage failure unchanged", () async {
    const failure = AppFailure.storageFailure(
      message: "secure storage unavailable",
    );
    when(() => mockKeyStorageRepository.isOnboardingComplete())
        .thenAnswer((_) async => const Left<AppFailure, bool>(failure));

    final result = await useCase.execute();

    expect(result, const Left<AppFailure, bool>(failure));
    verify(() => mockKeyStorageRepository.isOnboardingComplete()).called(1);
  });
}
