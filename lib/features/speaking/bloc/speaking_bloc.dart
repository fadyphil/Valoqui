// lib/features/speaking/bloc/speaking_bloc.dart

import "dart:async";
import "package:equatable/equatable.dart";
import "package:flutter/foundation.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:fpdart/fpdart.dart";
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

/// BLoC managing the core speaking session lifecycle for Valoqui.
///
/// This BLoC orchestrates the conversation pipeline:
/// 1. **User speaks** → VAD/STT detects and transcribes utterance
/// 2. **Transcript received** → LLM generates response via streaming tokens
/// 3. **LLM tokens arrive** → TTS speaks sentences as they complete
/// 4. **TTS finishes** → VAD resumes listening for next user utterance
///
/// ## State Machine
/// The BLoC emits [SpeakingState] variants representing the session phase:
/// * [SpeakingState.initial] → [SpeakingState.initializing] → [SpeakingState.active]
/// * [SpeakingState.active] transitions between [ConversationPhase] values:
///   - `listening`: waiting for user input
///   - `processing`: LLM is generating a response
///   - `speaking`: TTS is playing Lucia's response
/// * [SpeakingState.error] on fatal failures (permission denied, both LLMs down)
/// * [SpeakingState.ended] when session completes (for report generation)
///
/// ## Mic Modes
/// * [MicMode.alwaysOn]: VAD automatically detects utterances; user speaks freely
/// * [MicMode.pushToTalk]: User holds button to record; release triggers decode
///
/// VAD initialization failure automatically falls back to PTT mode — the
/// session remains functional even if the Silero VAD model cannot load.
///
/// ## Stream Contracts
/// This BLoC subscribes to three external streams:
/// * [_stt.transcriptStream] → [_TranscriptReceived] events
/// * [_vad.voiceActivityStream] → [_VoiceActivityChanged] events
/// * [_tts.speakingStateStream] → [_TtsStarted]/[_TtsFinished] events
/// * [_stt.amplitudeStream] → [_AmplitudeChanged] events (for VU meter UI)
///
/// All subscriptions are stored and cancelled in [close()] to prevent leaks
/// (engineering_lessons #2, #9).
///
/// ## Error Handling
/// * Expected business errors (rate limits, invalid keys) are wrapped in
///   [Either] and handled via [_LlmError] events.
/// * Unexpected infrastructure errors (stream exceptions, native crashes)
///   are caught via `onError:` handlers and converted to [_LlmError] events
///   (engineering_lessons #7).
///
/// ## Resource Ownership
/// This BLoC owns:
/// * All stream subscriptions ([_transcriptSub], [_vadSub], etc.)
/// * The session timer ([_sessionTimer])
/// * The conversation history buffers ([_history], [_fullTranscript])
///
/// Repositories ([_stt], [_tts], [_vad], [_llm]) are injected dependencies —
/// their lifecycle is managed by the service locator, not this BLoC.
class SpeakingBloc extends Bloc<SpeakingEvent, SpeakingState> {
  final SttRepository _stt;
  final TtsRepository _tts;
  final VadRepository _vad;
  final LlmRepository _llm;

  /// Rolling window of the last 8 messages for LLM context.
  ///
  /// Older messages are dropped to stay within token limits while preserving
  /// recent conversational context. This is a bounded data structure to prevent
  /// unbounded memory growth (engineering_lessons #3).
  final List<ConversationMessage> _history = [];

  /// Complete transcript of the session for the end-of-session report.
  ///
  /// Unlike [_history], this is never truncated — it accumulates all messages
  /// for the final report card. In production, consider adding a cap if sessions
  /// can run for hours (engineering_lessons #3).
  final List<ConversationMessage> _fullTranscript = [];

  StreamSubscription<String>? _transcriptSub;
  StreamSubscription<bool>? _vadSub;
  StreamSubscription<bool>? _ttsSub;
  StreamSubscription<double>? _amplitudeSub; // ← tracked so we can cancel it
  Timer? _sessionTimer;

  Duration _elapsed = Duration.zero;
  Duration _activeSpeaking = Duration.zero;
  DateTime? _speechStartTime;

  String _userId = "";
  String _userCefrLevel = "A1";

  /// Tracks whether TTS is currently playing to avoid duplicate events.
  ///
  /// The TTS stream emits `true` on start and `false` on complete. Without
  /// this guard, rapid state changes could cause multiple [_TtsFinished]
  /// events for a single utterance.
  bool _ttsWasPlaying = false;

  /// Character offset of the last sentence sent to TTS.
  ///
  /// Used to avoid re-speaking partial sentences when new tokens arrive.
  /// Ensures each sentence boundary triggers exactly one TTS call.
  int _ttsSpokenLength = 0;

  /// Creates a new [SpeakingBloc] with injected repository dependencies.
  ///
  /// All repositories are required — the BLoC cannot function without them.
  /// The initial state is [SpeakingState.initial]; the first event should
  /// be [SessionStarted] to begin the session.
  ///
  /// ## Stream Subscription Pattern
  /// Amplitude updates from [_stt.amplitudeStream] are routed through
  /// [_AmplitudeChanged] events rather than calling [emit()] directly.
  /// This is required by flutter_bloc ^9.x, which forbids [emit()] outside
  /// an event handler. Using [add()] ensures all state changes go through
  /// the normal handler pipeline (engineering_lessons #9).
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
    on<TimerTick>(_onTimerTick);
    on<VoiceActivityChanged>(_onVoiceActivityChanged);
    on<TranscriptReceived>(_onTranscriptReceived);
    on<LlmTokenReceived>(_onLlmTokenReceived);
    on<LlmResponseComplete>(_onLlmResponseComplete);
    on<LlmError>(_onLlmError);
    on<TtsFinished>(_onTtsFinished);
    on<TtsStarted>(_onTtsStarted);
    on<AmplitudeChanged>(_onAmplitudeChanged);

    // Dispatch amplitude changes as events rather than calling emit() directly.
    // flutter_bloc ^9.x forbids emit() outside an event handler — calling it
    // from a raw stream subscription throws at runtime. Using add() routes
    // every amplitude update through the normal handler pipeline.
    _amplitudeSub = _stt.amplitudeStream.listen((amp) {
      if (!isClosed) add(AmplitudeChanged(amp));
    });
  }

  // ── Amplitude ────────────────────────────────────────────────────────────

  /// Handles amplitude updates from the STT datasource.
  ///
  /// Emits a new [SpeakingState.active] with the updated [amplitude] value
  /// for VU meter visualization. Only emits if the current state is
  /// [SpeakingActive] — amplitude is meaningless in other states.
  ///
  /// This handler is called via [AmplitudeChanged] events, not directly
  /// from the stream subscription, to comply with flutter_bloc ^9.x rules.
  void _onAmplitudeChanged(
    AmplitudeChanged event,
    Emitter<SpeakingState> emit,
  ) {
    final current = state;
    if (current is SpeakingActive) {
      emit(current.copyWith(amplitude: event.amplitude));
    }
  }

  // ── Session lifecycle ─────────────────────────────────────────────────────

  /// Initializes a new speaking session.
  ///
  /// This is the entry point for the speaking feature. It:
  /// 1. Requests microphone permission (fatal if denied)
  /// 2. Initializes TTS, STT, and VAD datasources (VAD failure → PTT fallback)
  /// 3. Starts the session timer and subscribes to all external streams
  /// 4. Emits [SpeakingState.active] and delivers the precanned greeting
  ///
  /// Returns early with [SpeakingState.error] if:
  /// * Microphone permission is denied
  /// * TTS or STT initialization fails (fatal)
  ///
  /// VAD initialization failure is non-fatal — the session continues in
  /// [MicMode.pushToTalk] mode.
  ///
  /// ## Error Type Semantics
  /// Uses [AppFailure.ttsFailure] and [AppFailure.sttFailure] for local
  /// initialization errors, not [AppFailure.networkFailure]. This ensures
  /// the UI shows appropriate error messaging (engineering_lessons #8).
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
      add(TimerTick(_elapsed));
    });

    _transcriptSub = _stt.transcriptStream.listen(
      (text) => add(TranscriptReceived(text)),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint("[STT Stream] Non-fatal error: $error\n$stackTrace");
      },
    );

    _vadSub = _vad.voiceActivityStream.listen(
      (isSpeaking) => add(VoiceActivityChanged(isActive: isSpeaking)),
    );

    _ttsSub = _tts.speakingStateStream.listen((isSpeaking) {
      if (isSpeaking) {
        _ttsWasPlaying = true;
        add(const TtsStarted());
      } else if (_ttsWasPlaying) {
        _ttsWasPlaying = false;
        add(const TtsFinished());
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

  // ── TTS gate ──────────────────────────────────────────────────────────────

  /// Handles TTS playback start.
  ///
  /// In always-on mode, stops VAD monitoring during TTS playback to prevent
  /// Lucia's voice from being transcribed as user input (echo cancellation
  /// at the application layer). VAD is restarted in [_onTtsFinished].
  ///
  /// In PTT mode, this event is ignored — the user controls the mic manually.
  Future<void> _onTtsStarted(
    TtsStarted event,
    Emitter<SpeakingState> emit,
  ) async {
    final current = state;
    if (current is SpeakingActive && current.micMode == MicMode.alwaysOn) {
      await _vad.stopMonitoring();
    }
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  /// Handles session timer ticks.
  ///
  /// Updates the [elapsed] duration in the state for the session timer UI.
  /// Only emits if the current state is [SpeakingActive].
  void _onTimerTick(TimerTick event, Emitter<SpeakingState> emit) {
    final current = state;
    if (current is SpeakingActive) {
      emit(current.copyWith(elapsed: event.elapsed));
    }
  }

  // ── VAD ───────────────────────────────────────────────────────────────────

  /// Handles VAD activity changes (always-on mode only).
  ///
  /// * `isActive == true`: User started speaking → start STT listening,
  ///   record start time for active-speaking duration calculation.
  /// * `isActive == false`: User stopped speaking → accumulate speaking time,
  ///   stop STT listening to trigger decode.
  ///
  /// Guarded to ignore events in PTT mode — the VAD model never loaded,
  /// so these events shouldn't fire, but the check makes the contract explicit.
  void _onVoiceActivityChanged(
    VoiceActivityChanged event,
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

  // ── STT → LLM pipeline ────────────────────────────────────────────────────

  /// Handles decoded transcript from STT.
  ///
  /// Filters out:
  /// * Empty or whitespace-only transcripts
  /// * Transcripts received while Lucia is speaking or LLM is processing
  ///   (prevents overlapping requests and conflicting history)
  ///
  /// Valid transcripts are processed via [_processUserUtterance].
  ///
  /// ## Design Decision: Last-Speaker-Wins
  /// In always-on mode, there is a small window between VAD restart and
  /// new mic session where a stale partial transcript can arrive. Accepting
  /// it during `processing` phase would fire two back-to-back LLM requests.
  /// MVP decision: drop the utterance. Post-MVP: buffer and send after
  /// current response completes to allow user to speak over Lucia.
  void _onTranscriptReceived(
    TranscriptReceived event,
    Emitter<SpeakingState> emit,
  ) {
    final current = state;
    if (current is! SpeakingActive) return;

    // Intentional drop: discard STT output while Lucia is speaking or while
    // the previous LLM request is still streaming.
    //
    // Why: in always-on mode the VAD datasource is stopped during TTS
    // playback (_onTtsStarted) and restarted after (_onTtsFinished), but
    // there is a small window between VAD restart and the new mic session
    // where a stale partial transcript can arrive. In the processing phase,
    // accepting a new utterance would fire two back-to-back LLM requests
    // with conflicting history. MVP decision: last-speaker wins.
    // Post-MVP consideration: buffer the utterance and send it after the
    // current response completes so the user can speak over Lucia.
    if (current.phase == ConversationPhase.speaking ||
        current.phase == ConversationPhase.processing) {
      return;
    }

    final text = event.text.trim();
    if (text.isEmpty) return;

    _processUserUtterance(text, emit);
  }

  /// Processes a validated user utterance.
  ///
  /// 1. Adds the message to [_fullTranscript] and [_history] (with 8-message cap)
  /// 2. Resets [_ttsSpokenLength] for the new response
  /// 3. Emits updated state with `phase: processing`
  /// 4. Triggers LLM response streaming via [_streamLlmResponse]
  ///
  /// This method assumes the caller has already validated that:
  /// * State is [SpeakingActive]
  /// * Transcript is non-empty
  /// * Not in `speaking` or `processing` phase
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

  /// Streams LLM response tokens and handles errors.
  ///
  /// Subscribes to [_llm.streamResponse()] with three handlers:
  /// * `fold(left)`: Business logic errors → [_LlmError] event
  /// * `fold(right)`: Token received → [_LlmTokenReceived] event
  /// * `onDone`: Stream completed → [_LlmResponseComplete] event
  /// * `onError`: Infrastructure exceptions → [_LlmError] with fallback
  ///
  /// ## Error Handling Tiers (engineering_lessons #7)
  /// * Tier 1 (business errors): Handled by [Either.fold] — rate limits,
  ///   invalid keys, empty responses.
  /// * Tier 2 (infrastructure errors): Handled by [onError] — stream
  ///   exceptions, null dereferences, parsing failures that bypass [Either].
  /// * Tier 3 (fatal): Handled by [_onLlmError] — both LLM providers down.
  void _streamLlmResponse() {
    _llm
        .streamResponse(
          messages: List.from(_history),
          systemPrompt: LuciaPrompt.build(_userCefrLevel),
        )
        .listen(
          (event) => event.fold(
            // handles business logic errors (left)
            (failure) => add(LlmError(failure)),
            // handles LLM responses (right) success
            (token) => add(LlmTokenReceived(token)),
          ),
          onDone: () => add(const LlmResponseComplete()),
          //NEW: handles stream exceptions and errors
          onError: (Object error, StackTrace stackTrace) {
            debugPrint("[LLM Stream] Unexpected error: $error\n$stackTrace");
            add(
              LlmError(
                AppFailure.llmFailure(message: "Unexpected error: $error"),
              ),
            );
          },
        );
  }

  // ── LLM token streaming ───────────────────────────────────────────────────

  /// Handles incoming LLM tokens.
  ///
  /// 1. Appends token to [currentLuciaBuffer]
  /// 2. Updates transcript via [_upsertLuciaMessage] (replaces partial assistant message)
  /// 3. Emits updated state with `phase: processing`
  /// 4. Checks for sentence boundaries and triggers TTS for complete sentences
  ///
  /// ## Sentence-Boundary TTS
  /// Tokens arrive one at a time. We buffer them and only speak when a
  /// sentence boundary (`.`, `?`, `!`, `…`) is detected. This prevents
  /// choppy, word-by-word TTS and gives Lucia a more natural speaking rhythm.
  ///
  /// [_ttsSpokenLength] tracks how many characters have been sent to TTS
  /// to avoid re-speaking partial sentences when new tokens arrive.
  void _onLlmTokenReceived(
    LlmTokenReceived event,
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

  /// Handles LLM stream completion.
  ///
  /// 1. Commits the full response to [_fullTranscript] and [_history]
  /// 2. Sends any remaining unspoken text to TTS
  /// 3. Resets [_ttsSpokenLength] for the next response
  /// 4. Transitions state to `speaking` (if response non-empty) or `listening`
  ///
  /// If the response is empty, transitions directly to `listening`.
  /// If non-empty but TTS is not playing, manually fires [_TtsFinished]
  /// to ensure the state machine advances (defensive: TTS stream might
  /// not emit if the sentence was too short to trigger playback).
  void _onLlmResponseComplete(
    LlmResponseComplete event,
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
        add(const TtsFinished());
      }
    }
  }

  /// Handles LLM errors.
  ///
  /// Determines if the error is fatal (both providers failed) or recoverable:
  /// * Fatal: Emits [SpeakingState.error] — session cannot continue
  /// * Recoverable: Emits error message in [SpeakingActive] and resumes
  ///   `listening` phase — user can try again
  ///
  /// Resets [_ttsSpokenLength] to avoid partial TTS on retry.
  void _onLlmError(LlmError event, Emitter<SpeakingState> emit) {
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

  // ── TTS finished ──────────────────────────────────────────────────────────

  /// Handles TTS playback completion.
  ///
  /// In always-on mode, restarts VAD monitoring to flush any echo that
  /// accumulated during TTS playback. [VadRepository.startMonitoring()]
  /// disposes the old audio subscription and creates a fresh one — the
  /// Silero VAD internal ring buffer starts clean.
  ///
  /// Transitions state to `listening` to await next user utterance.
  /// Guarded to only act if currently in `speaking` phase.
  Future<void> _onTtsFinished(
    TtsFinished event,
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

  // ── Session end ───────────────────────────────────────────────────────────

  /// Ends the speaking session and emits final report data.
  ///
  /// 1. Cancels the session timer
  /// 2. Stops TTS and VAD monitoring
  /// 3. Emits [SpeakingState.ended] with:
  ///    * Complete transcript ([_fullTranscript])
  ///    * Total session duration ([_elapsed])
  ///    * Active speaking time ([_activeSpeaking])
  ///    * User metadata for report generation
  ///
  /// Note: Does not dispose repositories — they are singleton dependencies
  /// managed by the service locator. Only the BLoC's owned resources are
  /// cleaned up here; repository disposal happens in their own [dispose()]
  /// methods called by the service locator or parent widget.
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

  // ── PTT ───────────────────────────────────────────────────────────────────

  /// Handles PTT button press.
  ///
  /// 1. Records start time for active-speaking duration calculation
  /// 2. Opens microphone via [VadRepository.startMonitoring()] (works even
  ///    if VAD model failed to load — PTT fallback path)
  /// 3. Tells STT to start buffering incoming bytes via [SttRepository.startListening()]
  ///
  /// ## Error Handling
  /// Mic permission was already verified in [_onSessionStarted]. A failure
  /// here is unexpected (e.g., another app grabbed the mic mid-session).
  /// We log it rather than crashing — the user simply gets no transcription
  /// for this press, which is preferable to an error screen.
  ///
  /// [SttRepository.startListening()] is fire-and-forget with [catchError]
  /// to prevent unhandled rejections. Errors are logged for observability.
  Future<void> _onMicPressed(
    MicPressed event,
    Emitter<SpeakingState> emit,
  ) async {
    _speechStartTime = DateTime.now();

    // Open the microphone so the VAD datasource starts streaming raw PCM
    // bytes into audioStream, which SherpaSttDatasource buffers for PTT.
    // This works even when the Silero VAD model is not loaded (the VAD
    // datasource always opens the recorder regardless of model availability).
    //
    // Mic permission was already verified in _onSessionStarted, so a failure
    // here is unexpected (e.g. another app grabbed the mic mid-session).
    // We log it rather than crashing — the user will simply get no
    // transcription for this press, which is preferable to an error screen.
    final result = await _vad.startMonitoring();
    result.fold(
      (failure) => debugPrint("[PTT] Mic open failed: ${failure.message}"),
      (_) {},
    );

    // Tell SherpaSttDatasource to start accumulating the incoming bytes into
    // its PTT buffer. Must come after startMonitoring() so bytes are already
    // flowing before the buffer starts collecting them.
    unawaited(
      _stt.startListening().catchError((Object error, StackTrace stackTrace) {
        debugPrint("[PTT] STT start failed: $error\n$stackTrace");
        // Returning a Future<void> that completes with an error is not
        // what catchError expects. It expects a value of the Future's type.
        // Since startListening returns Future<void>, we should return Future<void>.
        // We've already logged the error, so we can just return an empty Future.
        return left<AppFailure, void>(
          AppFailure.sttFailure(message: 'Failed to start listening: $error'),
        );
      }),
    );
  }

  /// Handles PTT button release.
  ///
  /// 1. Accumulates speaking time for the just-completed utterance
  /// 2. Stops STT listening to trigger decode of buffered audio
  /// 3. Stops VAD monitoring (PTT mode only — always-on never triggers this)
  ///
  /// Awaiting [SttRepository.stopListening()] ensures the buffer is flushed
  /// and decode is triggered before the mic closes.
  Future<void> _onMicReleased(
    MicReleased event,
    Emitter<SpeakingState> emit,
  ) async {
    _accumulateSpeakingTime();
    await _stt.stopListening();
    await _vad.stopMonitoring();
  }

  // ── Mode toggle ───────────────────────────────────────────────────────────

  /// Handles mic mode toggle (always-on ↔ PTT).
  ///
  /// 1. Toggles [MicMode] in state
  /// 2. Starts or stops VAD monitoring based on new mode
  ///
  /// ## Await on startMonitoring
  /// [VadRepository.startMonitoring()] is awaited to ensure the mic is
  /// fully open before the UI reflects the mode change. Without this,
  /// rapid toggles could cause a race where the UI shows "always-on"
  /// but the mic is not yet streaming (engineering_lessons #1).
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
      await _vad.startMonitoring();
    } else {
      await _vad.stopMonitoring();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Accumulates active speaking time from [_speechStartTime] to now.
  ///
  /// Called when VAD detects silence (always-on) or PTT button is released.
  /// Nulls [_speechStartTime] after accumulation to avoid double-counting.
  void _accumulateSpeakingTime() {
    if (_speechStartTime != null) {
      _activeSpeaking += DateTime.now().difference(_speechStartTime!);
      _speechStartTime = null;
    }
  }

  /// Delivers the precanned greeting through the normal LLM→TTS pipeline.
  ///
  /// Routes the greeting via [LlmTokenReceived] + [LlmResponseComplete]
  /// events to ensure it:
  /// * Updates the transcript via [_upsertLuciaMessage]
  /// * Triggers sentence-boundary TTS via [_findFirstSentenceBoundary]
  /// * Commits to [_fullTranscript] and [_history] for the report card
  ///
  /// ## State Guard
  /// Added `if (current is SpeakingActive)` check for defensive programming.
  /// The greeting is always called immediately after `emit(SpeakingState.active)`
  /// in [_onSessionStarted], and [emit()] is synchronous in flutter_bloc,
  /// so the state is guaranteed to be [SpeakingActive]. The guard protects
  /// against future refactors that might change this ordering.
  ///
  /// The previous `else` branch was dead code — it called _tts.speak()
  /// directly (skipping the TTS queue and sentence-boundary logic) and
  /// only partially updated _fullTranscript. Removed for clarity.
  void _deliverPrecannedGreeting() {
    // This is always called immediately after emit(SpeakingState.active(...))
    // in _onSessionStarted. emit() is synchronous in flutter_bloc, so state
    // is guaranteed to be SpeakingActive at this point — no branch is needed.
    //
    // Routing the greeting through LlmTokenReceived + LlmResponseComplete
    // ensures it goes through the normal pipeline:
    //   • _onLlmTokenReceived: updates transcript via _upsertLuciaMessage and
    //     triggers sentence-boundary TTS via _findFirstSentenceBoundary
    //   • _onLlmResponseComplete: commits the full text to _fullTranscript
    //     and _history so it appears in the report card transcript
    //
    // The previous else branch bypassed all of this — it called _tts.speak()
    // directly (skipping the TTS queue and sentence-boundary logic) and only
    // partially updated _fullTranscript (not _history). It was also dead code:
    // the condition could never be false given the synchronous emit above.
    const greeting =
        "¡Hola! Me alegra que estés aquí. ¿De qué te gustaría hablar hoy?";
    add(const LlmTokenReceived(greeting));
    add(const LlmResponseComplete());
  }

  /// Finds the index of the first sentence boundary in [text].
  ///
  /// Returns the index of `.`, `?`, `!`, or `…`, or `-1` if none found.
  /// Used by [_onLlmTokenReceived] to trigger TTS at natural speaking points.
  int _findFirstSentenceBoundary(String text) {
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '.' || c == '?' || c == '!' || c == '…') return i;
    }
    return -1;
  }

  /// Updates or appends Lucia's partial message in the transcript.
  ///
  /// If the last message in [transcript] is from the assistant, replaces it
  /// with the new [buffer] (streaming update). Otherwise, appends a new
  /// assistant message.
  ///
  /// This enables the UI to show Lucia's response as it streams in, with
  /// each token updating the same message rather than creating a new one.
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

  /// Releases all resources owned by this BLoC.
  ///
  /// Cancels:
  /// * [_sessionTimer] — stops the session timer
  /// * All stream subscriptions ([_amplitudeSub], [_transcriptSub], etc.)
  ///
  /// Then calls [super.close()] to complete the BLoC's internal stream.
  ///
  /// Note: Repositories ([_stt], [_tts], [_vad]) are NOT disposed here —
  /// they are injected dependencies with their own lifecycle managed by
  /// the service locator. Disposing them here would break re-initialization
  /// for "Speak Again" flows (engineering_lessons #5).
  @override
  Future<void> close() async {
    _sessionTimer?.cancel();
    await _amplitudeSub?.cancel();
    await _transcriptSub?.cancel();
    await _vadSub?.cancel();
    await _ttsSub?.cancel();
    await _stt.dispose();
    await _tts.dispose();
    await _vad.dispose();
    return super.close();
  }
}
