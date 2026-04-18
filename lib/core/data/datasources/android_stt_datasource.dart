// lib/core/data/datasources/android_stt_datasource.dart
//
// Sprint 2 implementation — Android SpeechRecognizer via speech_to_text.
// NOTE (ARCH-101): This datasource has a hard ~7-second OS ceiling on PTT
// sessions and a mic-conflict with always-on VAD. It is a Sprint 2 stand-in.
// Sprint 3 replaces it with GroqSttDatasource (record + Groq Whisper).
// Swap: one new file + one line in service_locator.dart.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:valoqui/core/domain/models/app_failure.dart';

class AndroidSttDatasource {
  final SpeechToText _stt = SpeechToText();

  final _transcriptController = StreamController<String>.broadcast();
  final _amplitudeController = StreamController<double>.broadcast();

  bool _initialized = false;

  // ── Public streams ─────────────────────────────────────────────────────────

  Stream<String> get transcriptStream => _transcriptController.stream;

  /// Normalized 0.0–1.0 amplitude.
  /// speech_to_text onSoundLevelChange reports ~0–10 on Android.
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  bool get isListening => _stt.isListening;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<Either<AppFailure, bool>> initialize() async {
    try {
      _initialized = await _stt.initialize(
        onError: (error) {
          debugPrint('[STT] Error: ${error.errorMsg}');
        },
      );
      return right(_initialized);
    } on Exception catch (e) {
      return left(AppFailure.sttFailure(message: 'STT init failed: $e'));
    }
  }

  Future<Either<AppFailure, void>> startListening() async {
    if (!_initialized) {
      return left(const AppFailure.sttNotAvailable());
    }
    try {
      await _stt.listen(
        onResult: (SpeechRecognitionResult result) {
          if (result.recognizedWords.isNotEmpty) {
            _transcriptController.add(result.recognizedWords);
          }
        },
        onSoundLevelChange: (double level) {
          // level is roughly 0–10 on Android; clamp and normalize to 0.0–1.0
          final normalized = (level / 10.0).clamp(0.0, 1.0);
          if (!_amplitudeController.isClosed) {
            _amplitudeController.add(normalized);
          }
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        // Do NOT set localeId — auto-detection handles Spanish + English.
        // Setting 'es_ES' breaks English input entirely.
      );
      return right(null);
    } on Exception catch (e) {
      return left(
        AppFailure.sttFailure(message: 'Failed to start listening: $e'),
      );
    }
  }

  Future<Either<AppFailure, String>> stopListening() async {
    try {
      await _stt.stop();
      // Decay amplitude to zero when not listening
      if (!_amplitudeController.isClosed) {
        _amplitudeController.add(0.0);
      }
      return right(_stt.lastRecognizedWords);
    } on Exception catch (e) {
      return left(
        AppFailure.sttFailure(message: 'Failed to stop listening: $e'),
      );
    }
  }

  Future<void> dispose() async {
    await _stt.cancel();
    await _transcriptController.close();
    await _amplitudeController.close();
  }
}
