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
class _VoiceActivityChanged extends SpeakingEvent {
  final bool isActive;
  const _VoiceActivityChanged({required this.isActive});
  @override
  List<Object?> get props => [isActive];
}

/// STT emitted a (partial or final) transcript.
class _TranscriptReceived extends SpeakingEvent {
  final String text;
  const _TranscriptReceived(this.text);
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

/// TTS finished playing — transition back to listening.
class _TtsFinished extends SpeakingEvent {
  const _TtsFinished();
}

/// TTS began playing — gate the VAD so TTS audio can't reach Silero.
class _TtsStarted extends SpeakingEvent {
  const _TtsStarted();
}

/// Mic amplitude updated — dispatched by the amplitude stream subscription.
/// This is a proper event so emit() is only ever called inside a handler,
/// satisfying flutter_bloc's constraint that emit must not be called from
/// outside an event handler.
class _AmplitudeChanged extends SpeakingEvent {
  final double amplitude;
  const _AmplitudeChanged(this.amplitude);
  @override
  List<Object?> get props => [amplitude];
}
