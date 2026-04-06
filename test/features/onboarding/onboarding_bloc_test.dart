// test/features/onboarding/onboarding_bloc_test.dart

import "package:bloc_test/bloc_test.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:fpdart/fpdart.dart";
import "package:valoqui/features/onboarding/bloc/onboarding_bloc.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "../../mocks/mock_services.dart";

void main() {
  late MockCheckOnboardingStatus mockCheckStatus;
  late MockSaveGroqKey mockSaveGroqKey;
  late MockSaveGeminiKey mockSaveGeminiKey;
  late MockMarkOnboardingComplete mockMarkComplete;
  late MockUpdateUserLevel mockUpdateLevel;

  const tUid = "user123";

  setUp(() {
    mockCheckStatus = MockCheckOnboardingStatus();
    mockSaveGroqKey = MockSaveGroqKey();
    mockSaveGeminiKey = MockSaveGeminiKey();
    mockMarkComplete = MockMarkOnboardingComplete();
    mockUpdateLevel = MockUpdateUserLevel();
  });

  OnboardingBloc buildBloc() => OnboardingBloc(
    checkOnboardingStatus: mockCheckStatus,
    saveGroqKey: mockSaveGroqKey,
    saveGeminiKey: mockSaveGeminiKey,
    markOnboardingComplete: mockMarkComplete,
    updateUserLevel: mockUpdateLevel,
  );

  group("OnboardingBloc", () {
    group("CheckOnboardingStatusEvent", () {
      blocTest<OnboardingBloc, OnboardingState>(
        "emits [loading, complete] when onboarding is done",
        build: () {
          when(
            () => mockCheckStatus.execute(),
          ).thenAnswer((_) async => right(true));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const CheckOnboardingStatusEvent()),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.complete(),
        ],
      );

      blocTest<OnboardingBloc, OnboardingState>(
        "emits [loading, initial] when onboarding is NOT done",
        build: () {
          when(
            () => mockCheckStatus.execute(),
          ).thenAnswer((_) async => right(false));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const CheckOnboardingStatusEvent()),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.initial(),
        ],
      );
    });

    group("SubmitGroqKey", () {
      blocTest<OnboardingBloc, OnboardingState>(
        "emits [loading, groqKeyComplete] on success",
        build: () {
          when(
            () => mockSaveGroqKey.execute(any(), any()),
          ).thenAnswer((_) async => right(null));
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const SubmitGroqKey(uid: tUid, key: "gsk_test")),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.groqKeyComplete(),
        ],
      );

      blocTest<OnboardingBloc, OnboardingState>(
        "emits [loading, error] on failure",
        build: () {
          when(() => mockSaveGroqKey.execute(any(), any())).thenAnswer(
            (_) async =>
                left(const AppFailure.storageFailure(message: "Failed")),
          );
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const SubmitGroqKey(uid: tUid, key: "gsk_test")),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.error(message: "Failed"),
        ],
      );
    });

    group("SubmitGeminiKey", () {
      blocTest<OnboardingBloc, OnboardingState>(
        "emits [loading, geminiStepComplete] on success",
        build: () {
          when(
            () => mockSaveGeminiKey.execute(any(), any()),
          ).thenAnswer((_) async => right(null));
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const SubmitGeminiKey(uid: tUid, key: "gem_test")),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.geminiStepComplete(),
        ],
      );

      blocTest<OnboardingBloc, OnboardingState>(
        "emits [geminiStepComplete] on SkipGeminiKey",
        build: () => buildBloc(),
        act: (bloc) => bloc.add(const SkipGeminiKey()),
        expect: () => [const OnboardingState.geminiStepComplete()],
      );
    });

    group("SubmitLevel", () {
      blocTest<OnboardingBloc, OnboardingState>(
        "emits [loading, complete] on success (level + mark complete)",
        build: () {
          when(
            () => mockUpdateLevel.execute(any(), any()),
          ).thenAnswer((_) async => right(null));
          when(
            () => mockMarkComplete.execute(),
          ).thenAnswer((_) async => right(null));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const SubmitLevel(uid: tUid, level: "A2")),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.complete(),
        ],
      );

      blocTest<OnboardingBloc, OnboardingState>(
        "emits [loading, error] if level update fails",
        build: () {
          when(() => mockUpdateLevel.execute(any(), any())).thenAnswer(
            (_) async =>
                left(const AppFailure.databaseFailure(message: "DB Error")),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const SubmitLevel(uid: tUid, level: "A2")),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.error(message: "DB Error"),
        ],
      );
    });
  });
}
