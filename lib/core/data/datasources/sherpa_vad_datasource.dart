// lib/core/data/datasources/sherpa_vad_datasource.dart
//
// On-device Voice Activity Detection using sherpa-onnx Silero VAD.
// Monitors the microphone continuously and emits bool events:
//   true  = speech detected
//   false = silence detected (after ~500ms threshold)
//
// Used only in always-on mode. Push-to-talk bypasses this entirely.
// A VAD initialization failure is non-fatal — SpeakingBloc falls back
// to push-to-talk mode and the session continues normally.
//
// NOTE: Silero VAD requires 16kHz mono audio input.

import "dart:async";
import "dart:typed_data";
import "package:flutter/foundation.dart";
import "package:fpdart/fpdart.dart";
import "package:record/record.dart";
import "package:sherpa_onnx/sherpa_onnx.dart" as sherpa;
import "package:valoqui/core/domain/models/app_failure.dart";

class SherpaVadDatasource {
  sherpa.VoiceActivityDetector? _vad;
  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<bool> _vadController =
      StreamController<bool>.broadcast();

  StreamSubscription<dynamic>? _audioSub;
  bool _initialized = false;
  bool _isSpeaking = false;

  // Silence counter — how many consecutive silent frames before
  // we emit a "silence detected" event. At 10ms frames, 50 frames = 500ms.
  static const int _silenceThresholdFrames = 50;
  int _silentFrameCount = 0;

  Stream<bool> get voiceActivityStream => _vadController.stream;

  Future<Either<AppFailure, void>> initialize() async {
    try {
      final vadConfig = sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          // The silero VAD model is bundled with the sherpa_onnx package.
          // No additional asset download is required.
          model: "",
          threshold: 0.5,
          minSilenceDuration: 0.5,
          minSpeechDuration: 0.25,
          windowSize: 512,
        ),
        sampleRate: 16000,
        numThreads: 1,
        debug: false,
        provider: "cpu",
      );

      _vad = sherpa.VoiceActivityDetector(
        config: vadConfig,
        bufferSizeInSeconds: 30,
      );

      _initialized = true;
      return right(null);
    } catch (e) {
      debugPrint("[VAD] Init failed: $e — session will use push-to-talk");
      return left(AppFailure.networkFailure(message: "VAD init failed: $e"));
    }
  }

  Future<Either<AppFailure, void>> startMonitoring() async {
    if (!_initialized || _vad == null) {
      return left(const AppFailure.sttNotAvailable());
    }

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        return left(const AppFailure.sttPermissionDenied());
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _audioSub = stream.listen((chunk) {
        if (_vad == null) return;
        final floatSamples = _convertPcm16ToFloat32(chunk);

        // Accept raw PCM bytes
        _vad!.acceptWaveform(floatSamples);

        while (!_vad!.isEmpty()) {
          final segment = _vad!.front();
          final speechDetected = segment.samples.isNotEmpty;

          if (speechDetected) {
            _silentFrameCount = 0;
            if (!_isSpeaking) {
              _isSpeaking = true;
              if (!_vadController.isClosed) _vadController.add(true);
            }
          } else {
            _silentFrameCount++;
            if (_isSpeaking && _silentFrameCount >= _silenceThresholdFrames) {
              _isSpeaking = false;
              _silentFrameCount = 0;
              if (!_vadController.isClosed) _vadController.add(false);
            }
          }

          _vad!.pop();
        }
      });

      return right(null);
    } catch (e) {
      return left(
        AppFailure.networkFailure(message: "VAD monitoring failed: $e"),
      );
    }
  }

  // ... (top of your file remains exactly the same)

  Future<void> stopMonitoring() async {
    await _audioSub?.cancel();
    _audioSub = null;

    try {
      // Only attempt to stop if it is currently recording
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (e) {
      debugPrint("[VAD] Safely ignored error stopping recorder: $e");
    }

    _isSpeaking = false;
    _silentFrameCount = 0;
  }

  Future<void> dispose() async {
    await stopMonitoring();

    try {
      await _recorder.dispose();
    } catch (e) {
      debugPrint("[VAD] Safely ignored error disposing recorder: $e");
    }

    // Ensure the stream controller is closed even if the recorder throws an error
    if (!_vadController.isClosed) {
      await _vadController.close();
    }
  }

  /// Converts raw 16-bit PCM bytes (Uint8List) into normalized Float32 samples.
  Float32List _convertPcm16ToFloat32(Uint8List pcmBytes) {
    // Create an Int16 view directly over the byte buffer for performance
    final int16List = Int16List.view(
      pcmBytes.buffer,
      pcmBytes.offsetInBytes,
      pcmBytes.length ~/ 2, // 2 bytes per 16-bit sample
    );

    final float32List = Float32List(int16List.length);

    // Normalize each sample from [-32768, 32767] to [-1.0, 1.0]
    for (int i = 0; i < int16List.length; i++) {
      float32List[i] = int16List[i] / 32768.0;
    }

    return float32List;
  }
}
