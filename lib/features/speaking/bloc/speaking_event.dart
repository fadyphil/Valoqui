// lib/features/speaking/bloc/speaking_event.dart
part of "speaking_bloc.dart";

abstract class SpeakingEvent extends Equatable {
  const SpeakingEvent();
  @override
  List<Object?> get props => [];
}

// ── Public events (dispatched from the UI) ─────────────────────────────

class SessionStarted extends SpeakingEvent {
  final String userCefrLevel;
  final String userId;
  const SessionStarted({required this.userCefrLevel, required this.userId});
  @override
  List<Object?> get props => [userCefrLevel, userId];
}

class SessionEnded extends SpeakingEvent {
  const SessionEnded();
}

/// Push-to-talk: button held down
class MicPressed extends SpeakingEvent {
  const MicPressed();
}

/// Push-to-talk: button released
class MicReleased extends SpeakingEvent {
  const MicReleased();
}

class MicModeToggled extends SpeakingEvent {
  const MicModeToggled();
}

// ── Internal events (dispatched by the BLoC itself) ────────────────────

/// Drives the session timer — dispatched by Timer.periodic every second.
class _TimerTick extends SpeakingEvent {
  final Duration elapsed;
  const _TimerTick(this.elapsed);
  @override
  List<Object?> get props => [elapsed];
}

/// VAD detected voice activity change.
/// Still used for active-speaking-time tracking even though
/// we no longer use it to trigger utterance processing.
class _VoiceActivityChanged extends SpeakingEvent {
  final bool isActive;
  const _VoiceActivityChanged(this.isActive);
  @override
  List<Object?> get props => [isActive];
}

/// STT emitted a partial transcript (live display only).
class _TranscriptReceived extends SpeakingEvent {
  final String text;
  const _TranscriptReceived(this.text);
  @override
  List<Object?> get props => [text];
}

/// STT emitted a FINAL transcript — this is the signal to fire the LLM.
/// Replaces VAD-based silence detection for always-on mode, removing
/// the mic conflict between sherpa VAD recorder and SpeechRecognizer.
class _FinalTranscriptReceived extends SpeakingEvent {
  final String text;
  const _FinalTranscriptReceived(this.text);
  @override
  List<Object?> get props => [text];
}

/// LLM streamed a new token.
class _LlmTokenReceived extends SpeakingEvent {
  final String token;
  const _LlmTokenReceived(this.token);
  @override
  List<Object?> get props => [token];
}

/// LLM finished streaming its full response.
class _LlmResponseComplete extends SpeakingEvent {
  const _LlmResponseComplete();
}

/// LLM encountered an error.
class _LlmError extends SpeakingEvent {
  final AppFailure failure;
  const _LlmError(this.failure);
  @override
  List<Object?> get props => [failure];
}

/// TTS finished playing — transition back to listening and restart STT.
/// Replaces the direct _resumeListening() call so we can emit a state
/// change (phase → listening) from inside a proper BLoC handler.
class _TtsFinished extends SpeakingEvent {
  const _TtsFinished();
}
