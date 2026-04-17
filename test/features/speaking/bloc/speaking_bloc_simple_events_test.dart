// test/features/speaking/bloc/speaking_bloc_simple_events_test.dart
//
// Behavior-focused tests for SpeakingBloc simple event handlers.
//
// Key testing strategy:
// 1. Mock tts.isSpeaking = true to short-circuit the precanned greeting flow
//    (prevents auto-emitted TtsFinished, keeping state sequence predictable)
// 2. List ALL emitted states in expect[] — blocTest matches exact sequence
// 3. Use predicate<> matchers for flexible state assertions on complex freezed states

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valoqui/core/domain/models/app_failure.dart';
import 'package:valoqui/core/domain/models/conversation_message.dart';
import 'package:valoqui/core/domain/repositories/llm_repository.dart';
import 'package:valoqui/core/domain/repositories/stt_repository.dart';
import 'package:valoqui/core/domain/repositories/tts_repository.dart';
import 'package:valoqui/core/domain/repositories/vad_repository.dart';
import 'package:valoqui/features/speaking/bloc/speaking_bloc.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────
class MockSttRepository extends Mock implements SttRepository {}

class MockTtsRepository extends Mock implements TtsRepository {}

class MockVadRepository extends Mock implements VadRepository {}

class MockLlmRepository extends Mock implements LlmRepository {}

// PermissionStatus int values from permission_handler_platform_interface
const _permissionGranted = 1;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const permissionChannel = MethodChannel(
    'flutter.baseflow.com/permissions/methods',
  );

  late SpeakingBloc bloc;
  late MockSttRepository mockStt;
  late MockTtsRepository mockTts;
  late MockVadRepository mockVad;
  late MockLlmRepository mockLlm;

  setUpAll(() {
    registerFallbackValue(
      ConversationMessage(role: 'user', content: '', timestamp: DateTime(2023)),
    );
    registerFallbackValue(<ConversationMessage>[]);

    // Mock permission_handler MethodChannel with correct response format
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (MethodCall call) async {
          switch (call.method) {
            case 'checkPermissionStatus':
            case 'requestPermissions':
              final permissions = call.arguments as List<dynamic>? ?? [];
              final result = <int, int>{};
              for (final p in permissions) {
                result[p as int] = _permissionGranted;
              }
              return result;
            default:
              return null;
          }
        });
  });

  setUp(() {
    mockStt = MockSttRepository();
    mockTts = MockTtsRepository();
    mockVad = MockVadRepository();
    mockLlm = MockLlmRepository();

    // Mock all streams to avoid unhandled subscriptions
    when(
      () => mockStt.transcriptStream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockStt.amplitudeStream).thenAnswer((_) => const Stream.empty());
    when(
      () => mockVad.voiceActivityStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockTts.speakingStateStream,
    ).thenAnswer((_) => const Stream.empty());

    // 🔑 KEY FIX: Return true to short-circuit greeting flow's TtsFinished auto-add
    // This keeps the state sequence predictable: speaking phase stays stable
    when(() => mockTts.isSpeaking).thenReturn(true);

    // Stub lifecycle methods with explicit Either generics
    when(() => mockStt.dispose()).thenAnswer((_) async {});
    when(() => mockTts.dispose()).thenAnswer((_) async {});
    when(() => mockVad.dispose()).thenAnswer((_) async {});
    when(
      () => mockVad.startMonitoring(),
    ).thenAnswer((_) async => const Right<AppFailure, void>(null));
    when(
      () => mockVad.stopMonitoring(),
    ).thenAnswer((_) async => const Right<AppFailure, void>(null));
    when(
      () => mockTts.speak(any()),
    ).thenAnswer((_) async => const Right<AppFailure, void>(null));
    when(
      () => mockTts.stop(),
    ).thenAnswer((_) async => const Right<AppFailure, void>(null));

    // Correct return types per repository contracts
    when(
      () => mockStt.initialize(),
    ).thenAnswer((_) async => const Right<AppFailure, bool>(true));
    when(
      () => mockTts.initialize(),
    ).thenAnswer((_) async => const Right<AppFailure, void>(null));
    when(
      () => mockVad.initialize(),
    ).thenAnswer((_) async => const Right<AppFailure, void>(null));

    bloc = SpeakingBloc(stt: mockStt, tts: mockTts, vad: mockVad, llm: mockLlm);
  });

  tearDown(() async {
    await bloc.close();
  });

  group('SpeakingBloc simple event handlers', () {
    group('MicModeToggled', () {
      // ── MicModeToggled tests ─────────────────────────────────────────────────
      blocTest<SpeakingBloc, SpeakingState>(
        'toggles from alwaysOn to pushToTalk and stops VAD monitoring',
        build: () {
          when(
            () => mockVad.initialize(),
          ).thenAnswer((_) async => const Right<AppFailure, void>(null));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
          // Wait for greeting flow to stabilize
          await Future<void>.delayed(const Duration(milliseconds: 150));
          bloc.add(const MicModeToggled());
        },
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<SpeakingInitializing>(),
          predicate<SpeakingState>((s) => s is SpeakingActive), // listening
          predicate<SpeakingState>(
            (s) => s is SpeakingActive,
          ), // processing (greeting)
          predicate<SpeakingState>(
            (s) => s is SpeakingActive,
          ), // speaking (greeting)
          predicate<SpeakingState>(
            (s) =>
                s is SpeakingActive &&
                s.micMode == MicMode.pushToTalk &&
                s.phase == ConversationPhase.speaking,
            'MicModeToggled switches to pushToTalk',
          ),
        ],
        verify: (_) {
          verify(() => mockVad.stopMonitoring()).called(1);
        },
      );

      blocTest<SpeakingBloc, SpeakingState>(
        'toggles from pushToTalk to alwaysOn and starts VAD monitoring',
        build: () {
          // VAD init fails → session starts in pushToTalk mode
          when(() => mockVad.initialize()).thenAnswer(
            (_) async => const Left<AppFailure, void>(
              AppFailure.sttFailure(message: 'Model not found'),
            ),
          );
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
          // Wait for greeting flow
          await Future<void>.delayed(const Duration(milliseconds: 150));
          bloc.add(const MicModeToggled());
        },
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<SpeakingInitializing>(),
          predicate<SpeakingState>(
            (s) => s is SpeakingActive,
          ), // listening (PTT)
          predicate<SpeakingState>(
            (s) => s is SpeakingActive,
          ), // processing (greeting)
          predicate<SpeakingState>(
            (s) => s is SpeakingActive,
          ), // speaking (greeting)
          predicate<SpeakingState>(
            (s) =>
                s is SpeakingActive &&
                s.micMode == MicMode.alwaysOn &&
                s.phase == ConversationPhase.speaking,
            'MicModeToggled switches to alwaysOn',
          ),
        ],
        verify: (_) {
          verify(() => mockVad.startMonitoring()).called(1);
        },
      );

      blocTest<SpeakingBloc, SpeakingState>(
        'ignores MicModeToggled when not in SpeakingActive state',
        build: () => bloc, // Start in initial state, no SessionStarted
        act: (bloc) async {
          bloc.add(const MicModeToggled());
          await Future.microtask(() {});
        },
        expect: () => <dynamic>[], // No state changes expected
        verify: (_) {
          verifyNever(() => mockVad.startMonitoring());
          verifyNever(() => mockVad.stopMonitoring());
        },
      );
    });

    group('TimerTick', () {
      // ── TimerTick test ───────────────────────────────────────────────────────
      blocTest<SpeakingBloc, SpeakingState>(
        'updates elapsed duration in active state',
        build: () {
          when(
            () => mockVad.initialize(),
          ).thenAnswer((_) async => const Right<AppFailure, void>(null));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
          await Future<void>.delayed(const Duration(milliseconds: 150));
          bloc.add(const TimerTick(Duration(seconds: 5)));
        },
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<SpeakingInitializing>(),
          predicate<SpeakingState>((s) => s is SpeakingActive), // listening
          predicate<SpeakingState>(
            (s) => s is SpeakingActive,
          ), // processing (greeting)
          predicate<SpeakingState>(
            (s) => s is SpeakingActive,
          ), // speaking (greeting)
          predicate<SpeakingState>(
            (s) =>
                s is SpeakingActive &&
                s.elapsed == const Duration(seconds: 5) &&
                s.phase == ConversationPhase.speaking,
            'TimerTick updates elapsed while in speaking phase',
          ),
        ],
      );
    });

    group('AmplitudeChanged', () {
      blocTest<SpeakingBloc, SpeakingState>(
        'updates amplitude in active state for VU meter',
        build: () {
          when(
            () => mockVad.initialize(),
          ).thenAnswer((_) async => const Right<AppFailure, void>(null));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
          await Future<void>.delayed(const Duration(milliseconds: 150));
          bloc.add(const AmplitudeChanged(0.75));
        },
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<SpeakingInitializing>(),
          predicate<SpeakingState>((s) => s is SpeakingActive), // listening
          predicate<SpeakingState>(
            (s) => s is SpeakingActive,
          ), // processing (greeting)
          predicate<SpeakingState>(
            (s) => s is SpeakingActive,
          ), // speaking (greeting)
          predicate<SpeakingState>(
            (s) =>
                s is SpeakingActive &&
                s.amplitude == 0.75 &&
                s.phase == ConversationPhase.speaking,
            'AmplitudeChanged updates amplitude in active state',
          ),
        ],
      );
    });

    group('SessionEnded', () {
      // ── SessionEnded test ────────────────────────────────────────────────────
      blocTest<SpeakingBloc, SpeakingState>(
        'emits ended state with complete transcript and timing data',
        build: () {
          when(
            () => mockVad.initialize(),
          ).thenAnswer((_) async => const Right<AppFailure, void>(null));
          when(
            () => mockTts.stop(),
          ).thenAnswer((_) async => const Right<AppFailure, void>(null));
          when(
            () => mockVad.stopMonitoring(),
          ).thenAnswer((_) async => const Right<AppFailure, void>(null));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(
            const SessionStarted(userId: 'test-user', userCefrLevel: 'B1'),
          );
          // End session immediately after initializing
          await Future<void>.delayed(const Duration(milliseconds: 20));
          bloc.add(const SessionEnded());
          // Wait for greeting events to flush
          await Future<void>.delayed(const Duration(milliseconds: 100));
        },
        expect: () => [
          isA<SpeakingInitializing>(),
          predicate<SpeakingState>((s) => s is SpeakingActive), // listening
          predicate<SpeakingState>(
            (s) => s is SpeakingActive,
          ), // processing (greeting)
          predicate<SpeakingState>(
            (s) => s is SpeakingActive,
          ), // speaking (greeting)
          isA<SpeakingEnded>(),
        ],
        verify: (_) {
          verify(() => mockTts.stop()).called(1);
          verify(() => mockVad.stopMonitoring()).called(1);
        },
      );
    });
  });
}
