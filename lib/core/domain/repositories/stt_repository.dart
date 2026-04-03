// lib/core/domain/repositories/stt_repository.dart

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";

abstract class SttRepository {
  Future<Either<AppFailure, void>> initialize();

  /// Emits final transcribed text once per utterance.
  Stream<String> get transcriptStream;

  /// PTT: start buffering audio. Call on mic press.
  void startListening();

  /// PTT: stop buffering and decode immediately. Call on mic release.
  void stopListening();

  Future<void> dispose();
}
