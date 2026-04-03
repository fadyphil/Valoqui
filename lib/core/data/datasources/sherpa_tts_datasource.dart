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
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:fpdart/fpdart.dart";
import "package:just_audio/just_audio.dart";
import "package:path_provider/path_provider.dart";
import "package:sherpa_onnx/sherpa_onnx.dart" as sherpa;
import "package:valoqui/core/domain/models/app_failure.dart";

class SherpaTtsDatasource {
  static const String _modelAssetDir =
      "assets/tts/vits-piper-es_ES-sharvard-medium";
  static const String _modelFile = "es_ES-sharvard-medium.onnx";
  static const String _configFile = "es_ES-sharvard-medium.onnx.json";
  static const String _tokensFile = "tokens.txt";
  static const String _espeakDir = "espeak-ng-data";

  sherpa.OfflineTts? _tts;
  final AudioPlayer _player = AudioPlayer();
  final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();

  final List<String> _speechQueue = [];
  bool _isDrainingQueue = false;

  // Alternates between lucia_0.wav and lucia_1.wav so just_audio never
  // sees the same URI for consecutive sentences (avoids stale cache).
  int _wavIndex = 0;

  bool _initialized = false;

  Stream<bool> get speakingStateStream => _speakingController.stream;
  bool get isSpeaking => _isDrainingQueue;

  // ── Initialization ────────────────────────────────────

  Future<Either<AppFailure, void>> initialize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelDir = "${dir.path}/tts_model";

      await _copyModelFiles(modelDir);

      final config = sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: "$modelDir/$_modelFile",
            lexicon: "",
            tokens: "$modelDir/$_tokensFile",
            dataDir: "$modelDir/$_espeakDir",
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
        // Fix 1: was 1, which caused the VITS engine to truncate at the
        // first internal sentence boundary (e.g. a comma) and discard the rest.
        maxNumSenetences: 100,
      );

      _tts = sherpa.OfflineTts(config);
      _initialized = true;
      return right(null);
    } catch (e) {
      return left(AppFailure.ttsFailure(message: "TTS init failed: $e"));
    }
  }

  // ── Public speak — enqueues text ───────────────────────

  Future<Either<AppFailure, void>> speak(String text) async {
    if (!_initialized || _tts == null) {
      return left(const AppFailure.ttsNotInitialized());
    }
    _speechQueue.add(text);
    if (!_isDrainingQueue) {
      _drainQueue(); // fire-and-forget
    }
    return right(null);
  }

  // ── Internal queue drain ───────────────────────────────

  Future<void> _drainQueue() async {
    _isDrainingQueue = true;
    if (!_speakingController.isClosed) _speakingController.add(true);

    while (_speechQueue.isNotEmpty) {
      if (!_isDrainingQueue) break;
      final text = _speechQueue.removeAt(0);
      await _playSingleSentence(text);
    }

    if (_isDrainingQueue) {
      _isDrainingQueue = false;
      if (!_speakingController.isClosed) _speakingController.add(false);
    }
  }

  Future<void> _playSingleSentence(String text) async {
    if (!_isDrainingQueue) return; // stop() was called mid-queue
    try {
      final tmpDir = await getTemporaryDirectory();

      // Fix 2: rotate between two filenames so just_audio sees a new URI
      // for every sentence and cannot serve a cached audio source.
      // Since we await play() before calling this method for the next
      // sentence, the "other" file slot is always free when we write to it.
      final wavPath = "${tmpDir.path}/lucia_speech_${_wavIndex % 2}.wav";
      _wavIndex++;

      final audio = _tts!.generate(text: text, sid: 0, speed: 1.0);
      if (audio.samples.isEmpty) return;

      sherpa.writeWave(
        filename: wavPath,
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );

      // Fix 3: explicitly reset the player before each sentence so it is
      // never in a completed/error state when we call play().
      await _player.stop();
      await _player.setFilePath(wavPath);
      await _player.seek(Duration.zero);
      await _player.play(); // resolves when this sentence finishes
    } catch (e) {
      debugPrint("[TTS] Error playing sentence: $e");
    }
  }

  // ── Stop ──────────────────────────────────────────────

  Future<void> stop() async {
    _isDrainingQueue = false;
    _speechQueue.clear();
    await _player.stop();
    if (!_speakingController.isClosed) _speakingController.add(false);
  }

  // ── Dispose ────────────────────────────────────────────

  Future<void> dispose() async {
    _isDrainingQueue = false;
    _speechQueue.clear();
    await _player.dispose();
    await _speakingController.close();
  }

  // ── Asset copying ──────────────────────────────────────

  Future<void> _copyModelFiles(String destDir) async {
    await _copyAsset("$_modelAssetDir/$_modelFile", "$destDir/$_modelFile");
    await _copyAsset("$_modelAssetDir/$_configFile", "$destDir/$_configFile");
    await _copyAsset("$_modelAssetDir/$_tokensFile", "$destDir/$_tokensFile");
    await _copyEspeakData(destDir);
  }

  Future<void> _copyAsset(String assetPath, String destPath) async {
    final file = File(destPath);
    if (await file.exists()) return;
    await file.parent.create(recursive: true);
    final bytes = await rootBundle.load(assetPath);
    await file.writeAsBytes(bytes.buffer.asUint8List());
    debugPrint("[TTS] Copied $assetPath");
  }

  Future<void> _copyEspeakData(String destDir) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final prefix = "$_modelAssetDir/$_espeakDir/";
    final assets = manifest.listAssets().where((p) => p.startsWith(prefix));
    for (final assetPath in assets) {
      final rel = assetPath.substring(prefix.length);
      await _copyAsset(assetPath, "$destDir/$_espeakDir/$rel");
    }
  }
}
