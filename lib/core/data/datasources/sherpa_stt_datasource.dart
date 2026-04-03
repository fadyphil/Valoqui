// lib/core/data/datasources/sherpa_stt_datasource.dart

import "dart:async";
import "dart:io";
import "dart:isolate";
import "dart:typed_data";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart" show rootBundle;
import "package:fpdart/fpdart.dart";
import "package:path_provider/path_provider.dart";
import "package:sherpa_onnx/sherpa_onnx.dart" as sherpa;
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/repositories/vad_repository.dart";

// ── Background isolate entry point ─────────────────────────────────────────

void _sherpaIsolateEntry(List<dynamic> args) {
  final mainPort = args[0] as SendPort;
  final encoderPath = args[1] as String;
  final decoderPath = args[2] as String;
  final tokensPath = args[3] as String;

  final receivePort = ReceivePort();

  try {
    final config = sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        moonshine: sherpa.OfflineMoonshineModelConfig(
          encoder: encoderPath,
          mergedDecoder: decoderPath,
        ),
        tokens: tokensPath,
        modelType: "",
        numThreads: 2,
        debug: false,
      ),
    );

    final recognizer = sherpa.OfflineRecognizer(config);
    mainPort.send(receivePort.sendPort);

    receivePort.listen((msg) {
      if (msg == null) {
        recognizer.free();
        receivePort.close();
        return;
      }
      if (msg is! List || msg.length != 2) return;

      final replyPort = msg[0] as SendPort;
      final samples = msg[1] as Float32List;

      try {
        final stream = recognizer.createStream();
        stream.acceptWaveform(sampleRate: 16000, samples: samples);
        recognizer.decode(stream);
        final result = recognizer.getResult(stream);
        stream.free();
        replyPort.send(result.text);
      } catch (e) {
        debugPrint("[STT Isolate] Decode error: $e");
        replyPort.send("");
      }
    });
  } catch (e) {
    mainPort.send("error: $e");
  }
}

// ── Background isolate wrapper ─────────────────────────────────────────────

class _SherpaDecodeIsolate {
  SendPort? _port;
  bool get isReady => _port != null;

  Future<bool> initialize(
    String encoderPath,
    String decoderPath,
    String tokensPath,
  ) async {
    final handshake = ReceivePort();
    try {
      await Isolate.spawn(_sherpaIsolateEntry, [
        handshake.sendPort,
        encoderPath,
        decoderPath,
        tokensPath,
      ]);
      final reply = await handshake.first;
      if (reply is SendPort) {
        _port = reply;
        return true;
      }
      debugPrint("[STT Isolate] Init reply was not a SendPort: $reply");
      return false;
    } catch (e) {
      debugPrint("[STT Isolate] Spawn failed: $e");
      return false;
    } finally {
      handshake.close();
    }
  }

  Future<String> decode(Float32List samples) async {
    if (!isReady) return "";
    final reply = ReceivePort();
    _port!.send([reply.sendPort, samples]);
    final text = await reply.first as String;
    reply.close();
    return text;
  }

  void dispose() {
    _port?.send(null);
    _port = null;
  }
}

// ── Main datasource ────────────────────────────────────────────────────────

class SherpaSttDatasource {
  final VadRepository _vadRepository;

  sherpa.OfflineRecognizer? _fallbackRecognizer;
  final _SherpaDecodeIsolate _decodeIsolate = _SherpaDecodeIsolate();

  final StreamController<String> _textController =
      StreamController<String>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  Stream<String> get textStream => _textController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  StreamSubscription<bool>? _vadSub;
  StreamSubscription<List<int>>? _audioSub;
  StreamSubscription<Float32List>? _segmentSub;

  final BytesBuilder _audioBuffer = BytesBuilder();
  bool _isRecordingUtterance = false;

  bool get isListening => _isRecordingUtterance;

  String _encoderPath = "";
  String _decoderPath = "";
  String _tokensPath = "";

  SherpaSttDatasource({required VadRepository vadRepository})
    : _vadRepository = vadRepository;

  Future<Either<AppFailure, void>> initialize() async {
    try {
      _encoderPath = await _copyAssetToLocal(
        "assets/stt/sherpa_stt_es/encoder_model.ort",
      );
      _decoderPath = await _copyAssetToLocal(
        "assets/stt/sherpa_stt_es/decoder_model_merged.ort",
      );
      _tokensPath = await _copyAssetToLocal(
        "assets/stt/sherpa_stt_es/tokens.txt",
      );

      final isolateOk = await _decodeIsolate.initialize(
        _encoderPath,
        _decoderPath,
        _tokensPath,
      );

      if (isolateOk) {
        debugPrint("[STT] Background isolate ready.");
      } else {
        debugPrint("[STT] Isolate unavailable — falling back to main thread.");
        _fallbackRecognizer = _buildRecognizer();
      }

      _segmentSub = _vadRepository.speechSegmentStream.listen(_onSpeechSegment);
      _vadSub = _vadRepository.voiceActivityStream.listen(_onVadEvent);
      _audioSub = _vadRepository.audioStream.listen(_onAudioBytesReceived);

      return right(null);
    } catch (e) {
      debugPrint("[STT] Init failed: $e");
      return left(AppFailure.networkFailure(message: "STT init failed: $e"));
    }
  }

  // ── PTT controls ──────────────────────────────────────────────────────────

  void startListening() {
    _audioBuffer.clear();
    _isRecordingUtterance = true;
  }

  Future<String> stopListening() async {
    if (!_isRecordingUtterance) return "";
    _isRecordingUtterance = false;

    // Decay amplitude to zero visually when stopping
    if (!_amplitudeController.isClosed) {
      _amplitudeController.add(0.0);
    }

    final bytes = _audioBuffer.takeBytes();
    await _decodeUtterance(bytes);

    // Final text arrives via textStream, returning empty here aligns with contract
    return "";
  }

  // ── Always-on segment path ────────────────────────────────────────────────

  void _onSpeechSegment(Float32List samples) {
    debugPrint("[STT] Segment received — ${samples.length} samples, decoding…");
    _decodeFloat32(samples);
  }

  // ── PTT / VAD buffer path ─────────────────────────────────────────────────

  void _onVadEvent(bool isSpeaking) {
    if (isSpeaking) {
      _audioBuffer.clear();
      _isRecordingUtterance = true;
    } else if (_isRecordingUtterance) {
      _isRecordingUtterance = false;
      _decodeUtterance(_audioBuffer.takeBytes());
    }
  }

  void _onAudioBytesReceived(List<int> chunk) {
    if (_isRecordingUtterance) {
      _audioBuffer.add(chunk);
    }
    // Calculate and emit amplitude continuously whenever audio flows
    _calculateAndEmitAmplitude(chunk);
  }

  // Extracts peak volume from 16-bit PCM chunk and normalizes it to 0.0 - 1.0
  // Extracts peak volume from 16-bit PCM chunk and normalizes it to 0.0 - 1.0
  void _calculateAndEmitAmplitude(List<int> chunk) {
    if (_amplitudeController.isClosed || chunk.isEmpty) return;

    // FIX: Ensure memory alignment. If the offset isn't a multiple of 2,
    // we must create a fresh, cleanly aligned copy of the bytes.
    Uint8List bytes;
    if (chunk is Uint8List && chunk.offsetInBytes % 2 == 0) {
      bytes = chunk;
    } else {
      bytes = Uint8List.fromList(chunk);
    }

    final int16 = Int16List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.length ~/ 2,
    );

    int maxAmplitude = 0;
    for (int i = 0; i < int16.length; i++) {
      final absValue = int16[i].abs();
      if (absValue > maxAmplitude) {
        maxAmplitude = absValue;
      }
    }

    // Max value for 16-bit PCM is 32768.
    final normalized = (maxAmplitude / 32768.0).clamp(0.0, 1.0);
    _amplitudeController.add(normalized);
  }

  // ── Decode ────────────────────────────────────────────────────────────────

  Future<void> _decodeUtterance(List<int> pcmBytes) async {
    if (pcmBytes.isEmpty) return;
    final bytes = pcmBytes is Uint8List
        ? pcmBytes
        : Uint8List.fromList(pcmBytes);
    await _decodeFloat32(_pcm16ToFloat32(bytes));
  }

  Future<void> _decodeFloat32(Float32List samples) async {
    if (samples.isEmpty) return;

    final String text;
    if (_decodeIsolate.isReady) {
      text = await _decodeIsolate.decode(samples);
    } else {
      text = _decodeSynchronously(samples);
    }

    if (text.isNotEmpty && !_textController.isClosed) {
      debugPrint("[STT] Transcript: $text");
      _textController.add(text);
    }
  }

  String _decodeSynchronously(Float32List samples) {
    _fallbackRecognizer ??= _buildRecognizer();
    try {
      final stream = _fallbackRecognizer!.createStream();
      stream.acceptWaveform(sampleRate: 16000, samples: samples);
      _fallbackRecognizer!.decode(stream);
      final result = _fallbackRecognizer!.getResult(stream);
      stream.free();
      return result.text;
    } catch (e) {
      debugPrint("[STT] Sync decode error: $e");
      return "";
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  sherpa.OfflineRecognizer _buildRecognizer() {
    return sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          moonshine: sherpa.OfflineMoonshineModelConfig(
            encoder: _encoderPath,
            mergedDecoder: _decoderPath,
          ),
          tokens: _tokensPath,
          modelType: "",
          numThreads: 2,
          debug: false,
        ),
      ),
    );
  }

  static Float32List _pcm16ToFloat32(Uint8List rawBytes) {
    // FIX: Ensure memory alignment for decoding as well
    final bytes = rawBytes.offsetInBytes % 2 == 0
        ? rawBytes
        : Uint8List.fromList(rawBytes);

    final int16 = Int16List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.length ~/ 2,
    );
    final f32 = Float32List(int16.length);
    for (int i = 0; i < int16.length; i++) {
      f32[i] = int16[i] / 32768.0;
    }
    return f32;
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
    }
    return localPath;
  }

  Future<void> dispose() async {
    await _segmentSub?.cancel();
    await _vadSub?.cancel();
    await _audioSub?.cancel();
    _decodeIsolate.dispose();
    _fallbackRecognizer?.free();
    if (!_textController.isClosed) await _textController.close();
    if (!_amplitudeController.isClosed) await _amplitudeController.close();
  }
}
