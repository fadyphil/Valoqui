// lib/core/domain/repositories/tts_repository.dart
//
// Contract for text-to-speech.
// Sprint 2 implementation: SherpaTtsRepository (sherpa-onnx Piper, on-device)

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";

abstract interface class TtsRepository {
  /// Initializes the TTS engine.
  /// For sherpa-onnx: copies model files from assets to the filesystem
  /// on first launch (~76 MB, one-time). Subsequent launches skip the copy.
  /// Must be awaited before the first [speak] call.
  Future<Either<AppFailure, void>> initialize();

  /// Speaks the given text using the on-device TTS engine.
  /// If the engine is already speaking, stops first then starts the new text.
  Future<Either<AppFailure, void>> speak(String text);

  /// Stops any in-progress speech immediately.
  Future<void> stop();

  /// Whether the TTS engine is currently producing audio.
  bool get isSpeaking;

  /// Emits [true] when speech begins, [false] when it ends.
  /// SpeakingBloc listens to this to know when to resume the mic.
  Stream<bool> get speakingStateStream;

  /// Releases all resources.
  Future<void> dispose();
}
