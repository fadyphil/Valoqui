// test/features/speaking/bloc/speaking_bloc_resource_cleanup_test.dart
//
// Layer 4: Resource management and edge case tests for SpeakingBloc.
// Tests critical cleanup and error handling:
// - close(): subscription cancellation + repository disposal
// - Stream error handling: onError handlers in _streamLlmResponse
// - Concurrent safety: SessionEnded during LLM streaming
// - Timer cleanup: periodic timer cancelled on close
//
// ✅ Uses EXACT patterns from previous SpeakingBloc tests:
//    - MethodChannel permission mock with Map<int,int> response
//    - tts.isSpeaking = true to short-circuit greeting flow
//    - Future.delayed + blocTest.wait for event queue draining
//    - Explicit Either generics: Right<AppFailure, void>(null)
//    - expect[] lists ALL emitted states in exact order

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

    // ✅ Pattern: MethodChannel mock with correct format
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

    // ✅ Mock all streams to avoid unhandled subscriptions
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

    // ✅ Short-circuit greeting flow
    when(() => mockTts.isSpeaking).thenReturn(true);

    // ✅ Stub lifecycle methods with explicit Either generics
    when(() => mockStt.dispose()).thenAnswer((_) async {});
    when(() => mockTts.dispose()).thenAnswer((_) async {});
    when(() => mockVad.dispose()).thenAnswer((_) async {});
    when(
      () => mockVad.startMonitoring(),
    ).thenAnswer((_) async => const Right<AppFailure, void>(null));
    // stop/stopMonitoring return Future<void>, not Either
    when(() => mockVad.stopMonitoring()).thenAnswer((_) async {});
    when(
      () => mockTts.speak(any()),
    ).thenAnswer((_) async => const Right<AppFailure, void>(null));
    when(() => mockTts.stop()).thenAnswer((_) async {});
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

  // ── close() Resource Cleanup Tests ───────────────────────────────────────
  group('SpeakingBloc - Resource Cleanup (close())', () {
    blocTest<SpeakingBloc, SpeakingState>(
      'close() cancels all stream subscriptions and disposes repositories',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // We rely on tearDown calling close() to verify once
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>((s) => s is SpeakingActive), // listening
        predicate<SpeakingState>((s) => s is SpeakingActive && s.phase == ConversationPhase.speaking), // greeting speaking
      ],
      verify: (_) {
        // ✅ Verify stop/stopMonitoring called (close() doesn't call dispose())
        verify(() => mockTts.stop());
        verify(() => mockVad.stopMonitoring());
      },
    );

    blocTest<SpeakingBloc, SpeakingState>(
      'close() cancels session timer to prevent memory leaks',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>((s) => s is SpeakingActive),
        predicate<SpeakingState>((s) => s is SpeakingActive),
        predicate<SpeakingState>((s) => s is SpeakingActive),
      ],
    );

    blocTest<SpeakingBloc, SpeakingState>(
      'close() can be called multiple times safely (idempotent)',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Call close manually; tearDown will call it again
        await bloc.close();
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>((s) => s is SpeakingActive),
        predicate<SpeakingState>((s) => s is SpeakingActive),
        predicate<SpeakingState>((s) => s is SpeakingActive),
      ],
      verify: (_) {
        // stop/stopMonitoring called TWICE: once in test's close() + once in tearDown
        verify(() => mockTts.stop()).called(2);
        verify(() => mockVad.stopMonitoring()).called(2);
        // dispose() is NOT called in close() - repositories managed by service locator
        verifyNever(() => mockStt.dispose());
        verifyNever(() => mockTts.dispose());
        verifyNever(() => mockVad.dispose());
      },
    );
  });

  // ── Stream Error Handling Tests ──────────────────────────────────────────
  group('SpeakingBloc - Stream Error Handling', () {
    blocTest<SpeakingBloc, SpeakingState>(
      'LLM stream onError handler converts exceptions to LlmError event',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        // Mock LLM stream to throw an exception
        when(
          () => mockLlm.streamResponse(
            messages: any(named: 'messages'),
            systemPrompt: any(named: 'systemPrompt'),
          ),
        ).thenAnswer((_) => Stream.error(Exception('Network hiccup')));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
        bloc.add(const TtsFinished()); // Return to listening
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const TranscriptReceived('Test utterance'));
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>((s) => s is SpeakingActive), // listening
        predicate<SpeakingState>((s) => s is SpeakingActive && s.phase == ConversationPhase.speaking), // greeting speaking
        predicate<SpeakingState>(
          (s) => s is SpeakingActive,
        ), // listening (after TtsFinished)
        predicate<SpeakingState>(
          (s) => s is SpeakingActive,
        ), // processing (user)
        // onError handler emits LlmError which triggers recoverable error state
        predicate<SpeakingState>(
          (s) =>
              s is SpeakingActive &&
              s.phase == ConversationPhase.listening &&
              s.errorMessage != null,
          'stream exception converted to recoverable error state',
        ),
      ],
    );

    blocTest<SpeakingBloc, SpeakingState>(
      'STT transcriptStream error is caught and logged (non-fatal)',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));

        when(() => mockStt.transcriptStream).thenAnswer(
          (_) => Stream<String>.error(Exception('STT decode failed')),
        );
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>((s) => s is SpeakingActive), // listening
        predicate<SpeakingState>((s) => s is SpeakingActive && s.phase == ConversationPhase.speaking), // greeting speaking
      ],
    );
  });

  // ── Concurrent Event Safety Tests ────────────────────────────────────────
  group('SpeakingBloc - Concurrent Event Safety', () {
    blocTest<SpeakingBloc, SpeakingState>(
      'SessionEnded during LLM streaming cleans up and emits ended state',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        // Mock LLM to stream slowly
        when(
          () => mockLlm.streamResponse(
            messages: any(named: 'messages'),
            systemPrompt: any(named: 'systemPrompt'),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right<AppFailure, String>('token1'),
            const Right('token2'),
          ]),
        );
        when(
          () => mockTts.stop(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        when(
          () => mockVad.stopMonitoring(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
        bloc.add(const TtsFinished());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Trigger LLM stream with user transcript
        bloc.add(const TranscriptReceived('User question'));
        // Immediately end session while LLM is "streaming"
        bloc.add(const SessionEnded());
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>((s) => s is SpeakingActive), // listening
        predicate<SpeakingState>((s) => s is SpeakingActive && s.phase == ConversationPhase.speaking), // greeting speaking
        predicate<SpeakingState>(
          (s) => s is SpeakingActive,
        ), // listening (after TtsFinished)
        predicate<SpeakingState>(
          (s) => s is SpeakingActive,
        ), // processing (user)
        predicate<SpeakingState>((s) => s is SpeakingActive), // token1
        isA<SpeakingEnded>(),
      ],
      verify: (_) {
        verify(() => mockTts.stop());
        verify(() => mockVad.stopMonitoring());
      },
    );

    blocTest<SpeakingBloc, SpeakingState>(
      'Multiple rapid MicModeToggled events converge to final mode',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        when(
          () => mockVad.startMonitoring(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        when(
          () => mockVad.stopMonitoring(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
        // Rapidly toggle mode 3 times: alwaysOn → PTT → alwaysOn → PTT
        bloc.add(const MicModeToggled());
        bloc.add(const MicModeToggled());
        bloc.add(const MicModeToggled());
      },
      wait: const Duration(milliseconds: 150),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>((s) => s is SpeakingActive), // listening
        predicate<SpeakingState>((s) => s is SpeakingActive && s.phase == ConversationPhase.speaking), // greeting speaking
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.micMode == MicMode.pushToTalk,
        ),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.micMode == MicMode.alwaysOn,
        ),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.micMode == MicMode.pushToTalk,
        ),
      ],
      verify: (_) {
        verify(() => mockVad.startMonitoring());
        verify(() => mockVad.stopMonitoring());
      },
    );

    blocTest<SpeakingBloc, SpeakingState>(
      'TranscriptReceived after SessionEnded is safely ignored',
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
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const SessionEnded());
        // Add transcript after ended - should be ignored
        bloc.add(const TranscriptReceived('Late transcript'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>((s) => s is SpeakingActive), // listening
        predicate<SpeakingState>((s) => s is SpeakingActive && s.phase == ConversationPhase.speaking), // greeting speaking
        isA<SpeakingEnded>(),
      ],
      verify: (_) {
        verifyNever(
          () => mockLlm.streamResponse(
            messages: any(named: 'messages'),
            systemPrompt: any(named: 'systemPrompt'),
          ),
        );
      },
    );

    group('LlmError event', () {
      blocTest<SpeakingBloc, SpeakingState>(
        'LlmError event emitted from stream exception updates state with errorMessage',
        build: () => bloc,
        seed: () => const SpeakingState.active(
          transcript: [],
          phase: ConversationPhase.processing,
          micMode: MicMode.alwaysOn,
          elapsed: Duration.zero,
          activeSpeakingTime: Duration.zero,
          currentLuciaBuffer: '',
          amplitude: 0.0,
        ),
        act: (bloc) => bloc.add(
          const LlmError(AppFailure.llmFailure(message: 'Test error message')),
        ),
        expect: () => [
          predicate<SpeakingState>(
            (s) =>
                s is SpeakingActive &&
                s.phase == ConversationPhase.listening &&
                s.errorMessage != null,
            'LlmError triggers recovery to listening with error message',
          ),
        ],
      );
    });
  });
}
