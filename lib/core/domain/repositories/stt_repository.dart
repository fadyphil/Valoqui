// lib/core/domain/repositories/stt_repository.dart

import 'package:fpdart/fpdart.dart';
import 'package:valoqui/core/domain/models/app_failure.dart';

abstract class SttRepository {
  /// Check STT availability and request microphone permission.
  Future<Either<AppFailure, bool>> initialize();

  /// Emits partial + final transcription text as the user speaks.
  Stream<String> get transcriptStream;

  /// Normalized 0.0–1.0 mic amplitude, emitted continuously while listening.
  /// Consumers (e.g. SpeakingWaveform) use this to drive visual intensity.
  Stream<double> get amplitudeStream;

  /// Start a listening session.
  Future<Either<AppFailure, void>> startListening();

  /// Stop listening and return the final transcription.
  Future<Either<AppFailure, String>> stopListening();

  /// Whether the STT engine is currently listening.
  bool get isListening;

  /// Release all resources.
  Future<void> dispose();
}
