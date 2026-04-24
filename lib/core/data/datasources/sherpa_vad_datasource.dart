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

/// Voice Activity Detection datasource using sherpa-onnx Silero VAD.
///
/// This datasource exposes three streams for different consumption patterns:
/// * [voiceActivityStream] — Emits `false` when an utterance completes (for
///   active-speaking time tracking in the BLoC).
/// * [speechSegmentStream] — Emits [Float32List] audio samples for each
///   detected utterance, ready for direct STT decoding without buffering.
/// * [audioStream] — Raw PCM16 bytes for push-to-talk fallback buffering.
///
/// ## Segment-Based VAD Behavior
/// sherpa-onnx Silero VAD is segment-based, not frame-based. The [isEmpty()]
/// method returns `false` only AFTER silence follows speech, at which point
/// [front()] returns a completed [sherpa.SpeechSegment] containing the full
/// utterance audio in [sherpa.SpeechSegment.samples].
///
/// This means: by the time a segment is available, the speech has already
/// ended. We emit only the completion event (`false`) to avoid confusing
/// the BLoC's speaking-time accumulation with back-to-back `true`→`false`
/// events that have ~0ms duration.

class SherpaVadDatasource {
  sherpa.VoiceActivityDetector? _vad;
  final AudioRecorder _recorder = AudioRecorder();

  /// Broadcast stream emitting `false` when an utterance completes.
  ///
  /// Used by the BLoC to stop the active-speaking timer. Does not emit `true`
  /// on speech onset because sherpa-onnx detects segments post-hoc — the
  /// "start" event would fire after speech has already ended, making duration
  /// calculations inaccurate.

  // ── voiceActivityStream — true/false pair per utterance, for timing ──────
  final StreamController<bool> _vadController =
      StreamController<bool>.broadcast();

  /// Stream of voice activity completion events.
  Stream<bool> get voiceActivityStream => _vadController.stream;

  /// Broadcast stream emitting completed utterance audio as [Float32List].
  ///
  /// Each emission contains the normalized PCM samples for one detected
  /// utterance, extracted directly from the VAD segment. This allows
  /// [SherpaSttDatasource] to decode speech without maintaining a separate
  /// audio buffer or attempting to correlate stream timing with VAD events.

  // ── speechSegmentStream — Float32 samples for direct STT decode ──────────
  final StreamController<Float32List> _segmentController =
      StreamController<Float32List>.broadcast();

  /// Stream of completed utterance audio samples for STT decoding.
  Stream<Float32List> get speechSegmentStream => _segmentController.stream;

  /// Broadcast stream emitting raw PCM16 bytes from the microphone.
  ///
  /// Used exclusively by the push-to-talk fallback path in
  /// [SherpaSttDatasource] when the VAD model fails to initialize or is
  /// intentionally bypassed. Not used in always-on mode.

  // ── audioStream — raw PCM bytes used only by PTT buffering ───────────────
  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>.broadcast();

  /// Raw PCM16 audio stream for push-to-talk buffering.
  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  StreamSubscription<dynamic>? _audioSub;

  /// Initializes the Silero VAD model and prepares the datasource.
  ///
  /// Copies the ONNX model from assets to the application documents directory
  /// if not already present, then instantiates the sherpa-onnx
  /// [sherpa.VoiceActivityDetector].
  ///
  /// Returns [right] on success, or [left] with an [AppFailure] if:
  /// * Model file copy fails
  /// * Native VAD initialization fails (e.g., OOM, incompatible device)
  ///
  /// Note: Failure here does not block session start — the BLoC will fall
  /// back to push-to-talk mode.

  Future<Either<AppFailure, void>> initialize() async {
    try {
      final modelPath = await _copyAssetToLocal(
        "assets/models/silero_vad.onnx",
      );

      final vadConfig = sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          model: modelPath,
          threshold: 0.5,
          minSilenceDuration: 0.8,
          minSpeechDuration: 0.25,
          windowSize: 512,
        ),
        sampleRate: 16000,
        numThreads: 2,
        debug: false,
        // Hardware acceleration: NNAPI on Android (often buggy/slow fallback),
        // XNNPACK (highly optimized for ARM CPU), or CoreML on iOS.
        provider: Platform.isIOS ? "coreml" : "xnnpack",
      );
      _vad = sherpa.VoiceActivityDetector(
        config: vadConfig,
        bufferSizeInSeconds: 30,
      );

      debugPrint("[VAD] Silero VAD model loaded from $modelPath");
      return right(null);
    } on Exception catch (e) {
      debugPrint("[VAD] Init failed: $e — session will use push-to-talk");
      return left(AppFailure.networkFailure(message: "VAD init failed: $e"));
    }
  }

  /// Starts microphone monitoring and VAD processing.
  ///
  /// Requests microphone permission and begins streaming PCM16 audio. If the
  /// VAD model was successfully initialized, audio chunks are fed to the
  /// detector and completed utterance segments are emitted via
  /// [speechSegmentStream].
  ///
  /// Returns [right] on success, or [left] with an [AppFailure] if:
  /// * Permission denied ([AppFailure.sttPermissionDenied])
  /// * Recorder fails to start ([AppFailure.sttFailure])
  ///
  /// The microphone stream includes an [onError] handler to catch unexpected
  /// platform-level audio errors without crashing the BLoC.

  Future<Either<AppFailure, void>> startMonitoring({
    bool enableVad = true,
  }) async {
    // We do NOT gate on VAD model availability here.
    // PTT needs the mic open regardless of whether the VAD model loaded.
    // VAD segment processing below is skipped when _vad == null or enableVad is false.

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

      _audioSub = stream.listen(
        (chunk) {
          // Always broadcast raw bytes for PTT buffering in SherpaSttDatasource.
          if (!_audioStreamController.isClosed) {
            _audioStreamController.add(chunk);
          }

          // Always-on VAD processing — skipped when _vad is null (PTT fallback)
          // or explicitly disabled (PTT active session).
          if (_vad == null || !enableVad) return;
          _vad!.acceptWaveform(_convertPcm16ToFloat32(chunk));

          // sherpa-onnx VAD is segment-based:
          // isEmpty() returns false only AFTER a complete utterance
          // (speech + silence). front() holds the full audio for that
          // utterance, so we pass its samples directly to STT — no
          // external buffering or timing correlation required.
          while (!_vad!.isEmpty()) {
            final segment = _vad!.front();
            _vad!.pop();

            if (segment.samples.isEmpty) continue;

            // Emit the completed utterance samples for direct STT decoding.
            if (!_segmentController.isClosed) {
              _segmentController.add(segment.samples);
            }

            // The VAD detects segments post-hoc: by the time we process a
            // segment, the speech has already ended. Emitting 'true' here
            // would be misleading (it fires after speech is done, not at
            // the moment it starts) and would cause back-to-back true→false
            // events that confuse the BLoC's speaking-time accumulation.
            // We emit only 'false' to signal "utterance complete" so the
            // BLoC can stop the active-speaking clock.
            if (!_vadController.isClosed) {
              _vadController.add(false); // utterance complete
            }

            debugPrint(
              "[VAD] Segment emitted — ${segment.samples.length} samples "
              "(${(segment.samples.length / 16000).toStringAsFixed(2)}s)",
            );
          }
        },
        // Handles unexpected mic hardware errors (e.g. device revoked
        // audio focus mid-session). These bypass the Either wrapper
        // because they come from the platform stream, not our code.
        // Logged for observability; no crash, session degrades gracefully.
        onError: (Object error, StackTrace stackTrace) {
          debugPrint(
            "[VAD Audio Stream] Unexpected error: $error\n$stackTrace",
          );
        },
      );

      return right(null);
    } on Exception catch (e) {
      // FIXED: was AppFailure.networkFailure — incorrect because this is a
      // local audio hardware / recorder initialisation failure, not a network
      // call. Using sttFailure gives the BLoC the correct domain context and
      // prevents the UI from showing "check your connection" for a mic error.
      return left(AppFailure.sttFailure(message: "VAD monitoring failed: $e"));
    }
  }

  /// Stops microphone monitoring and cancels the audio stream subscription.
  ///
  /// Safe to call multiple times. Errors from the underlying recorder are
  /// caught and logged to avoid crashing during teardown.

  Future<void> stopMonitoring() async {
    await _audioSub?.cancel();
    _audioSub = null;

    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } on Exception catch (e) {
      debugPrint("[VAD] Safely ignored error stopping recorder: $e");
    }
  }

  /// Releases all resources held by this datasource.
  ///
  /// Calls [stopMonitoring], frees the native ONNX VAD model memory via
  /// [sherpa.VoiceActivityDetector.free], disposes the audio recorder, and
  /// closes all broadcast stream controllers.
  ///
  /// Safe to call multiple times. All cleanup operations are guarded against
  /// already-disposed state.

  Future<void> dispose() async {
    await stopMonitoring();

    // Release native ONNX runtime memory for the Silero VAD model (~2 MB).
    // The Dart GC cannot see native heap — without explicit free() this
    // memory leaks for the lifetime of the process. Nulling afterwards
    // prevents accidental reuse and allows the Dart wrapper to be collected.
    _vad?.free();
    _vad = null;

    try {
      await _recorder.dispose();
    } on Exception catch (e) {
      debugPrint("[VAD] Safely ignored error disposing recorder: $e");
    }

    if (!_vadController.isClosed) await _vadController.close();
    if (!_segmentController.isClosed) await _segmentController.close();
    if (!_audioStreamController.isClosed) await _audioStreamController.close();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Converts PCM16 little-endian bytes to normalized Float32 samples.
  ///
  /// sherpa-onnx expects audio in the range [-1.0, 1.0]. This helper divides
  /// each Int16 sample by 32768.0 to perform the conversion.

  Float32List _convertPcm16ToFloat32(Uint8List pcmBytes) {
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

  /// Copies an asset file to the application documents directory if missing.
  ///
  /// Used to stage the Silero VAD ONNX model at runtime. The file is only
  /// copied if it does not already exist, avoiding redundant I/O on subsequent
  /// sessions.
  ///
  /// Returns the local file path for use in VAD initialization.

  Future<String> _copyAssetToLocal(String assetPath) async {
    final docDir = await getApplicationDocumentsDirectory();
    final localPath = "${docDir.path}/$assetPath";
    final file = File(localPath);

    // Use sync File methods — I/O runs on background isolate on mobile,
    // so sync doesn't block the UI and reduces async overhead.
    // Also: existsSync() returns bool directly, fixing the negation lint error.
    if (!file.existsSync()) {
      file.parent.createSync(recursive: true);
      final byteData = await rootBundle.load(assetPath);
      file.writeAsBytesSync(
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
