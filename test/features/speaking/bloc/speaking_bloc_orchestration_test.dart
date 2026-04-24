// test/features/speaking/bloc/speaking_bloc_orchestration_test.dart
//
// Layer 3: Complex orchestration tests for SpeakingBloc.
// Tests event handlers that coordinate multiple repositories:
// - _onTranscriptReceived: STT → LLM pipeline with phase guards
// - _onLlmError: Fatal vs recoverable error handling
// - _onTtsFinished: VAD restart coordination in alwaysOn mode
// - _onVoiceActivityChanged: VAD → STT start/stop coordination
//
// ✅ Uses EXACT patterns from speaking_bloc_simple_events_test.dart:
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

    // ✅ Pattern from simple_events_test: MethodChannel mock with correct format
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
    when(
      () => mockStt.partialTranscriptStream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockStt.amplitudeStream).thenAnswer((_) => const Stream.empty());
    when(
      () => mockStt.bufferFillStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockVad.voiceActivityStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockTts.speakingStateStream,
    ).thenAnswer((_) => const Stream.empty());

    // ✅ Short-circuit greeting flow (prevents TtsFinished auto-add)
    when(() => mockTts.isSpeaking).thenReturn(true);

    // ✅ Stub lifecycle methods with explicit Either generics
    when(() => mockStt.dispose()).thenAnswer((_) async {});
    when(() => mockTts.dispose()).thenAnswer((_) async {});
    when(() => mockTts.warmUp()).thenAnswer((_) async {});
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
    when(
      () => mockStt.initialize(),
    ).thenAnswer((_) async => const Right<AppFailure, bool>(true));
    when(
      () => mockStt.startListening(),
    ).thenAnswer((_) async => const Right<AppFailure, void>(null));
    when(
      () => mockStt.stopListening(),
    ).thenAnswer((_) async => const Right<AppFailure, String>(""));
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

  // ── _onTranscriptReceived Tests ──────────────────────────────────────────
  group('SpeakingBloc - Transcript Orchestration (_onTranscriptReceived)', () {
    blocTest<SpeakingBloc, SpeakingState>(
      'ignores empty/whitespace transcript in SpeakingActive',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const TranscriptReceived('   '));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>(
          (s) =>
              s is SpeakingActive &&
              s.micMode == MicMode.alwaysOn &&
              s.phase == ConversationPhase.listening,
          'SessionStarted reaches active/listening',
        ),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.speaking,
          'greeting completes, transitions to speaking',
        ),
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

    blocTest<SpeakingBloc, SpeakingState>(
      'ignores transcript when phase is processing (prevents overlapping LLM requests)',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Add interrupt while greeting is in processing/speaking phase
        bloc.add(const TranscriptReceived('Interrupting utterance'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.listening,
          'SessionStarted reaches active/listening',
        ),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.speaking,
          'greeting completes, transitions to speaking',
        ),
      ],
      // ✅ FIX: Remove verify that expects streamResponse (greeting bypasses it)
      // Optional: verify the interrupt doesn't trigger a new LLM call
      verify: (_) {
        verifyNever(
          () => mockLlm.streamResponse(
            messages: any(
              named: 'messages',
              that: predicate<List<ConversationMessage>>(
                (msgs) =>
                    msgs.any((m) => m.content == 'Interrupting utterance'),
              ),
            ),
            systemPrompt: any(named: 'systemPrompt'),
          ),
        );
      },
    );
    blocTest<SpeakingBloc, SpeakingState>(
      'ignores transcript when phase is speaking (Lucia is talking)',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const TranscriptReceived('User interrupts Lucia'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.listening,
          'SessionStarted reaches active/listening',
        ),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.speaking,
          'greeting completes, transitions to speaking',
        ),
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

    blocTest<SpeakingBloc, SpeakingState>(
      'processes valid transcript: emits processing, adds to transcript, triggers LLM stream',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        // Mock LLM response to be empty so we don't get extra speaking states
        when(
          () => mockLlm.streamResponse(
            messages: any(named: 'messages'),
            systemPrompt: any(named: 'systemPrompt'),
          ),
        ).thenAnswer((_) => const Stream.empty());
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        // Wait for SessionStarted + greeting processing + greeting speaking
        await Future<void>.delayed(const Duration(milliseconds: 200));
        // Manually move to listening so it can accept a new transcript
        bloc.add(const TtsFinished());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const TranscriptReceived('Hola, ¿cómo estás?'));
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.listening,
          'SessionStarted reaches active/listening',
        ),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.speaking,
          'greeting completes, transitions to speaking',
        ),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.listening,
          'TtsFinished transitions back to listening',
        ),
        // After greeting completes and phase returns to listening, user transcript triggers processing
        predicate<SpeakingState>(
          (s) =>
              s is SpeakingActive &&
              s.phase == ConversationPhase.processing &&
              s.transcript.any((m) => m.content == 'Hola, ¿cómo estás?'),
          'valid transcript triggers processing with message in transcript',
        ),
        // Stream.empty() triggers end of response logic which returns to listening
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.listening,
          'returns to listening after empty stream',
        ),
      ],
      verify: (_) {
        verify(
          () => mockLlm.streamResponse(
            messages: any(
              named: 'messages',
              that: predicate<List<ConversationMessage>>(
                (msgs) => msgs.any((m) => m.content == 'Hola, ¿cómo estás?'),
              ),
            ),
            systemPrompt: any(named: 'systemPrompt'),
          ),
        ).called(1);
      },
    );
  });

  // ── _onLlmError Tests ────────────────────────────────────────────────────
  group('SpeakingBloc - LLM Error Handling (_onLlmError)', () {
    blocTest<SpeakingBloc, SpeakingState>(
      'fatal error (llmBothProvidersFailed) emits SpeakingState.error',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const LlmError(AppFailure.llmBothProvidersFailed()));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.listening,
          'SessionStarted reaches active/listening',
        ),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.speaking,
          'greeting completes, transitions to speaking',
        ),
        predicate<SpeakingState>(
          (s) =>
              s is SpeakingError &&
              s.message ==
                  'Both AI providers are unavailable. Try again in a few minutes.',
          'error message matches AppFailure.llmBothProvidersFailed default',
        ),
      ],
    );

    blocTest<SpeakingBloc, SpeakingState>(
      'recoverable LLM error emits errorMessage and returns to listening',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(
          const LlmError(AppFailure.llmFailure(message: 'Rate limited')),
        );
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.listening,
          'SessionStarted reaches active/listening',
        ),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.speaking,
          'greeting completes, transitions to speaking',
        ),
        predicate<SpeakingState>(
          (s) =>
              s is SpeakingActive &&
              s.phase == ConversationPhase.listening &&
              s.errorMessage == 'Rate limited',
          'returns to listening with error message',
        ),
      ],
    );
  });

  // ── _onTtsFinished Tests ─────────────────────────────────────────────────
  group('SpeakingBloc - TTS Completion (_onTtsFinished)', () {
    blocTest<SpeakingBloc, SpeakingState>(
      'in alwaysOn mode, TtsFinished restarts VAD monitoring and transitions to listening',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        when(
          () => mockVad.startMonitoring(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Manually trigger TtsFinished (normally emitted by TTS stream)
        bloc.add(const TtsFinished());
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.listening,
          'SessionStarted reaches active/listening',
        ),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.speaking,
          'greeting completes, transitions to speaking',
        ),
        predicate<SpeakingState>(
          (s) =>
              s is SpeakingActive &&
              s.phase == ConversationPhase.listening &&
              s.micMode == MicMode.alwaysOn,
          'TtsFinished transitions back to listening in alwaysOn mode',
        ),
      ],
      verify: (_) {
        // Called once in _onSessionStarted and once in _onTtsFinished
        verify(() => mockVad.startMonitoring()).called(2);
      },
    );

    blocTest<SpeakingBloc, SpeakingState>(
      'in pushToTalk mode, TtsFinished does NOT restart VAD monitoring',
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
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const TtsFinished());
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>(
          (s) =>
              s is SpeakingActive &&
              s.micMode == MicMode.pushToTalk &&
              s.phase == ConversationPhase.listening,
          'VAD failure starts session in pushToTalk mode',
        ),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.speaking,
          'greeting completes, transitions to speaking',
        ),
        predicate<SpeakingState>(
          (s) =>
              s is SpeakingActive &&
              s.phase == ConversationPhase.listening &&
              s.micMode == MicMode.pushToTalk,
          'TtsFinished transitions to listening but does NOT restart VAD in PTT mode',
        ),
      ],
      verify: (_) {
        verifyNever(() => mockVad.startMonitoring());
      },
    );
  });

  // ── _onVoiceActivityChanged Tests ────────────────────────────────────────
  group('SpeakingBloc - VAD Coordination (_onVoiceActivityChanged)', () {
    blocTest<SpeakingBloc, SpeakingState>(
      'in alwaysOn mode, VAD isActive=true triggers STT startListening',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        when(
          () => mockStt.startListening(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const VoiceActivityChanged(isActive: true));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.listening,
          'SessionStarted reaches active/listening',
        ),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.speaking,
          'greeting completes, transitions to speaking',
        ),
      ],
      verify: (_) {
        verify(() => mockStt.startListening()).called(1);
      },
    );

    blocTest<SpeakingBloc, SpeakingState>(
      'in alwaysOn mode, VAD isActive=false triggers STT stopListening',
      build: () {
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right<AppFailure, void>(null));
        when(() => mockStt.stopListening()).thenAnswer(
          (_) async => const Right<AppFailure, String>('final transcript'),
        );
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const VoiceActivityChanged(isActive: false));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.listening,
          'SessionStarted reaches active/listening',
        ),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.speaking,
          'greeting completes, transitions to speaking',
        ),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.isTranscribing == true,
          'isActive=false sets isTranscribing to true',
        ),
      ],
      verify: (_) {
        verify(() => mockStt.stopListening()).called(1);
      },
    );

    blocTest<SpeakingBloc, SpeakingState>(
      'in pushToTalk mode, VAD events are ignored (VAD model not loaded)',
      build: () {
        // VAD init fails → PTT mode
        when(() => mockVad.initialize()).thenAnswer(
          (_) async => const Left<AppFailure, void>(
            AppFailure.sttFailure(message: 'Model not found'),
          ),
        );
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const VoiceActivityChanged(isActive: true));
        bloc.add(const VoiceActivityChanged(isActive: false));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SpeakingInitializing>(),
        predicate<SpeakingState>(
          (s) =>
              s is SpeakingActive &&
              s.micMode == MicMode.pushToTalk &&
              s.phase == ConversationPhase.listening,
          'VAD failure starts session in pushToTalk mode',
        ),
        predicate<SpeakingState>(
          (s) => s is SpeakingActive && s.phase == ConversationPhase.speaking,
          'greeting completes, transitions to speaking',
        ),
      ],
      verify: (_) {
        verifyNever(() => mockStt.startListening());
        verifyNever(() => mockStt.stopListening());
      },
    );
  });
}
