// test/features/onboarding/onboarding_bloc_test.dart

import "package:bloc_test/bloc_test.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:valoqui/features/onboarding/bloc/onboarding_bloc.dart";
import "../../mocks/mock_services.dart";

void main() {
  late MockSecureStorage secureStorage;
  late MockFirestoreService firestoreService;

  setUp(() {
    secureStorage = MockSecureStorage();
    firestoreService = MockFirestoreService();
  });

  OnboardingBloc buildBloc() => OnboardingBloc(
    secureStorage: secureStorage,
    firestoreService: firestoreService,
  );

  group("OnboardingBloc", () {
    blocTest<OnboardingBloc, OnboardingState>(
      "emits complete when onboarding is already done",
      build: () {
        when(
          () => secureStorage.isOnboardingComplete(),
        ).thenAnswer((_) async => true);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CheckOnboardingStatus()),
      expect: () => [
        const OnboardingState.loading(),
        const OnboardingState.complete(),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      "emits error when Groq key format is invalid",
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const SaveGroqKey("invalid_key")),
      expect: () => [isA<OnboardingError>()],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      "emits groqKeyComplete when valid key is saved",
      build: () {
        when(() => secureStorage.saveGroqKey(any())).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SaveGroqKey("gsk_validkeyhere")),
      expect: () => [
        const OnboardingState.loading(),
        const OnboardingState.groqKeyComplete(),
      ],
    );
  });
}
