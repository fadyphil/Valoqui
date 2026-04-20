import "package:flutter_test/flutter_test.dart";
import "package:fpdart/fpdart.dart";
import "package:mocktail/mocktail.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/usecases/onboarding/save_gemini_key.dart";

import "../../../../mocks/mock_services.dart";

void main() {
  late MockKeyStorageRepository mockKeyStorageRepository;
  late MockUserRepository mockUserRepository;
  late SaveGeminiKey useCase;

  const uid = "u1";
  const geminiKey = "AIza-sample";

  setUp(() {
    mockKeyStorageRepository = MockKeyStorageRepository();
    mockUserRepository = MockUserRepository();
    useCase = SaveGeminiKey(
      keyStorage: mockKeyStorageRepository,
      userRepository: mockUserRepository,
    );
  });

  test("returns failure when secure storage save fails", () async {
    const failure = AppFailure.storageFailure(message: "save failed");
    when(() => mockKeyStorageRepository.saveGeminiKey(geminiKey))
        .thenAnswer((_) async => const Left<AppFailure, void>(failure));

    final result = await useCase.execute(uid, geminiKey);

    expect(result, const Left<AppFailure, void>(failure));
    verify(() => mockKeyStorageRepository.saveGeminiKey(geminiKey)).called(1);
    verifyZeroInteractions(mockUserRepository);
  });

  test(
    "returns success when storage and firestore flag update succeed",
    () async {
      when(() => mockKeyStorageRepository.saveGeminiKey(geminiKey))
          .thenAnswer((_) async => const Right<AppFailure, void>(null));
      when(
        () => mockUserRepository.updateKeyConfigured(
          uid,
          geminiConfigured: true,
        ),
      ).thenAnswer((_) async => const Right<AppFailure, void>(null));

      final result = await useCase.execute(uid, geminiKey);

      expect(result, const Right<AppFailure, void>(null));
      verify(() => mockKeyStorageRepository.saveGeminiKey(geminiKey)).called(1);
      verify(
        () => mockUserRepository.updateKeyConfigured(
          uid,
          geminiConfigured: true,
        ),
      ).called(1);
    },
  );

  test("still returns success when firestore flag update fails", () async {
    when(() => mockKeyStorageRepository.saveGeminiKey(geminiKey))
        .thenAnswer((_) async => const Right<AppFailure, void>(null));
    when(
      () => mockUserRepository.updateKeyConfigured(uid, geminiConfigured: true),
    ).thenAnswer(
      (_) async => const Left<AppFailure, void>(
        AppFailure.databaseFailure(message: "firestore update failed"),
      ),
    );

    final result = await useCase.execute(uid, geminiKey);

    expect(result, const Right<AppFailure, void>(null));
    verify(() => mockKeyStorageRepository.saveGeminiKey(geminiKey)).called(1);
    verify(
      () => mockUserRepository.updateKeyConfigured(
        uid,
        geminiConfigured: true,
      ),
    ).called(1);
  });
}
