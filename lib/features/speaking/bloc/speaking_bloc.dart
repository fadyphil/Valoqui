// lib/features/speaking/bloc/speaking_bloc.dart

import "dart:async";
import "package:equatable/equatable.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:permission_handler/permission_handler.dart";
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
  StreamSubscription<bool>? _vadSub;
  StreamSubscription<bool>? _ttsSub;
  Timer? _sessionTimer;

  Duration _elapsed = Duration.zero;
  Duration _activeSpeaking = Duration.zero;
  DateTime? _speechStartTime;

  String _userId = "";
  String _userCefrLevel = "A1";

  bool _ttsWasPlaying = false;
  int _ttsSpokenLength = 0;

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
    on<_LlmTokenReceived>(_onLlmTokenReceived);
    on<_LlmResponseComplete>(_onLlmResponseComplete);
    on<_LlmError>(_onLlmError);
    on<_TtsFinished>(_onTtsFinished);
    on<_TtsStarted>(_onTtsStarted);
  }

  Future<void> _onSessionStarted(
    SessionStarted event,
    Emitter<SpeakingState> emit,
  ) async {
    _userId = event.userId;
    _userCefrLevel = event.userCefrLevel;

    emit(const SpeakingState.initializing());

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      emit(
        const SpeakingState.error(
          message: "Microphone permission is required to speak.",
        ),
      );
      return;
    }

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

    // VAD init failing is non-fatal — it just forces PTT mode.
    final vadResult = await _vad.initialize();
    final micMode = vadResult.isRight() ? MicMode.alwaysOn : MicMode.pushToTalk;

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      add(_TimerTick(_elapsed));
    });

    _transcriptSub = _stt.transcriptStream.listen(
      (text) => add(_TranscriptReceived(text)),
    );

    _vadSub = _vad.voiceActivityStream.listen(
      (isSpeaking) => add(_VoiceActivityChanged(isSpeaking)),
    );

    _ttsSub = _tts.speakingStateStream.listen((isSpeaking) {
      if (isSpeaking) {
        _ttsWasPlaying = true;
        add(const _TtsStarted());
      } else if (_ttsWasPlaying) {
        _ttsWasPlaying = false;
        add(const _TtsFinished());
      }
    });

    if (micMode == MicMode.alwaysOn) {
      await _vad.startMonitoring();
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

  Future<void> _onTtsStarted(
    _TtsStarted event,
    Emitter<SpeakingState> emit,
  ) async {
    final current = state;
    if (current is SpeakingActive && current.micMode == MicMode.alwaysOn) {
      await _vad.stopMonitoring();
    }
  }

  void _onTimerTick(_TimerTick event, Emitter<SpeakingState> emit) {
    final current = state;
    if (current is SpeakingActive) {
      emit(current.copyWith(elapsed: event.elapsed));
    }
  }

  void _onVoiceActivityChanged(
    _VoiceActivityChanged event,
    Emitter<SpeakingState> emit,
  ) {
    // VAD events are only meaningful in always-on mode.
    // In PTT mode the VAD model never loaded, so this never fires anyway,
    // but the guard makes the intent explicit.
    final current = state;
    if (current is SpeakingActive && current.micMode == MicMode.pushToTalk) {
      return;
    }

    if (event.isActive) {
      _speechStartTime ??= DateTime.now();
      _stt.startListening();
    } else {
      _accumulateSpeakingTime();
      _stt.stopListening();
    }
  }

  void _onTranscriptReceived(
    _TranscriptReceived event,
    Emitter<SpeakingState> emit,
  ) {
    final current = state;
    if (current is! SpeakingActive) return;
    if (current.phase == ConversationPhase.speaking ||
        current.phase == ConversationPhase.processing) {
      return;
    }

    final text = event.text.trim();
    if (text.isEmpty) return;

    _processUserUtterance(text, emit);
  }

  void _processUserUtterance(String text, Emitter<SpeakingState> emit) {
    final current = state;
    if (current is! SpeakingActive) return;

    final message = userMessage(text);
    _fullTranscript.add(message);
    _history.add(message);
    if (_history.length > 8) _history.removeAt(0);

    _ttsSpokenLength = 0;

    emit(
      current.copyWith(
        transcript: [...current.transcript, message],
        phase: ConversationPhase.processing,
        partialUserTranscript: null,
      ),
    );

    _streamLlmResponse();
  }

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

    String unspoken = newBuffer.substring(_ttsSpokenLength);
    int boundary;
    while ((boundary = _findFirstSentenceBoundary(unspoken)) != -1) {
      final sentence = unspoken.substring(0, boundary + 1).trim();
      _ttsSpokenLength += boundary + 1;
      unspoken = unspoken.substring(boundary + 1);
      if (sentence.isNotEmpty) {
        _tts.speak(sentence);
      }
    }
  }

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

      final spokenUpTo = _ttsSpokenLength.clamp(0, fullResponse.length);
      final remaining = fullResponse.substring(spokenUpTo).trim();
      if (remaining.isNotEmpty) {
        _tts.speak(remaining);
      }
    }

    _ttsSpokenLength = 0;

    if (fullResponse.isEmpty) {
      emit(
        current.copyWith(
          currentLuciaBuffer: "",
          phase: ConversationPhase.listening,
        ),
      );
    } else {
      emit(
        current.copyWith(
          currentLuciaBuffer: "",
          phase: ConversationPhase.speaking,
        ),
      );
      if (!_tts.isSpeaking && !_ttsWasPlaying) {
        add(const _TtsFinished());
      }
    }
  }

  void _onLlmError(_LlmError event, Emitter<SpeakingState> emit) {
    final current = state;
    if (current is! SpeakingActive) return;

    _ttsSpokenLength = 0;

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
    }
  }

  Future<void> _onTtsFinished(
    _TtsFinished event,
    Emitter<SpeakingState> emit,
  ) async {
    final current = state;
    if (current is! SpeakingActive) return;
    if (current.phase != ConversationPhase.speaking) return;

    if (current.micMode == MicMode.alwaysOn) {
      // Restart monitoring to flush any echo that accumulated during TTS.
      // stopMonitoring disposes the old _audioSub; startMonitoring creates a
      // fresh one — the Silero VAD internal ring buffer starts clean.
      await _vad.startMonitoring();
    }

    emit(current.copyWith(phase: ConversationPhase.listening));
  }

  Future<void> _onSessionEnded(
    SessionEnded event,
    Emitter<SpeakingState> emit,
  ) async {
    _sessionTimer?.cancel();
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

  void _onMicPressed(MicPressed event, Emitter<SpeakingState> emit) {
    _speechStartTime = DateTime.now();
    // Open the microphone (VAD datasource handles this; works even without
    // the VAD model loaded, which is the PTT fallback scenario).
    _vad.startMonitoring();
    // Tell the STT to start buffering bytes immediately.
    _stt.startListening();
  }

  Future<void> _onMicReleased(
    MicReleased event,
    Emitter<SpeakingState> emit,
  ) async {
    _accumulateSpeakingTime();
    // Flush the buffer and kick off decoding before closing the mic.
    _stt.stopListening();
    // Close the mic (PTT) — in always-on mode this would also close it, but
    // always-on never triggers MicReleased from the UI since the button only
    // fires press/release in PTT mode (see mic_button.dart).
    await _vad.stopMonitoring();
  }

  Future<void> _onMicModeToggled(
    MicModeToggled event,
    Emitter<SpeakingState> emit,
  ) async {
    final current = state;
    if (current is! SpeakingActive) return;

    final newMode = current.micMode == MicMode.alwaysOn
        ? MicMode.pushToTalk
        : MicMode.alwaysOn;

    emit(current.copyWith(micMode: newMode));

    if (newMode == MicMode.alwaysOn) {
      await _vad
          .startMonitoring(); // ← was unawaited, a race if called right before recording starts
    } else {
      await _vad.stopMonitoring();
    }
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
    final current = state;
    if (current is SpeakingActive) {
      add(_LlmTokenReceived(greeting));
      add(const _LlmResponseComplete());
    } else {
      final msg = assistantMessage(greeting);
      _fullTranscript.add(msg);
      _history.add(msg);
      Future<void>.microtask(() => _tts.speak(greeting));
    }
  }

  int _findFirstSentenceBoundary(String text) {
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '.' || c == '?' || c == '!' || c == '…') return i;
    }
    return -1;
  }

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
    await _vadSub?.cancel();
    await _ttsSub?.cancel();
    await _stt.dispose();
    await _tts.dispose();
    await _vad.dispose();
    return super.close();
  }
}
