// lib/core/data/datasources/sherpa_tts_datasource.dart
//
// On-device TTS using sherpa-onnx with the Piper es_ES-sharvard-medium voice.
// Model files are bundled in the APK as Flutter assets. On first launch
// they are copied to the app's documents directory (~76 MB, one-time).
// All subsequent launches skip the copy (file-exists check).
//
// Latency: ~50ms per sentence on mid-range Android hardware.
// This eliminates the cloud TTS round-trip that competitors pay.

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
  static const String _tokensFile = "tokens.txt"; // ← ADD
  static const String _espeakDir = "espeak-ng-data";

  sherpa.OfflineTts? _tts;
  final AudioPlayer _player = AudioPlayer();
  final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();

  bool _initialized = false;

  Stream<bool> get speakingStateStream => _speakingController.stream;
  bool get isSpeaking => _player.playing;

  Future<Either<AppFailure, void>> initialize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelDir = "${dir.path}/tts_model";

      // Copy model files on first launch only
      await _copyModelFiles(modelDir);

      final config = sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: "$modelDir/$_modelFile",
            lexicon: "",
            tokens: "$modelDir/$_tokensFile", // ← WAS ""
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
        maxNumSenetences: 1,
      );

      _tts = sherpa.OfflineTts(config);
      _initialized = true;

      // Forward AudioPlayer playing state to our stream
      _player.playerStateStream.listen((state) {
        if (!_speakingController.isClosed) {
          _speakingController.add(state.playing);
        }
      });

      return right(null);
    } catch (e) {
      return left(AppFailure.ttsFailure(message: "TTS init failed: $e"));
    }
  }

  Future<Either<AppFailure, void>> speak(String text) async {
    if (!_initialized || _tts == null) {
      return left(const AppFailure.ttsNotInitialized());
    }

    try {
      // Stop any currently playing audio before generating new audio.
      // This handles sentence-boundary TTS overlaps gracefully.
      await _player.stop();

      // Generate audio and write WAV to temp file in one chain —
      // avoids the "unused local variable" warning from storing the
      // GeneratedAudio object before calling .save() on it.
      final tmpDir = await getTemporaryDirectory();
      final wavPath = "${tmpDir.path}/lucia_speech.wav";
      final audio = _tts!.generate(text: text, sid: 0, speed: 1.0);
      sherpa.writeWave(
        filename: wavPath,
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );
      await _player.setFilePath(wavPath);
      await _player.play();

      return right(null);
    } catch (e) {
      return left(AppFailure.ttsFailure(message: "TTS speak failed: $e"));
    }
  }

  Future<void> stop() => _player.stop();

  Future<void> dispose() async {
    await _player.dispose();
    await _speakingController.close();
  }

  // ── Asset copying ──────────────────────────────────────

  Future<void> _copyModelFiles(String destDir) async {
    await _copyAsset("$_modelAssetDir/$_modelFile", "$destDir/$_modelFile");
    await _copyAsset("$_modelAssetDir/$_configFile", "$destDir/$_configFile");
    await _copyAsset(
      "$_modelAssetDir/$_tokensFile",
      "$destDir/$_tokensFile",
    ); // ← ADD
    await _copyEspeakData(destDir);
  }

  Future<void> _copyAsset(String assetPath, String destPath) async {
    final file = File(destPath);
    if (await file.exists()) return; // already copied on a previous launch

    await file.parent.create(recursive: true);
    final bytes = await rootBundle.load(assetPath);
    await file.writeAsBytes(bytes.buffer.asUint8List());
    debugPrint("[TTS] Copied $assetPath");
  }

  Future<void> _copyEspeakData(String destDir) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final prefix = "$_modelAssetDir/$_espeakDir/";

    final assets = manifest.listAssets().where(
      (path) => path.startsWith(prefix),
    );

    for (final assetPath in assets) {
      final relativeName = assetPath.substring(prefix.length);
      await _copyAsset(assetPath, "$destDir/$_espeakDir/$relativeName");
    }
  }
}
