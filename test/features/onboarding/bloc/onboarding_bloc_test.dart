import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valoqui/core/domain/models/app_failure.dart';
import 'package:valoqui/features/onboarding/bloc/onboarding_bloc.dart';

import '../../../mocks/mock_services.dart';

void main() {
  late OnboardingBloc onboardingBloc;
  late MockCheckOnboardingStatus mockCheckOnboardingStatus;
  late MockSaveGroqKey mockSaveGroqKey;
  late MockSaveGeminiKey mockSaveGeminiKey;
  late MockMarkOnboardingComplete mockMarkOnboardingComplete;
  late MockUpdateUserLevel mockUpdateUserLevel;

  const tUid = 'user123';
  const tKey = 'test-key-123';
  const tLevel = 'A1';

  setUp(() {
    mockCheckOnboardingStatus = MockCheckOnboardingStatus();
    mockSaveGroqKey = MockSaveGroqKey();
    mockSaveGeminiKey = MockSaveGeminiKey();
    mockMarkOnboardingComplete = MockMarkOnboardingComplete();
    mockUpdateUserLevel = MockUpdateUserLevel();

    onboardingBloc = OnboardingBloc(
      checkOnboardingStatus: mockCheckOnboardingStatus,
      saveGroqKey: mockSaveGroqKey,
      saveGeminiKey: mockSaveGeminiKey,
      markOnboardingComplete: mockMarkOnboardingComplete,
      updateUserLevel: mockUpdateUserLevel,
    );
  });

  tearDown(() {
    onboardingBloc.close();
  });

  group('OnboardingBloc', () {
    test('initial state should be OnboardingState.initial()', () {
      expect(onboardingBloc.state, const OnboardingState.initial());
    });

    group('CheckOnboardingStatusEvent', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'emits [loading, complete] when onboarding is complete',
        build: () {
          when(
            () => mockCheckOnboardingStatus.execute(),
          ).thenAnswer((_) async => const Right(true));
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const CheckOnboardingStatusEvent()),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.complete(),
        ],
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'emits [loading, initial] when onboarding is not complete',
        build: () {
          when(
            () => mockCheckOnboardingStatus.execute(),
          ).thenAnswer((_) async => const Right(false));
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const CheckOnboardingStatusEvent()),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.initial(),
        ],
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'emits [loading, error] when checking status fails',
        build: () {
          when(() => mockCheckOnboardingStatus.execute()).thenAnswer(
            (_) async =>
                const Left(AppFailure.storageFailure(message: 'Error')),
          );
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const CheckOnboardingStatusEvent()),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.error(message: 'Error'),
        ],
      );
    });

    group('SubmitGroqKey', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'emits [loading, groqKeyComplete] when save succeeds',
        build: () {
          when(
            () => mockSaveGroqKey.execute(tUid, tKey),
          ).thenAnswer((_) async => const Right(null));
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const SubmitGroqKey(uid: tUid, key: tKey)),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.groqKeyComplete(),
        ],
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'emits [loading, error] when save fails',
        build: () {
          when(() => mockSaveGroqKey.execute(tUid, tKey)).thenAnswer(
            (_) async =>
                const Left(AppFailure.storageFailure(message: 'Error')),
          );
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const SubmitGroqKey(uid: tUid, key: tKey)),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.error(message: 'Error'),
        ],
      );
    });

    group('SubmitGeminiKey', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'emits [loading, geminiStepComplete] when save succeeds',
        build: () {
          when(
            () => mockSaveGeminiKey.execute(tUid, tKey),
          ).thenAnswer((_) async => const Right(null));
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const SubmitGeminiKey(uid: tUid, key: tKey)),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.geminiStepComplete(),
        ],
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'emits [loading, error] when save fails',
        build: () {
          when(() => mockSaveGeminiKey.execute(tUid, tKey)).thenAnswer(
            (_) async =>
                const Left(AppFailure.storageFailure(message: 'Error')),
          );
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const SubmitGeminiKey(uid: tUid, key: tKey)),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.error(message: 'Error'),
        ],
      );
    });

    group('SkipGeminiKey', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'emits [geminiStepComplete] directly',
        build: () => onboardingBloc,
        act: (bloc) => bloc.add(const SkipGeminiKey()),
        expect: () => [const OnboardingState.geminiStepComplete()],
      );
    });

    group('SubmitLevel', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'emits [loading, complete] when both updates succeed',
        build: () {
          when(
            () => mockUpdateUserLevel.execute(tUid, tLevel),
          ).thenAnswer((_) async => const Right(null));
          when(
            () => mockMarkOnboardingComplete.execute(),
          ).thenAnswer((_) async => const Right(null));
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const SubmitLevel(uid: tUid, level: tLevel)),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.complete(),
        ],
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'emits [loading, error] when level update fails',
        build: () {
          when(() => mockUpdateUserLevel.execute(tUid, tLevel)).thenAnswer(
            (_) async =>
                const Left(AppFailure.databaseFailure(message: 'Level Error')),
          );
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const SubmitLevel(uid: tUid, level: tLevel)),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.error(message: 'Level Error'),
        ],
        verify: (_) {
          verifyNever(() => mockMarkOnboardingComplete.execute());
        },
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'emits [loading, error] when marking complete fails',
        build: () {
          when(
            () => mockUpdateUserLevel.execute(tUid, tLevel),
          ).thenAnswer((_) async => const Right(null));
          when(() => mockMarkOnboardingComplete.execute()).thenAnswer(
            (_) async =>
                const Left(AppFailure.storageFailure(message: 'Mark Error')),
          );
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const SubmitLevel(uid: tUid, level: tLevel)),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.error(message: 'Mark Error'),
        ],
      );
    });

    // ── Add to existing OnboardingBloc test file ──────────────────────────────

    group('AppFailure subtype handling', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'propagates networkFailure message correctly',
        build: () {
          when(() => mockCheckOnboardingStatus.execute()).thenAnswer(
            (_) async =>
                const Left(AppFailure.networkFailure(message: 'No internet')),
          );
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const CheckOnboardingStatusEvent()),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.error(message: 'No internet'),
        ],
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'propagates authFailure message correctly',
        build: () {
          when(() => mockSaveGroqKey.execute(tUid, tKey)).thenAnswer(
            (_) async =>
                const Left(AppFailure.authFailure(message: 'Token expired')),
          );
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const SubmitGroqKey(uid: tUid, key: tKey)),
        expect: () => [
          const OnboardingState.loading(),
          const OnboardingState.error(message: 'Token expired'),
        ],
      );
    });

    group('Loading state timing', () {
      test('emits loading BEFORE async work starts', () async {
        final completer = Completer<Either<AppFailure, bool>>();
        final mockUseCase = MockCheckOnboardingStatus();
        when(mockUseCase.execute).thenAnswer((_) => completer.future);

        final bloc = OnboardingBloc(
          checkOnboardingStatus: mockUseCase,
          saveGroqKey: MockSaveGroqKey(),
          saveGeminiKey: MockSaveGeminiKey(),
          markOnboardingComplete: MockMarkOnboardingComplete(),
          updateUserLevel: MockUpdateUserLevel(),
        );

        bloc.add(const CheckOnboardingStatusEvent());
        await Future.microtask(() {});

        expect(bloc.state, const OnboardingState.loading());

        completer.complete(const Right<AppFailure, bool>(true));
        await Future.microtask(() {});

        expect(bloc.state, const OnboardingState.complete());

        await bloc.close();
      });
    });

    group('State equality (freezed)', () {
      test('OnboardingState.error uses value equality', () {
        const s1 = OnboardingState.error(message: 'Test error');
        const s2 = OnboardingState.error(message: 'Test error');
        expect(s1, equals(s2));
        expect(s1.hashCode, equals(s2.hashCode));
      });

      test('OnboardingState.complete is singleton (const)', () {
        const s1 = OnboardingState.complete();
        const s2 = OnboardingState.complete();
        expect(identical(s1, s2), isTrue);
      });

      test('OnboardingState variants are not equal across types', () {
        const error = OnboardingState.error(message: 'X');
        const complete = OnboardingState.complete();
        expect(error, isNot(equals(complete)));
      });
    });
  });

  group('close()', () {
    test('closes cleanly without errors', () async {
      // Arrange: trigger an async operation
      final completer = Completer<Either<AppFailure, bool>>();
      when(
        () => mockCheckOnboardingStatus.execute(),
      ).thenAnswer((_) => completer.future);

      onboardingBloc.add(const CheckOnboardingStatusEvent());
      await Future.microtask(() {});

      // Act & Assert: close should not throw
      expect(() => onboardingBloc.close(), returnsNormally);
    });
  });

  group('SubmitLevel sequential logic', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'does not call markOnboardingComplete if updateUserLevel fails',
      build: () {
        when(() => mockUpdateUserLevel.execute(tUid, tLevel)).thenAnswer(
          (_) async =>
              const Left(AppFailure.databaseFailure(message: 'DB error')),
        );
        return onboardingBloc;
      },
      act: (bloc) => bloc.add(const SubmitLevel(uid: tUid, level: tLevel)),
      expect: () => [
        const OnboardingState.loading(),
        const OnboardingState.error(message: 'DB error'),
      ],
      verify: (_) {
        verifyNever(() => mockMarkOnboardingComplete.execute());
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'calls markOnboardingComplete only after updateUserLevel succeeds',
      build: () {
        when(
          () => mockUpdateUserLevel.execute(tUid, tLevel),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockMarkOnboardingComplete.execute(),
        ).thenAnswer((_) async => const Right(null));
        return onboardingBloc;
      },
      act: (bloc) => bloc.add(const SubmitLevel(uid: tUid, level: tLevel)),
      expect: () => [
        const OnboardingState.loading(),
        const OnboardingState.complete(),
      ],
      verify: (_) {
        // Verify call order: updateUserLevel first, then markOnboardingComplete
        verifyInOrder([
          () => mockUpdateUserLevel.execute(tUid, tLevel),
          () => mockMarkOnboardingComplete.execute(),
        ]);
      },
    );
  });

  group('SkipGeminiKey design contract', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'emits geminiStepComplete immediately without loading state',
      build: () => onboardingBloc,
      act: (bloc) => bloc.add(const SkipGeminiKey()),
      expect: () => [const OnboardingState.geminiStepComplete()],
      // Document: This is intentional — SkipGeminiKey is a sync UI action,
      // not an async operation, so no loading state is needed.
    );
  });
}
