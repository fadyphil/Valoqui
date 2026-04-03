// lib/core/data/datasources/android_stt_datasource.dart

import "dart:async";
import "package:flutter/foundation.dart";
import "package:fpdart/fpdart.dart";
import "package:speech_to_text/speech_recognition_result.dart";
import "package:speech_to_text/speech_to_text.dart";
import "package:valoqui/core/domain/models/app_failure.dart";

@Deprecated(
  'Migrating to offline Sherpa-ONNX unified pipeline to fix Android OS cutoffs. '
  'Use SherpaSttDatasource instead. (ARCH-101)',
)
class AndroidSttDatasource {
  /// Pass the required [SpeechToText] class/instance here to have clean dependency injection.
  AndroidSttDatasource({required SpeechToText stt}) : _stt = stt;

  final SpeechToText _stt;

  // Partial results → live UI display (user bubble updates while speaking)
  final StreamController<String> _partialController =
      StreamController<String>.broadcast();

  // Final results → utterance processing (triggers LLM call in always-on mode)
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

  /// Start listening.
  ///
  /// [alwaysOnMode] controls the silence-detection window:
  ///   - true  (always-on): pauseFor = 2s — silence ends the utterance and
  ///     fires a final result, which the BLoC uses to trigger the LLM call.
  ///   - false (push-to-talk): pauseFor = 60s — silence does NOT end the
  ///     session; the button release calls stopListening() explicitly.
  ///     listenFor is extended to 5 minutes for long PTT inputs.
  Future<Either<AppFailure, void>> startListening({
    bool alwaysOnMode = true,
  }) async {
    if (!_initialized) return left(const AppFailure.sttNotAvailable());
    if (_stt.isListening) return right(null); // guard against double-start

    try {
      await _stt.listen(
        localeId: "es-ES",
        onResult: (SpeechRecognitionResult result) {
          if (result.recognizedWords.isEmpty) return;

          // Always emit partial so the user bubble updates live
          _partialController.add(result.recognizedWords);

          // Emit final only when STT confirms the utterance is done.
          // BLoC uses this to fire the LLM call in always-on mode.
          if (result.finalResult) {
            _finalController.add(result.recognizedWords);
          }
        },
        // PTT: long timeout — button release, not silence, ends recording.
        // Always-on: short timeout — silence is the natural utterance boundary.
        listenFor: alwaysOnMode
            ? const Duration(seconds: 30)
            : const Duration(minutes: 5),
        pauseFor: alwaysOnMode
            ? const Duration(seconds: 2)
            : const Duration(seconds: 60),
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

