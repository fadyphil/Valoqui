// lib/core/data/datasources/sherpa_stt_datasource.dart
//
// Two decode paths — only one fires per mode:
//
//   PTT (push-to-talk):
//     MicPressed → startListening() → buffer PCM bytes → MicReleased →
//     stopListening() → _decodeUtterance(pcmBytes) → _decodeFloat32()
//
//   Always-on:
//     VAD emits completed SpeechSegment → _onSpeechSegment(Float32List) →
//     _decodeFloat32() directly — no PCM buffering involved.
//
// Root cause of the always-on silence (fixed here):
//   The previous code tried to buffer real-time audioStream bytes and decode
//   them when voiceActivityStream emitted false. But sherpa-onnx VAD is
//   segment-based: isEmpty() only becomes false AFTER silence follows speech,
//   at which point the audio has already passed through the stream. The VAD
//   also never emitted false (only true, from completed segments), so
//   _decodeUtterance was never called. Fix: listen to speechSegmentStream
//   which carries the completed segment's own samples.

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
      await Isolate.spawn(
        _sherpaIsolateEntry,
        [handshake.sendPort, encoderPath, decoderPath, tokensPath],
      );
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
  Stream<String> get textStream => _textController.stream;

  // voiceActivityStream subscription — keeps _onVadEvent for PTT compat.
  StreamSubscription<bool>? _vadSub;
  // audioStream subscription — raw PCM bytes for PTT buffering.
  StreamSubscription<List<int>>? _audioSub;
  // speechSegmentStream subscription — always-on decode path.
  StreamSubscription<Float32List>? _segmentSub;

  final BytesBuilder _audioBuffer = BytesBuilder();
  bool _isRecordingUtterance = false;

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

      // Always-on path: decode completed speech segments directly.
      _segmentSub = _vadRepository.speechSegmentStream.listen(
        _onSpeechSegment,
      );

      // PTT path: buffer raw bytes while button held, decode on release.
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

  void stopListening() {
    if (!_isRecordingUtterance) return;
    _isRecordingUtterance = false;
    _decodeUtterance(_audioBuffer.takeBytes());
  }

  // ── Always-on segment path ────────────────────────────────────────────────
  //
  // Called when the VAD emits a completed SpeechSegment (speech + silence).
  // The segment already contains the utterance audio as Float32 — decode it
  // directly without going through the PCM buffer.

  void _onSpeechSegment(Float32List samples) {
    debugPrint("[STT] Segment received — ${samples.length} samples, decoding…");
    _decodeFloat32(samples);
  }

  // ── PTT / VAD buffer path ─────────────────────────────────────────────────
  //
  // _onVadEvent is kept for PTT compatibility but is effectively a no-op in
  // always-on mode: voiceActivityStream emits true→false back-to-back after
  // a segment completes, so the buffer is always empty by the time false fires.

  void _onVadEvent(bool isSpeaking) {
    if (isSpeaking) {
      _audioBuffer.clear();
      _isRecordingUtterance = true;
    } else if (_isRecordingUtterance) {
      _isRecordingUtterance = false;
      _decodeUtterance(_audioBuffer.takeBytes()); // empty in always-on, no-op
    }
  }

  void _onAudioBytesReceived(List<int> chunk) {
    if (_isRecordingUtterance) {
      _audioBuffer.add(chunk);
    }
  }

  // ── Decode ────────────────────────────────────────────────────────────────

  Future<void> _decodeUtterance(List<int> pcmBytes) async {
    if (pcmBytes.isEmpty) return;
    final bytes =
        pcmBytes is Uint8List ? pcmBytes : Uint8List.fromList(pcmBytes);
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

  static Float32List _pcm16ToFloat32(Uint8List bytes) {
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
      debugPrint("[STT] Copied $assetPath");
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
  }
}
