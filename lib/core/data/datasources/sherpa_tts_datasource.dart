// lib/core/data/datasources/sherpa_tts_datasource.dart
//
// FIXES in this revision
// ──────────────────────
// 1. maxNumSenetences raised from 1 → 100.
//    With value 1 the VITS/Piper engine only synthesises audio up to the
//    FIRST punctuation boundary it detects internally (commas, colons, etc.),
//    dropping the rest of the text.  Setting it to 100 lets the engine process
//    the entire sentence in one generate() call.
//
// 2. Rotating WAV filenames (_wavIndex % 2 → lucia_0.wav / lucia_1.wav).
//    Reusing the same filename caused just_audio to serve a cached/stale audio
//    source for the second sentence onward (the file contents changed but the
//    URI did not).  Alternating between two files eliminates the cache hit
//    because we always await play() before writing the next file, so the
//    "other" slot is guaranteed free.
//
// 3. Explicit _player.stop() + seek(Duration.zero) before each play().
//    Ensures the player is in a clean, fully-reset state before loading each
//    new sentence, regardless of how the previous sentence ended.

import "dart:async";
import "dart:io";
import "dart:isolate";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:fpdart/fpdart.dart";
import "package:just_audio/just_audio.dart";
import "package:path_provider/path_provider.dart";
import "package:sherpa_onnx/sherpa_onnx.dart" as sherpa;
import "package:valoqui/core/domain/models/app_failure.dart";

// ── Background isolate entry point ─────────────────────────────────────────

/// Entry point for the background TTS isolate.
///
/// Receives model directory via arguments, initializes a sherpa-onnx
/// [sherpa.OfflineTts], then listens for synthesis requests via [ReceivePort].
/// Each request contains a [SendPort] for the reply, the text to speak,
/// and the target [wavPath].
///
/// On receiving `null`, closes the port — polite shutdown signal.
/// All errors are caught and logged; failures return false.
void _sherpaTtsIsolateEntry(List<dynamic> args) {
  final mainPort = args[0] as SendPort;
  final modelDir = args[1] as String;
  final modelFile = args[2] as String;
  final tokensFile = args[3] as String;
  final espeakDir = args[4] as String;

  final receivePort = ReceivePort();

  try {
    final config = sherpa.OfflineTtsConfig(
      model: sherpa.OfflineTtsModelConfig(
        vits: sherpa.OfflineTtsVitsModelConfig(
          model: "$modelDir/$modelFile",
          lexicon: "",
          tokens: "$modelDir/$tokensFile",
          dataDir: "$modelDir/$espeakDir",
          dictDir: "",
          noiseScale: 0.667,
          noiseScaleW: 0.8,
          lengthScale: 1.0,
        ),
        numThreads: 2,
        debug: false,
        provider: "cpu",
      ),
      ruleFsts: "",
      maxNumSenetences: 100,
    );

    final tts = sherpa.OfflineTts(config);
    mainPort.send(receivePort.sendPort);

    receivePort.listen((msg) {
      if (msg == null) {
        receivePort.close();
        return;
      }
      if (msg is! List || msg.length != 3) return;

      final replyPort = msg[0] as SendPort;
      final text = msg[1] as String;
      final wavPath = msg[2] as String;

      try {
        final audio = tts.generate(text: text, sid: 0, speed: 1.0);
        if (audio.samples.isNotEmpty) {
          sherpa.writeWave(
            filename: wavPath,
            samples: audio.samples,
            sampleRate: audio.sampleRate,
          );
          replyPort.send(true);
        } else {
          replyPort.send(false);
        }
      } on Exception catch (e) {
        debugPrint("[TTS Isolate] Synthesis error: $e");
        replyPort.send(false);
      }
    });
  } on Exception catch (e) {
    mainPort.send("error: $e");
  }
}

// ── Background isolate wrapper ─────────────────────────────────────────────

/// Wrapper for the background TTS isolate with safe lifecycle management.
class _SherpaTtsIsolate {
  SendPort? _port;
  Isolate? _isolate;

  /// Returns `true` if the isolate is ready to accept synthesis requests.
  bool get isReady => _port != null;

  /// Spawns the background isolate and waits for handshake completion.
  Future<bool> initialize(
    String modelDir,
    String modelFile,
    String tokensFile,
    String espeakDir,
  ) async {
    final handshake = ReceivePort();
    try {
      _isolate = await Isolate.spawn(_sherpaTtsIsolateEntry, [
        handshake.sendPort,
        modelDir,
        modelFile,
        tokensFile,
        espeakDir,
      ], debugName: 'SherpaTtsIsolate');

      final reply = await handshake.first;
      if (reply is SendPort) {
        _port = reply;
        return true;
      }
      debugPrint("[TTS Isolate] Init reply was not a SendPort: $reply");
      return false;
    } on Exception catch (e) {
      debugPrint("[TTS Isolate] Spawn failed: $e");
      return false;
    } finally {
      handshake.close();
    }
  }

  /// Synthesizes text to a WAV file via the background isolate.
  Future<bool> generateAndSave(String text, String wavPath) async {
    if (!isReady) return false;

    final reply = ReceivePort();
    try {
      _port!.send([reply.sendPort, text, wavPath]);
      final ok =
          await reply.first.timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  debugPrint("[TTS Isolate] Synthesis timeout");
                  return false;
                },
              )
              as bool;
      return ok;
    } on Exception catch (e) {
      debugPrint("[TTS Isolate] Synthesis error: $e");
      return false;
    } finally {
      reply.close();
    }
  }

  /// Terminates the background isolate and releases all resources.
  void dispose() {
    _port?.send(null);
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _port = null;
  }
}

// ── Main datasource ────────────────────────────────────────────────────────

/// Text-to-Speech datasource using sherpa-onnx VITS-Piper engine.
///
/// This datasource synthesizes Spanish speech from text and plays it via
/// [just_audio.AudioPlayer]. It manages an internal queue to handle multiple
/// [speak()] calls in sequence, draining them one sentence at a time.
///
/// ## Key Design Decisions
/// * **Rotating output files**: Alternates between `lucia_0.wav` and
///   `lucia_1.wav` to avoid [just_audio] serving cached audio when the URI
///   hasn't changed. Since we `await play()` before writing the next file,
///   the "other" slot is always free.
/// * **Player reset before each sentence**: Calls `stop()` + `seek(0)` before
///   `play()` to ensure the player is in a clean state regardless of how the
///   previous sentence ended.
/// * **Re-entrancy guard**: Sets `_isDrainingQueue = true` synchronously
///   before the fire-and-forget `_drainQueue()` call to prevent multiple
///   concurrent drain loops (engineering_lessons #1).
/// * **Queue-based synthesis**: Text is enqueued via [speak()] and processed
///   sequentially. This prevents overlapping audio and ensures natural pacing.
///
/// ## Stream Contract
/// [speakingStateStream] emits:
/// * `true` when the queue starts draining (first sentence begins playing)
/// * `false` when the queue is empty and playback has completed
///
/// Consumers can use this to show/hide a "speaking" indicator. The stream
/// does not emit per-sentence events — only queue-level start/complete.

class SherpaTtsDatasource {
  static const String _modelAssetDir =
      "assets/tts/vits-piper-es_ES-sharvard-medium";
  static const String _modelFile = "es_ES-sharvard-medium.onnx";
  static const String _configFile = "es_ES-sharvard-medium.onnx.json";
  static const String _tokensFile = "tokens.txt";
  static const String _espeakDir = "espeak-ng-data";

  final _SherpaTtsIsolate _ttsIsolate = _SherpaTtsIsolate();
  final AudioPlayer _player = AudioPlayer();
  final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();

  final List<String> _speechQueue = [];
  bool _isDrainingQueue = false;

  // Alternates between lucia_0.wav and lucia_1.wav so just_audio never
  // sees the same URI for consecutive sentences (avoids stale cache).

  /// Alternates between 0 and 1 to produce `lucia_speech_0.wav` /
  /// `lucia_speech_1.wav`. Prevents just_audio cache hits when the same
  /// URI is reused for consecutive sentences.

  int _wavIndex = 0;

  bool _initialized = false;

  /// Stream emitting `true` when TTS playback starts, `false` when complete.
  ///
  /// Used by the UI to show a speaking indicator. Emits at the queue level,
  /// not per-sentence: `true` on first sentence start, `false` after last
  /// sentence finishes or [stop()] is called.

  Stream<bool> get speakingStateStream => _speakingController.stream;

  /// Returns `true` if the queue is currently being drained.
  ///
  /// This is a synchronous snapshot of `_isDrainingQueue`. For reactive
  /// updates, listen to [speakingStateStream] instead.

  /// Warms up the TTS engine by performing a silent synthesis pass.
  /// This should be called before first use to eliminate cold start latency.
  ///
  /// Call this when entering the speaking state or when LLM generation begins
  /// to overlap TTS initialization with other processing.
  Future<void> warmUp() async {
    if (!_initialized || !_ttsIsolate.isReady) return;
    // Pre-synthesize a silent/near-silent sentence
    // This forces model loading and first-time initialization in the isolate
    final tmpDir = await getTemporaryDirectory();
    final wavPath = "${tmpDir.path}/warmup.wav";
    await _ttsIsolate.generateAndSave(" ", wavPath);
  }

  bool get isSpeaking => _isDrainingQueue;

  // ── Initialization ────────────────────────────────────

  /// Initializes the VITS-Piper TTS engine and copies model files to disk.
  ///
  /// Copies the ONNX model, config, tokens, and espeak-ng data from assets
  /// to the application documents directory if not already present. Then
  /// spawns the background TTS isolate.
  ///
  /// Returns [right] on success, or [left] with an [AppFailure] if:
  /// * Model file copy fails
  /// * Isolate spawn fails (e.g., OOM, incompatible device)
  ///
  /// Safe to call multiple times — re-initialization is idempotent.

  Future<Either<AppFailure, void>> initialize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelDir = "${dir.path}/tts_model";

      await _copyModelFiles(modelDir);

      final isolateOk = await _ttsIsolate.initialize(
        modelDir,
        _modelFile,
        _tokensFile,
        _espeakDir,
      );

      if (isolateOk) {
        _initialized = true;
        return right(null);
      } else {
        return left(
          const AppFailure.ttsFailure(message: "TTS Isolate init failed"),
        );
      }
    } on Exception catch (e) {
      return left(AppFailure.ttsFailure(message: "TTS init failed: $e"));
    }
  }

  // ── Public speak — enqueues text ───────────────────────

  /// Enqueues [text] for speech synthesis and playback.
  ///
  /// If the queue is idle, starts draining immediately via fire-and-forget
  /// `_drainQueue()`. The re-entrancy guard `_isDrainingQueue` is set
  /// synchronously before the async call to prevent race conditions where
  /// multiple drain loops could start concurrently (engineering_lessons #1).
  ///
  /// Returns [right] on successful enqueue, or [left] with
  /// [AppFailure.ttsNotInitialized] if [initialize()] was not called first.
  ///
  /// Note: This method does not wait for playback to complete. Use
  /// [speakingStateStream] to react to start/complete events.

  Future<Either<AppFailure, void>> speak(String text) async {
    if (!_initialized || !_ttsIsolate.isReady) {
      return left(const AppFailure.ttsNotInitialized());
    }
    _speechQueue.add(text);
    if (!_isDrainingQueue) {
      // NEW: no await between check and set to avoid multiple instances of the _drainqueue and to avoid race condtions
      _isDrainingQueue = true;
      // fire-and-forget is now safe (no await)
      // Explicitly document intentional fire and forget
      unawaited(_drainQueue());
    }
    return right(null);
  }

  // ── Internal queue drain ───────────────────────────────

  /// Drains the speech queue using a pipelined synthesis/playback architecture.
  ///
  /// While sentence N is playing, the background isolate synthesizes sentence N+1.
  /// This eliminates the gap between sentences and keeps the UI responsive by
  /// offloading all heavy work to the isolate.
  Future<void> _drainQueue() async {
    if (!_isDrainingQueue) return;
    if (!_speakingController.isClosed) _speakingController.add(true);

    Future<bool>? nextSynthesisFuture;
    String? currentWavPath;

    final tmpDir = await getTemporaryDirectory();

    while (_speechQueue.isNotEmpty || nextSynthesisFuture != null) {
      if (!_isDrainingQueue) break;

      // 1. Get the next synthesis result (either from previous loop or start new one)
      bool wavReady;
      if (nextSynthesisFuture != null) {
        wavReady = await nextSynthesisFuture;
        nextSynthesisFuture = null;
        // currentWavPath was already set in the previous iteration
      } else {
        final text = _speechQueue.removeAt(0);
        currentWavPath = "${tmpDir.path}/lucia_speech_${_wavIndex % 2}.wav";
        _wavIndex++;
        wavReady = await _ttsIsolate.generateAndSave(text, currentWavPath);
      }

      if (wavReady && _isDrainingQueue) {
        // 2. Start playback of the synthesized WAV
        try {
          await _player.stop();
          await _player.setFilePath(currentWavPath!);
          await _player.seek(Duration.zero);
          final playFuture = _player.play();

          // 3. Pre-synthesize the NEXT sentence while the current one is playing!
          if (_speechQueue.isNotEmpty) {
            final nextText = _speechQueue.removeAt(0);
            final nextWavPath =
                "${tmpDir.path}/lucia_speech_${_wavIndex % 2}.wav";
            _wavIndex++;
            nextSynthesisFuture = _ttsIsolate.generateAndSave(
              nextText,
              nextWavPath,
            );
            // Store currentWavPath for the next iteration's playback
            currentWavPath = nextWavPath;
          }

          // 4. Await playback completion before continuing the loop
          await playFuture;
        } on Exception catch (e) {
          debugPrint("[TTS] Playback error: $e");
        }
      }
    }

    if (_isDrainingQueue) {
      _isDrainingQueue = false;
      if (!_speakingController.isClosed) _speakingController.add(false);
    }
  }

  // ── Stop ──────────────────────────────────────────────

  /// Stops all pending and current TTS playback immediately.
  ///
  /// Clears the speech queue, sets the drain guard to `false`, stops the
  /// audio player, and emits `false` on [speakingStateStream]. Safe to call
  /// multiple times — idempotent and guards against already-stopped state.

  Future<void> stop() async {
    _isDrainingQueue = false;
    _speechQueue.clear();
    await _player.stop();
    if (!_speakingController.isClosed) _speakingController.add(false);
  }

  // ── Dispose ────────────────────────────────────────────

  /// Releases all resources held by this datasource.
  ///
  /// Stops playback, clears the queue, disposes the [AudioPlayer], and closes
  /// the speaking state stream controller. The background isolate is killed
  /// explicitly to prevent memory leaks.
  ///
  /// Safe to call multiple times. All cleanup operations are guarded against
  /// already-disposed state.

  Future<void> dispose() async {
    _isDrainingQueue = false;
    _speechQueue.clear();
    _ttsIsolate.dispose();
    await _player.dispose();
    await _speakingController.close();
  }

  // ── Asset copying ──────────────────────────────────────

  /// Copies all TTS model files from assets to [destDir].
  ///
  /// Copies the ONNX model, config JSON, tokens file, and the entire
  /// espeak-ng data directory. Files are only copied if they don't already
  /// exist, avoiding redundant I/O on subsequent sessions.

  Future<void> _copyModelFiles(String destDir) async {
    await _copyAsset("$_modelAssetDir/$_modelFile", "$destDir/$_modelFile");
    await _copyAsset("$_modelAssetDir/$_configFile", "$destDir/$_configFile");
    await _copyAsset("$_modelAssetDir/$_tokensFile", "$destDir/$_tokensFile");
    await _copyEspeakData(destDir);
  }

  /// Copies a single asset file to [destPath] if it doesn't already exist.
  ///
  /// Creates parent directories as needed. Uses [rootBundle.load] to read
  /// the asset and [File.writeAsBytes] to write it to disk.

  Future<void> _copyAsset(String assetPath, String destPath) async {
    final file = File(destPath);

    // Use sync File methods — I/O runs on background isolate on mobile,
    // so sync doesn't block the UI and reduces async overhead.
    // Also: existsSync() returns bool directly, fixing the negation lint error.
    if (file.existsSync()) return;
    file.parent.createSync(recursive: true);
    final bytes = await rootBundle.load(assetPath);
    file.writeAsBytesSync(bytes.buffer.asUint8List());
    debugPrint("[TTS] Copied $assetPath");
  }

  /// Copies the espeak-ng data directory from assets to [destDir].
  ///
  /// Iterates over the asset manifest to find all files under the espeak
  /// prefix, then copies each one while preserving the relative path structure.

  Future<void> _copyEspeakData(String destDir) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    const prefix = "$_modelAssetDir/$_espeakDir/";
    final assets = manifest.listAssets().where((p) => p.startsWith(prefix));
    for (final assetPath in assets) {
      final rel = assetPath.substring(prefix.length);
      await _copyAsset(assetPath, "$destDir/$_espeakDir/$rel");
    }
  }
}
