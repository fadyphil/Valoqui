// lib/features/speaking/bloc/speaking_state.dart

part of "speaking_bloc.dart";

/// The phase of the conversation at any given moment.
/// Drives all visual state in SpeakingScreen.
enum ConversationPhase {
  /// Mic is open, waiting for the user to speak.
  listening,

  /// STT is running or LLM is generating a response.
  processing,

  /// TTS is playing Lucia's reply. Mic is inactive.
  speaking,
}

/// Always-on: VAD detects speech automatically.
/// pushToTalk: user must hold the mic button.
enum MicMode { alwaysOn, pushToTalk }

@freezed
sealed class SpeakingState with _$SpeakingState {
  /// Before SessionStarted has been processed.
  const factory SpeakingState.initial() = SpeakingInitial;

  /// TTS model is being copied / initialized (first launch only).
  /// Show a loading indicator.
  const factory SpeakingState.initializing() = SpeakingInitializing;

  /// Active conversation loop.
  const factory SpeakingState.active({
    /// Full transcript displayed in the scroll view.
    required List<ConversationMessage> transcript,

    /// Current phase — drives mic button visual and waveform visibility.
    required ConversationPhase phase,

    /// Current mic input mode.
    required MicMode micMode,

    /// Session wall-clock time since SessionStarted.
    required Duration elapsed,

    /// Accumulated time the user spent actually speaking.
    required Duration activeSpeakingTime,

    /// Tokens currently accumulating for Lucia's current response.
    /// Cleared once the full response is committed to transcript.
    required String currentLuciaBuffer,

    /// STT partial result shown live in the user bubble while speaking.
    /// Null when the user is not speaking.
    String? partialUserTranscript,

    /// The current amplitude of the user's speech.
    @Default(0.0) double amplitude,

    /// Percentage of the STT buffer currently filled (0.0 to 1.0).
    /// Used for visual feedback in PTT mode.
    @Default(0.0) double bufferFillPercentage,

    /// Non-fatal error message shown as a toast (e.g. network hiccup).
    /// Null when there is no error.
    String? errorMessage,
  }) = SpeakingActive;

  /// Session is over. Carries all data needed by ReportBloc.
  /// Router reads this state and navigates to /report.
  const factory SpeakingState.ended({
    required List<ConversationMessage> transcript,
    required Duration totalDuration,
    required Duration activeSpeakingTime,
    required String userId,
    required String userCefrLevel,
  }) = SpeakingEnded;

  /// Fatal error — session cannot continue.
  const factory SpeakingState.error({required String message}) = SpeakingError;
}
