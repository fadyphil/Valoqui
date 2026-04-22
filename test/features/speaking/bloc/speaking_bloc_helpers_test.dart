// test/features/speaking/bloc/speaking_bloc_helpers_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SpeakingBloc speakingBloc;
  late MockSttRepository mockStt;
  late MockTtsRepository mockTts;
  late MockVadRepository mockVad;
  late MockLlmRepository mockLlm;

  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');

  setUpAll(() {
    registerFallbackValue(
      ConversationMessage(role: 'user', content: '', timestamp: DateTime(2023)),
    );
    registerFallbackValue(<ConversationMessage>[]);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'requestPermissions') {
            final List<dynamic> permissions =
                methodCall.arguments as List<dynamic>;
            final Map<int, int> map = <int, int>{};
            for (final p in permissions) {
              map[p as int] = 1; // PermissionStatus.granted
            }
            return map;
          }
          if (methodCall.method == 'checkPermissionStatus') {
            return 1; // PermissionStatus.granted
          }
          return null;
        });
  });

  setUp(() {
    mockStt = MockSttRepository();
    mockTts = MockTtsRepository();
    mockVad = MockVadRepository();
    mockLlm = MockLlmRepository();

    // Default stubs for stream getters
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
    when(() => mockTts.isSpeaking).thenReturn(false);

    // Stub dispose methods
    when(() => mockStt.dispose()).thenAnswer((_) async {});
    when(() => mockTts.dispose()).thenAnswer((_) async {});
    when(() => mockVad.dispose()).thenAnswer((_) async {});

    // Stub stop/stopMonitoring (return void, not Either)
    when(() => mockTts.stop()).thenAnswer((_) async {});
    when(() => mockTts.warmUp()).thenAnswer((_) async {});
    when(() => mockVad.stopMonitoring()).thenAnswer((_) async {});

    // Stub startMonitoring
    when(
      () => mockVad.startMonitoring(),
    ).thenAnswer((_) async => const Right(null));

    // Stub speak
    when(() => mockTts.speak(any())).thenAnswer((_) async => const Right(null));

    speakingBloc = SpeakingBloc(
      stt: mockStt,
      tts: mockTts,
      vad: mockVad,
      llm: mockLlm,
    );
  });

  tearDown(() {
    speakingBloc.close();
  });

  group('SpeakingBloc pure helper effects', () {
    // ── _findFirstSentenceBoundary effects ─────────────────────────────────
    // Tested indirectly via _onLlmTokenReceived → TTS speak() calls

    blocTest<SpeakingBloc, SpeakingState>(
      'triggers TTS speak at sentence boundaries (. ? ! …)',
      build: () {
        when(
          () => mockLlm.streamResponse(
            messages: any(named: 'messages'),
            systemPrompt: any(named: 'systemPrompt'),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            Either.right('Hola.'), // boundary at index 4
            Either.right(' ¿Cómo'), // no boundary
            Either.right(' estás?'), // boundary at index 6 of this token
          ]),
        );
        return speakingBloc;
      },
      act: (bloc) async {
        // Start session first to get to SpeakingActive state
        when(
          () => mockStt.initialize(),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => mockTts.initialize(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockStt.startListening(),
        ).thenAnswer((_) async => const Right(null));

        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(
          const Duration(milliseconds: 100),
        ); // Wait for greeting to finish
        clearInteractions(mockTts);

        // Now trigger LLM token handling indirectly via stream
        // (In real usage, tokens come from _llm.streamResponse stream)
        // For this test, we simulate by adding internal events
        bloc.add(const LlmTokenReceived('Hola.'));
        bloc.add(const LlmTokenReceived(' ¿Cómo'));
        bloc.add(const LlmTokenReceived(' estás?'));
        await Future.microtask(() {});
      },
      // Verify TTS.speak was called for each sentence boundary
      verify: (_) {
        // Should speak "Hola." and "¿Cómo estás?" as separate sentences (trimmed)
        verify(() => mockTts.speak('Hola.')).called(1);
        verify(() => mockTts.speak('¿Cómo estás?')).called(1);
      },
    );

    blocTest<SpeakingBloc, SpeakingState>(
      'does not trigger TTS for text without sentence boundaries',
      build: () {
        when(
          () => mockLlm.streamResponse(
            messages: any(named: 'messages'),
            systemPrompt: any(named: 'systemPrompt'),
          ),
        ).thenAnswer(
          (_) => Stream.value(Either.right('Hola que tal')),
        ); // no boundary chars
        return speakingBloc;
      },
      act: (bloc) async {
        when(
          () => mockStt.initialize(),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => mockTts.initialize(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockStt.startListening(),
        ).thenAnswer((_) async => const Right(null));

        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        clearInteractions(mockTts);

        bloc.add(const LlmTokenReceived('Hola que tal'));
        await Future.microtask(() {});
      },
      verify: (_) {
        // No speak() calls for text without boundaries
        verifyNever(() => mockTts.speak(any()));
      },
    );

    // ── _upsertLuciaMessage effects ────────────────────────────────────────
    // Tested indirectly via transcript state updates in _onLlmTokenReceived

    blocTest<SpeakingBloc, SpeakingState>(
      'appends new assistant message when transcript last message is user',
      build: () {
        when(
          () => mockLlm.streamResponse(
            messages: any(named: 'messages'),
            systemPrompt: any(named: 'systemPrompt'),
          ),
        ).thenAnswer((_) => Stream.value(Either.right('Hello')));
        return speakingBloc;
      },
      act: (bloc) async {
        when(
          () => mockStt.initialize(),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => mockTts.initialize(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockStt.startListening(),
        ).thenAnswer((_) async => const Right(null));

        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Simulate user message via TranscriptReceived
        // This triggers the LLM response stream returning 'Hello'
        bloc.add(const TranscriptReceived('Hi Lucia'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      verify: (bloc) {
        final state = bloc.state as SpeakingActive;
        expect(state.transcript.length, 3); // Greeting, User, Assistant
        expect(state.transcript[0].isAssistant, true); // Greeting
        expect(state.transcript[1].isUser, true); // "Hi Lucia"
        expect(state.transcript[2].isAssistant, true); // "Hello"
        expect(state.transcript[2].content, 'Hello');
      },
    );

    blocTest<SpeakingBloc, SpeakingState>(
      'replaces partial assistant message when streaming continues',
      build: () {
        when(
          () => mockLlm.streamResponse(
            messages: any(named: 'messages'),
            systemPrompt: any(named: 'systemPrompt'),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            Either.right('Hello'),
            Either.right(' World'),
          ]),
        );
        return speakingBloc;
      },
      act: (bloc) async {
        when(
          () => mockStt.initialize(),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => mockTts.initialize(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockVad.initialize(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockStt.startListening(),
        ).thenAnswer((_) async => const Right(null));

        bloc.add(const SessionStarted(userId: 'u1', userCefrLevel: 'A1'));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Simulate user message via TranscriptReceived
        // This triggers the LLM response stream returning 'Hello' then ' World'
        bloc.add(const TranscriptReceived('Hi Lucia'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      verify: (bloc) {
        final state = bloc.state as SpeakingActive;
        // If it appended instead of replacing, length would be 4.
        expect(state.transcript.length, 3); // Greeting, User, Assistant
        expect(state.transcript[2].isAssistant, true);
        expect(state.transcript[2].content, 'Hello World');
      },
    );
  });
}
