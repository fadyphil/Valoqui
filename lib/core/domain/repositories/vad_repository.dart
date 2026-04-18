// lib/core/domain/repositories/vad_repository.dart
//
// Contract for voice activity detection.
// Sprint 2 implementation: SherpaVadRepository (sherpa-onnx Silero VAD, on-device)
//
// VAD is only used in always-on mode. In push-to-talk mode the BLoC
// bypasses VAD entirely — mic recording starts on button press, stops
// on button release.

import "dart:typed_data";

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

  /// Emits [true] then [false] for each completed speech segment.
  /// Used by the bloc for active-speaking-time tracking only.
  ///
  /// NOTE: sherpa-onnx Silero VAD is segment-based — a segment becomes
  /// available only after silence follows speech. Both events are emitted
  /// back-to-back once per utterance, not in real time. For actual STT
  /// decoding, listen to [speechSegmentStream] which carries the segment
  /// samples directly.
  Stream<bool> get voiceActivityStream;

  /// Emits the Float32 samples of each completed speech segment.
  /// This is the primary trigger for always-on STT decoding.
  /// SherpaSttDatasource subscribes here and bypasses the PCM buffer.
  Stream<Float32List> get speechSegmentStream;

  Stream<Uint8List> get audioStream;

  /// Releases all resources.
  Future<void> dispose();
}
