// lib/core/domain/repositories/stt_repository.dart

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";

abstract class SttRepository {
  Future<Either<AppFailure, bool>> initialize();

  /// Partial results — emits continuously while the user is speaking.
  /// Use to update the live user transcript bubble in the UI.
  Stream<String> get transcriptStream;

  /// Final results — emits exactly once per utterance, after the configured
  /// silence threshold (pauseFor). Use this to trigger the LLM call in
  /// always-on mode instead of relying on the VAD.
  Stream<String> get finalTranscriptStream;

  Future<Either<AppFailure, void>> startListening();
  Future<Either<AppFailure, String>> stopListening();

  bool get isListening;
  Future<void> dispose();
}
