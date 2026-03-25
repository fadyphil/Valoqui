// lib/core/data/datasources/android_stt_datasource.dart
//
// Two key fixes vs v1:
//   1. localeId: 'es-ES' — without this the device uses its default language
//      (English/Arabic) and Spanish is never recognized.
//   2. Separate finalTranscriptStream — emits only when result.finalResult==true.
//      The BLoC uses this to trigger LLM calls in always-on mode, removing
//      the dependency on sherpa VAD (which was fighting the SpeechRecognizer
//      for the microphone and causing empty transcripts).

import "dart:async";
import "package:flutter/foundation.dart";
import "package:fpdart/fpdart.dart";
import "package:speech_to_text/speech_recognition_result.dart";
import "package:speech_to_text/speech_to_text.dart";
import "package:valoqui/core/domain/models/app_failure.dart";

class AndroidSttDatasource {
  final SpeechToText _stt = SpeechToText();

  // Partial results → live UI display (user bubble updates while speaking)
  final StreamController<String> _partialController =
      StreamController<String>.broadcast();

  // Final results → utterance processing (triggers LLM call in always-on mode)
  // Fires only once per utterance, after pauseFor silence threshold.
  final StreamController<String> _finalController =
      StreamController<String>.broadcast();

  bool _initialized = false;

  Stream<String> get transcriptStream => _partialController.stream;
  Stream<String> get finalTranscriptStream => _finalController.stream;
  bool get isListening => _stt.isListening;

  Future<Either<AppFailure, bool>> initialize() async {
    try {
      _initialized = await _stt.initialize(
        onError: (error) {
          debugPrint(
            "[STT] Error: ${error.errorMsg} (permanent: ${error.permanent})",
          );
        },
        debugLogging: kDebugMode,
      );

      if (!_initialized) return left(const AppFailure.sttNotAvailable());
      return right(_initialized);
    } catch (e) {
      return left(AppFailure.sttFailure(message: "STT init failed: $e"));
    }
  }

  Future<Either<AppFailure, void>> startListening() async {
    if (!_initialized) return left(const AppFailure.sttNotAvailable());
    if (_stt.isListening) return right(null); // guard against double-start

    try {
      await _stt.listen(
        // FIX 1: Set es-ES so the Google Spanish recognition model is used.
        // The Spanish model handles common English/Arabic words mixed in —
        // acceptable trade-off for a Spanish learning app.
        localeId: "es-ES",
        onResult: (SpeechRecognitionResult result) {
          if (result.recognizedWords.isEmpty) return;

          // Always emit partial so the user bubble updates live
          _partialController.add(result.recognizedWords);

          // FIX 2: Only emit to finalController when STT is actually done.
          // This is the signal the BLoC uses to fire the LLM call.
          if (result.finalResult) {
            _finalController.add(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        // 2 seconds of silence → fires final result → BLoC processes utterance
        pauseFor: const Duration(seconds: 2),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
      );

      return right(null);
    } catch (e) {
      return left(AppFailure.sttFailure(message: "Failed to start STT: $e"));
    }
  }

  Future<Either<AppFailure, String>> stopListening() async {
    try {
      await _stt.stop();
      return right(_stt.lastRecognizedWords);
    } catch (e) {
      return left(AppFailure.sttFailure(message: "Failed to stop STT: $e"));
    }
  }

  Future<void> dispose() async {
    await _stt.cancel();
    await _partialController.close();
    await _finalController.close();
  }
}
