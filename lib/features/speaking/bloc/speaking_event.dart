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
class TimerTick extends SpeakingEvent {
  final Duration elapsed;
  const TimerTick(this.elapsed);
  @override
  List<Object?> get props => [elapsed];
}

/// VAD detected voice activity change.
class VoiceActivityChanged extends SpeakingEvent {
  final bool isActive;
  const VoiceActivityChanged({required this.isActive});
  @override
  List<Object?> get props => [isActive];
}

/// STT emitted a (partial or final) transcript.
class TranscriptReceived extends SpeakingEvent {
  final String text;
  const TranscriptReceived(this.text);
  @override
  List<Object?> get props => [text];
}

class PartialTranscriptReceived extends SpeakingEvent {
  final String text;
  const PartialTranscriptReceived(this.text);
  @override
  List<Object?> get props => [text];
}

/// LLM streamed a new token.
class LlmTokenReceived extends SpeakingEvent {
  final String token;
  const LlmTokenReceived(this.token);
  @override
  List<Object?> get props => [token];
}

/// LLM finished streaming its full response.
class LlmResponseComplete extends SpeakingEvent {
  const LlmResponseComplete();
}

/// LLM encountered an error.
class LlmError extends SpeakingEvent {
  final AppFailure failure;
  const LlmError(this.failure);
  @override
  List<Object?> get props => [failure];
}

/// TTS finished playing — transition back to listening.
class TtsFinished extends SpeakingEvent {
  const TtsFinished();
}

/// TTS began playing — gate the VAD so TTS audio can't reach Silero.
class TtsStarted extends SpeakingEvent {
  const TtsStarted();
}

/// Mic amplitude updated — dispatched by the amplitude stream subscription.
/// This is a proper event so emit() is only ever called inside a handler,
/// satisfying flutter_bloc's constraint that emit must not be called from
/// outside an event handler.
class AmplitudeChanged extends SpeakingEvent {
  final double amplitude;
  const AmplitudeChanged(this.amplitude);
  @override
  List<Object?> get props => [amplitude];
}

class BufferFillChanged extends SpeakingEvent {
  final double percent;
  const BufferFillChanged(this.percent);
  @override
  List<Object?> get props => [percent];
}

/// Internal update event for token batching.
class _UpdateBatchUi extends SpeakingEvent {
  final List<ConversationMessage> transcript;
  final String buffer;
  const _UpdateBatchUi(this.transcript, this.buffer);
  @override
  List<Object?> get props => [transcript, buffer];
}
