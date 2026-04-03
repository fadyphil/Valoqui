// lib/core/data/datasources/sherpa_vad_datasource.dart
//
// FIX (always-on transcription): sherpa-onnx Silero VAD is segment-based,
// not frame-based. isEmpty() returns false only AFTER silence follows speech,
// at which point front() returns a completed SpeechSegment containing the
// full utterance audio in segment.samples.
//
// The previous implementation tried to correlate real-time audioStream bytes
// with VAD events, which fundamentally cannot work: by the time the VAD
// signals speech, the audio has already passed through the stream.
//
// Fix: expose speechSegmentStream (Float32List) so SherpaSttDatasource
// decodes the segment's own samples directly — no buffering mismatch.
//
// voiceActivityStream still emits true→false per utterance so the bloc
// can track active-speaking time.

import "dart:async";
import "dart:io";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart" show rootBundle;
import "package:fpdart/fpdart.dart";
import "package:path_provider/path_provider.dart";
import "package:record/record.dart";
import "package:sherpa_onnx/sherpa_onnx.dart" as sherpa;
import "package:valoqui/core/domain/models/app_failure.dart";

class SherpaVadDatasource {
  sherpa.VoiceActivityDetector? _vad;
  final AudioRecorder _recorder = AudioRecorder();

  // ── voiceActivityStream — true/false pair per utterance, for timing ──────
  final StreamController<bool> _vadController =
      StreamController<bool>.broadcast();
  Stream<bool> get voiceActivityStream => _vadController.stream;

  // ── speechSegmentStream — Float32 samples for direct STT decode ──────────
  final StreamController<Float32List> _segmentController =
      StreamController<Float32List>.broadcast();
  Stream<Float32List> get speechSegmentStream => _segmentController.stream;

  // ── audioStream — raw PCM bytes used only by PTT buffering ───────────────
  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  StreamSubscription<dynamic>? _audioSub;
  // bool _initialized = false;

  Future<Either<AppFailure, void>> initialize() async {
    try {
      final modelPath = await _copyAssetToLocal(
        "assets/models/silero_vad.onnx",
      );

      final vadConfig = sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          model: modelPath,
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

      // _initialized = true;
      debugPrint("[VAD] Silero VAD model loaded from $modelPath");
      return right(null);
    } catch (e) {
      debugPrint("[VAD] Init failed: $e — session will use push-to-talk");
      return left(AppFailure.networkFailure(message: "VAD init failed: $e"));
    }
  }

  Future<Either<AppFailure, void>> startMonitoring() async {
    // We do NOT gate on _initialized here.
    // PTT needs the mic open regardless of whether the VAD model loaded.
    // VAD segment processing below is skipped when _vad == null.

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        return left(const AppFailure.sttPermissionDenied());
      }

      if (await _recorder.isRecording()) return right(null);

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );

      _audioSub = stream.listen((chunk) {
        // Always broadcast raw bytes for PTT buffering.
        if (!_audioStreamController.isClosed) {
          _audioStreamController.add(chunk);
        }

        // Always-on VAD processing — skipped in PTT mode (_vad == null).
        if (_vad == null) return;
        _vad!.acceptWaveform(_convertPcm16ToFloat32(chunk));

        // sherpa-onnx VAD is segment-based:
        // isEmpty() is false only after a complete utterance (speech + silence).
        // front() returns a SpeechSegment whose .samples holds the full audio.
        // We emit the samples directly so STT can decode without buffering.
        while (!_vad!.isEmpty()) {
          final segment = _vad!.front();
          _vad!.pop();

          if (segment.samples.isEmpty) continue;

          // Emit the completed utterance samples for direct STT decoding.
          if (!_segmentController.isClosed) {
            _segmentController.add(segment.samples);
          }

          // Emit timing events so the bloc can track active-speaking time.
          if (!_vadController.isClosed) {
            _vadController.add(true); // speech was detected
            _vadController.add(false); // silence followed — utterance complete
          }

          debugPrint(
            "[VAD] Segment emitted — ${segment.samples.length} samples "
            "(${(segment.samples.length / 16000).toStringAsFixed(2)}s)",
          );
        }
      });

      return right(null);
    } catch (e) {
      return left(
        AppFailure.networkFailure(message: "VAD monitoring failed: $e"),
      );
    }
  }

  Future<void> stopMonitoring() async {
    await _audioSub?.cancel();
    _audioSub = null;

    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (e) {
      debugPrint("[VAD] Safely ignored error stopping recorder: $e");
    }
  }

  Future<void> dispose() async {
    await stopMonitoring();

    try {
      await _recorder.dispose();
    } catch (e) {
      debugPrint("[VAD] Safely ignored error disposing recorder: $e");
    }

    if (!_vadController.isClosed) await _vadController.close();
    if (!_segmentController.isClosed) await _segmentController.close();
    if (!_audioStreamController.isClosed) await _audioStreamController.close();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Float32List _convertPcm16ToFloat32(Uint8List pcmBytes) {
    // final int16List = Int16List.view(
    //   pcmBytes.buffer,
    //   pcmBytes.offsetInBytes,
    //   // pcmBytes.length ~/ 2,
    // );
    // final float32List = Float32List(int16List.length);
    // for (int i = 0; i < int16List.length; i++) {
    // float32List[i] = int16List[i] / 32768.0;
    // }
    final byteData = ByteData.view(
      pcmBytes.buffer,
      pcmBytes.offsetInBytes,
      pcmBytes.lengthInBytes,
    );
    final int numSamples = pcmBytes.lengthInBytes ~/ 2;
    final float32List = Float32List(numSamples);
    for (int i = 0; i < numSamples; i++) {
      float32List[i] = byteData.getInt16(i * 2, Endian.host) / 32768.0;
    }

    return float32List;
  }

  Future<String> _copyAssetToLocal(String assetPath) async {
    final docDir = await getApplicationDocumentsDirectory();
    final localPath = "${docDir.path}/$assetPath";
    final file = File(localPath);
    if (!await file.exists()) {
      await file.parent.create(recursive: true);
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
        flush: true,
      );
      debugPrint("[VAD] Copied $assetPath → $localPath");
    }
    return localPath;
  }
}
