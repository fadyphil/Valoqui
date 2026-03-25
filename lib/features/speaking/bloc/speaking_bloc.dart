// lib/features/speaking/bloc/speaking_bloc.dart
//
// Key fixes vs v1:
//   - Always-on mode no longer starts sherpa VAD monitoring.
//     VAD and Android SpeechRecognizer were both holding the mic,
//     causing degraded audio → empty partials → nothing sent.
//   - Utterance processing in always-on mode is now driven by
//     _FinalTranscriptReceived (STT finalResult=true), not VAD silence.
//   - _TtsFinished event replaces the direct _resumeListening() call,
//     allowing a proper phase→listening state emit from inside a handler.
//   - Active speaking time is tracked via partial transcript callbacks
//     instead of VAD events.

import "dart:async";
import "package:equatable/equatable.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:valoqui/core/constants/lucia_prompt.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/models/conversation_message.dart";
import "package:valoqui/core/domain/repositories/llm_repository.dart";
import "package:valoqui/core/domain/repositories/stt_repository.dart";
import "package:valoqui/core/domain/repositories/tts_repository.dart";
import "package:valoqui/core/domain/repositories/vad_repository.dart";

part "speaking_event.dart";
part "speaking_state.dart";
part "speaking_bloc.freezed.dart";

class SpeakingBloc extends Bloc<SpeakingEvent, SpeakingState> {
  final SttRepository _stt;
  final TtsRepository _tts;
  final VadRepository _vad;
  final LlmRepository _llm;

  final List<ConversationMessage> _history = [];
  final List<ConversationMessage> _fullTranscript = [];

  StreamSubscription<String>? _transcriptSub;
  StreamSubscription<String>? _finalTranscriptSub;
  StreamSubscription<bool>? _vadSub;
  StreamSubscription<bool>? _ttsSub;
  Timer? _sessionTimer;

  Duration _elapsed = Duration.zero;
  Duration _activeSpeaking = Duration.zero;
  DateTime? _speechStartTime;

  String _userId = "";
  String _userCefrLevel = "A1";

  // PTT: buffer latest partial so we process exactly one utterance per release
  String _lastPttText = "";

  // Guard: only resume listening if TTS actually started playing
  bool _ttsWasPlaying = false;

  SpeakingBloc({
    required SttRepository stt,
    required TtsRepository tts,
    required VadRepository vad,
    required LlmRepository llm,
  }) : _stt = stt,
       _tts = tts,
       _vad = vad,
       _llm = llm,
       super(const SpeakingState.initial()) {
    on<SessionStarted>(_onSessionStarted);
    on<SessionEnded>(_onSessionEnded);
    on<MicPressed>(_onMicPressed);
    on<MicReleased>(_onMicReleased);
    on<MicModeToggled>(_onMicModeToggled);
    on<_TimerTick>(_onTimerTick);
    on<_VoiceActivityChanged>(_onVoiceActivityChanged);
    on<_TranscriptReceived>(_onTranscriptReceived);
    on<_FinalTranscriptReceived>(_onFinalTranscriptReceived);
    on<_LlmTokenReceived>(_onLlmTokenReceived);
    on<_LlmResponseComplete>(_onLlmResponseComplete);
    on<_LlmError>(_onLlmError);
    on<_TtsFinished>(_onTtsFinished);
  }

  // ── Session started ────────────────────────────────────

  Future<void> _onSessionStarted(
    SessionStarted event,
    Emitter<SpeakingState> emit,
  ) async {
    _userId = event.userId;
    _userCefrLevel = event.userCefrLevel;

    emit(const SpeakingState.initializing());

    final ttsResult = await _tts.initialize();
    if (ttsResult.isLeft()) {
      emit(
        SpeakingState.error(message: ttsResult.getLeft().toNullable()!.message),
      );
      return;
    }

    final sttResult = await _stt.initialize();
    if (sttResult.isLeft()) {
      emit(
        SpeakingState.error(message: sttResult.getLeft().toNullable()!.message),
      );
      return;
    }

    // VAD init is still attempted for push-to-talk fallback detection,
    // but we do NOT start monitoring in always-on mode (mic conflict).
    final vadResult = await _vad.initialize();
    final micMode = vadResult.isRight() ? MicMode.alwaysOn : MicMode.pushToTalk;

    // Timer: dispatch event instead of calling emit() from callback
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      add(_TimerTick(_elapsed));
    });

    // Partial transcript → live UI display
    _transcriptSub = _stt.transcriptStream.listen(
      (text) => add(_TranscriptReceived(text)),
    );

    // Final transcript → process utterance (replaces VAD silence trigger)
    _finalTranscriptSub = _stt.finalTranscriptStream.listen(
      (text) => add(_FinalTranscriptReceived(text)),
    );

    // TTS state: dispatch _TtsFinished when audio stops
    _ttsSub = _tts.speakingStateStream.listen((isSpeaking) {
      if (isSpeaking) {
        _ttsWasPlaying = true;
      } else if (_ttsWasPlaying) {
        _ttsWasPlaying = false;
        add(const _TtsFinished());
      }
    });

    // Always-on: start STT only — no VAD recorder (mic conflict avoided)
    // Push-to-talk: nothing to start here, button press starts STT
    if (micMode == MicMode.alwaysOn) {
      await _stt.startListening();
    }

    emit(
      SpeakingState.active(
        transcript: const [],
        phase: ConversationPhase.listening,
        micMode: micMode,
        elapsed: Duration.zero,
        activeSpeakingTime: Duration.zero,
        currentLuciaBuffer: "",
      ),
    );

    _deliverPrecannedGreeting();
  }

  // ── Timer tick ─────────────────────────────────────────

  void _onTimerTick(_TimerTick event, Emitter<SpeakingState> emit) {
    final current = state;
    if (current is SpeakingActive) {
      emit(current.copyWith(elapsed: event.elapsed));
    }
  }

  // ── VAD (kept for future use / visual — no longer triggers processing) ──

  void _onVoiceActivityChanged(
    _VoiceActivityChanged event,
    Emitter<SpeakingState> emit,
  ) {
    // VAD is not started in always-on mode so this only fires if
    // VAD monitoring was explicitly started elsewhere (e.g. future sprint).
    if (event.isActive) {
      _speechStartTime ??= DateTime.now();
    } else {
      _accumulateSpeakingTime();
    }
  }

  // ── Partial transcript (always-on: live display + time tracking) ───────

  void _onTranscriptReceived(
    _TranscriptReceived event,
    Emitter<SpeakingState> emit,
  ) {
    final current = state;
    if (current is! SpeakingActive) return;

    if (current.micMode == MicMode.pushToTalk) {
      // PTT: buffer latest partial — _onMicReleased processes exactly once
      _lastPttText = event.text;
    } else {
      // Always-on: start tracking time on first partial of this utterance
      _speechStartTime ??= DateTime.now();
      // Update the live user bubble
      emit(current.copyWith(partialUserTranscript: event.text));
    }
  }

  // ── Final transcript (always-on: triggers LLM call) ────────────────────

  void _onFinalTranscriptReceived(
    _FinalTranscriptReceived event,
    Emitter<SpeakingState> emit,
  ) {
    final current = state;
    if (current is! SpeakingActive) return;
    if (current.micMode != MicMode.alwaysOn) return;
    if (current.phase == ConversationPhase.speaking) return;

    // Accumulate speaking time now that utterance is complete
    _accumulateSpeakingTime();

    final text = event.text.trim();
    if (text.isEmpty) return;

    _processUserUtterance(text, emit);
  }

  // ── Process a complete user utterance ──────────────────

  void _processUserUtterance(String text, Emitter<SpeakingState> emit) {
    final current = state;
    if (current is! SpeakingActive) return;
    if (text.isEmpty) return;

    final message = userMessage(text);
    _fullTranscript.add(message);

    _history.add(message);
    if (_history.length > 8) _history.removeAt(0);

    emit(
      current.copyWith(
        transcript: [...current.transcript, message],
        phase: ConversationPhase.processing,
        partialUserTranscript: null,
      ),
    );

    _streamLlmResponse();
  }

  // ── LLM streaming ──────────────────────────────────────

  void _streamLlmResponse() {
    _llm
        .streamResponse(
          messages: List.from(_history),
          systemPrompt: LuciaPrompt.build(_userCefrLevel),
        )
        .listen(
          (event) => event.fold(
            (failure) => add(_LlmError(failure)),
            (token) => add(_LlmTokenReceived(token)),
          ),
          onDone: () => add(const _LlmResponseComplete()),
        );
  }

  // ── LLM token received ─────────────────────────────────

  void _onLlmTokenReceived(
    _LlmTokenReceived event,
    Emitter<SpeakingState> emit,
  ) {
    final current = state;
    if (current is! SpeakingActive) return;

    final newBuffer = current.currentLuciaBuffer + event.token;
    final updatedTranscript = _upsertLuciaMessage(
      current.transcript,
      newBuffer,
    );

    emit(
      current.copyWith(
        transcript: updatedTranscript,
        currentLuciaBuffer: newBuffer,
        phase: ConversationPhase.processing,
      ),
    );

    // Sentence-boundary TTS: speak first sentence before full response arrives
    if (_isSentenceEnd(event.token) && newBuffer.trim().isNotEmpty) {
      _tts.speak(newBuffer.trim());
    }
  }

  // ── LLM response complete ──────────────────────────────

  void _onLlmResponseComplete(
    _LlmResponseComplete event,
    Emitter<SpeakingState> emit,
  ) {
    final current = state;
    if (current is! SpeakingActive) return;

    final fullResponse = current.currentLuciaBuffer.trim();

    if (fullResponse.isNotEmpty) {
      final message = assistantMessage(fullResponse);
      _fullTranscript.add(message);
      _history.add(message);
      if (_history.length > 8) _history.removeAt(0);

      // Speak any trailing text that didn't hit a sentence boundary
      if (!_isSentenceEnd(fullResponse)) {
        _tts.speak(fullResponse);
      }
    }

    emit(
      current.copyWith(
        currentLuciaBuffer: "",
        phase: ConversationPhase.speaking,
      ),
    );
  }

  // ── LLM error ──────────────────────────────────────────

  void _onLlmError(_LlmError event, Emitter<SpeakingState> emit) {
    final current = state;
    if (current is! SpeakingActive) return;

    final isFatal = event.failure.maybeWhen(
      llmBothProvidersFailed: () => true,
      orElse: () => false,
    );

    if (isFatal) {
      emit(SpeakingState.error(message: event.failure.message));
    } else {
      emit(
        current.copyWith(
          errorMessage: event.failure.message,
          phase: ConversationPhase.listening,
        ),
      );
      _restartListening();
    }
  }

  // ── TTS finished → transition back to listening ─────────

  void _onTtsFinished(_TtsFinished event, Emitter<SpeakingState> emit) {
    final current = state;
    if (current is! SpeakingActive) return;

    emit(current.copyWith(phase: ConversationPhase.listening));

    if (current.micMode == MicMode.alwaysOn) {
      _restartListening();
    }
  }

  // ── Session ended ──────────────────────────────────────

  Future<void> _onSessionEnded(
    SessionEnded event,
    Emitter<SpeakingState> emit,
  ) async {
    _sessionTimer?.cancel();
    await _stt.stopListening();
    await _tts.stop();
    await _vad.stopMonitoring();

    emit(
      SpeakingState.ended(
        transcript: List.from(_fullTranscript),
        totalDuration: _elapsed,
        activeSpeakingTime: _activeSpeaking,
        userId: _userId,
        userCefrLevel: _userCefrLevel,
      ),
    );
  }

  // ── Push-to-talk ───────────────────────────────────────

  void _onMicPressed(MicPressed event, Emitter<SpeakingState> emit) {
    _lastPttText = "";
    _speechStartTime = DateTime.now();
    _stt.startListening();
  }

  Future<void> _onMicReleased(
    MicReleased event,
    Emitter<SpeakingState> emit,
  ) async {
    _accumulateSpeakingTime();
    await _stt.stopListening();

    final text = _lastPttText.trim();
    _lastPttText = "";
    if (text.isNotEmpty) {
      _processUserUtterance(text, emit);
    }
  }

  // ── Mic mode toggle ────────────────────────────────────

  void _onMicModeToggled(MicModeToggled event, Emitter<SpeakingState> emit) {
    final current = state;
    if (current is! SpeakingActive) return;

    final newMode = current.micMode == MicMode.alwaysOn
        ? MicMode.pushToTalk
        : MicMode.alwaysOn;

    emit(current.copyWith(micMode: newMode));

    if (newMode == MicMode.alwaysOn) {
      _stt.startListening();
    } else {
      _vad.stopMonitoring();
      _stt.stopListening();
    }
  }

  // ── Helpers ────────────────────────────────────────────

  /// Restart STT after 400ms delay so the OS has time to return
  /// audio focus to the microphone after TTS playback.
  void _restartListening() {
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!isClosed) _stt.startListening();
    });
  }

  void _accumulateSpeakingTime() {
    if (_speechStartTime != null) {
      _activeSpeaking += DateTime.now().difference(_speechStartTime!);
      _speechStartTime = null;
    }
  }

  void _deliverPrecannedGreeting() {
    const greeting =
        "¡Hola! Me alegra que estés aquí. ¿De qué te gustaría hablar hoy?";
    final msg = assistantMessage(greeting);
    _fullTranscript.add(msg);

    final current = state;
    if (current is SpeakingActive) {
      add(_LlmTokenReceived(greeting));
      add(const _LlmResponseComplete());
    } else {
      Future<void>.microtask(() => _tts.speak(greeting));
    }
  }

  bool _isSentenceEnd(String token) =>
      token.endsWith(".") ||
      token.endsWith("?") ||
      token.endsWith("!") ||
      token.endsWith("…");

  List<ConversationMessage> _upsertLuciaMessage(
    List<ConversationMessage> transcript,
    String buffer,
  ) {
    if (transcript.isNotEmpty && transcript.last.isAssistant) {
      return [
        ...transcript.sublist(0, transcript.length - 1),
        assistantMessage(buffer),
      ];
    }
    return [...transcript, assistantMessage(buffer)];
  }

  @override
  Future<void> close() async {
    _sessionTimer?.cancel();
    await _transcriptSub?.cancel();
    await _finalTranscriptSub?.cancel();
    await _vadSub?.cancel();
    await _ttsSub?.cancel();
    await _stt.dispose();
    await _tts.dispose();
    await _vad.dispose();
    return super.close();
  }
}
