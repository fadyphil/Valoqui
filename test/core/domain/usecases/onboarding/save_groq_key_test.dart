import "package:flutter_test/flutter_test.dart";
import "package:fpdart/fpdart.dart";
import "package:mocktail/mocktail.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/usecases/onboarding/save_groq_key.dart";

import "../../../../mocks/mock_services.dart";

void main() {
  late MockKeyStorageRepository mockKeyStorageRepository;
  late MockUserRepository mockUserRepository;
  late SaveGroqKey useCase;

  const uid = "u1";
  const validGroqKey = "gsk_123";

  setUp(() {
    mockKeyStorageRepository = MockKeyStorageRepository();
    mockUserRepository = MockUserRepository();
    useCase = SaveGroqKey(
      keyStorage: mockKeyStorageRepository,
      userRepository: mockUserRepository,
    );
  });

  test("rejects invalid key format and never writes", () async {
    final result = await useCase.execute(uid, "not-groq-key");

    expect(result, const Left<AppFailure, void>(AppFailure.invalidApiKey()));
    verifyNever(() => mockKeyStorageRepository.saveGroqKey(any()));
    verifyZeroInteractions(mockUserRepository);
  });

  test("returns save failure when secure storage write fails", () async {
    const failure = AppFailure.storageFailure(message: "save failed");
    when(() => mockKeyStorageRepository.saveGroqKey(validGroqKey))
        .thenAnswer((_) async => const Left<AppFailure, void>(failure));

    final result = await useCase.execute(uid, validGroqKey);

    expect(result, const Left<AppFailure, void>(failure));
    verify(() => mockKeyStorageRepository.saveGroqKey(validGroqKey)).called(1);
    verifyZeroInteractions(mockUserRepository);
  });

  test("returns success when both storage and firestore flag update succeed", () async {
    when(() => mockKeyStorageRepository.saveGroqKey(validGroqKey))
        .thenAnswer((_) async => const Right<AppFailure, void>(null));
    when(() => mockUserRepository.updateKeyConfigured(uid, groqConfigured: true))
        .thenAnswer((_) async => const Right<AppFailure, void>(null));

    final result = await useCase.execute(uid, validGroqKey);

    expect(result, const Right<AppFailure, void>(null));
    verify(() => mockKeyStorageRepository.saveGroqKey(validGroqKey)).called(1);
    verify(() => mockUserRepository.updateKeyConfigured(uid, groqConfigured: true))
        .called(1);
  });

  test("still returns success when firestore flag update fails", () async {
    when(() => mockKeyStorageRepository.saveGroqKey(validGroqKey))
        .thenAnswer((_) async => const Right<AppFailure, void>(null));
    when(() => mockUserRepository.updateKeyConfigured(uid, groqConfigured: true))
        .thenAnswer((_) async => const Left<AppFailure, void>(
              AppFailure.databaseFailure(message: "firestore down"),
            ));

    final result = await useCase.execute(uid, validGroqKey);

    expect(result, const Right<AppFailure, void>(null));
    verify(() => mockKeyStorageRepository.saveGroqKey(validGroqKey)).called(1);
    verify(() => mockUserRepository.updateKeyConfigured(uid, groqConfigured: true))
        .called(1);
  });
}
