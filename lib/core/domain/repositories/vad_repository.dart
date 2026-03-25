// lib/core/domain/repositories/vad_repository.dart
//
// Contract for voice activity detection.
// Sprint 2 implementation: SherpaVadRepository (sherpa-onnx Silero VAD, on-device)
//
// VAD is only used in always-on mode. In push-to-talk mode the BLoC
// bypasses VAD entirely — mic recording starts on button press, stops
// on button release.

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";

abstract interface class VadRepository {
  /// Initializes the VAD model.
  /// A VAD initialization failure is treated as non-fatal by SpeakingBloc —
  /// the session falls back to push-to-talk mode.
  Future<Either<AppFailure, void>> initialize();

  /// Begins monitoring the microphone for voice activity.
  Future<Either<AppFailure, void>> startMonitoring();

  /// Stops monitoring.
  Future<void> stopMonitoring();

  /// Emits [true] when speech is detected, [false] when silence is detected.
  /// The implementation debounces silence to avoid cutting off mid-sentence
  /// (configured silence threshold: ~500ms).
  Stream<bool> get voiceActivityStream;

  /// Releases all resources.
  Future<void> dispose();
}
