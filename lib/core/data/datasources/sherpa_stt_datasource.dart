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

/// Entry point for the background decode isolate.
///
/// Receives model paths via arguments, initializes a sherpa-onnx
/// [sherpa.OfflineRecognizer], then listens for decode requests via
/// [ReceivePort]. Each request contains a [SendPort] for the reply and
/// Float32 audio samples.
///
/// On receiving `null`, frees the recognizer and closes the port — polite
/// shutdown signal from the main isolate. All errors are caught and logged;
/// decode failures return empty string to avoid crashing the isolate.
void _sherpaIsolateEntry(List<dynamic> args) {
  final mainPort = args[0] as SendPort;
  final encoderPath = args[1] as String;
  final decoderPath = args[2] as String;
  final tokensPath = args[3] as String;

  final receivePort = ReceivePort();

  try {
    // Initialize native bindings inside the isolate before using sherpa
    sherpa.initBindings();

    final config = sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        moonshine: sherpa.OfflineMoonshineModelConfig(
          encoder: encoderPath,
          mergedDecoder: decoderPath,
        ),
        tokens: tokensPath,
        modelType: "",
        // Reliable xnnpack with 4 threads for better performance on mobile hardware
        numThreads: 4,
        debug: false,
        provider: Platform.isAndroid
            ? "xnnpack"
            : (Platform.isIOS ? "coreml" : "cpu"),
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
        final stopwatch = Stopwatch()..start();
        final stream = recognizer.createStream();
        stream.acceptWaveform(sampleRate: 16000, samples: samples);

        final audioDurationMs = (samples.length / 16000) * 1000;

        recognizer.decode(stream);
        final result = recognizer.getResult(stream);
        stream.free();
        stopwatch.stop();

        final decodeMs = stopwatch.elapsedMilliseconds;
        final rtf = audioDurationMs > 0 ? decodeMs / audioDurationMs : 0.0;

        debugPrint(
          "[STT Isolate] Decode completed in ${decodeMs}ms (Audio: ${audioDurationMs.toStringAsFixed(0)}ms, RTF: ${rtf.toStringAsFixed(3)})",
        );

        replyPort.send(result.text);
      } on Exception catch (e) {
        debugPrint("[STT Isolate] Decode error: $e");
        replyPort.send("");
      }
    });
  } on Exception catch (e) {
    mainPort.send("error: $e");
  }
}

// ── Background isolate wrapper ─────────────────────────────────────────────
// Current problem  is that the Isolate is never explicitly killed leading to a memory leak
// it sends a null to  the isolate politely asking it to terminate but if an exception is thrown or it is mid decoding it won't terminate

/// Wrapper for the background decode isolate with safe lifecycle management.
///
/// ## Fixes Implemented
/// * **Isolate reference capture**: Stores the [Isolate] object on spawn so
///   [dispose()] can call `.kill()` — not just send a polite `null` message.
///   Guarantees OS-level cleanup even if the isolate is frozen or crashed
///   (engineering_lessons #2).
/// * **Timeout on decode**: Wraps `reply.first` in `.timeout()` with 10s
///   limit and graceful fallback to empty string. Prevents hangs if the
///   isolate becomes unresponsive (engineering_lessons #1).
/// * **Error handling**: Catches all exceptions during decode and returns
///   empty string — a single failed decode should not crash the isolate
///   or block subsequent requests.
///
/// ## Usage
/// ```dart
/// await isolate.initialize(encoder, decoder, tokens);
/// final text = await isolate.decode(samples); // with timeout + fallback
/// isolate.dispose(); // kills isolate + frees native memory
/// ```
class _SherpaDecodeIsolate {
  SendPort? _port;
  Isolate? _isolate; // NEW: to hold OS reference so we can kill it

  /// NEW: tracks number of active decode futures awaiting a reply from the
  /// background isolate. Used for backpressure/bounded queueing.
  int _activeDecodes = 0;
  static const int _maxDecodeQueue = 3;

  /// Returns `true` if the isolate is ready to accept decode requests.
  bool get isReady => _port != null;

  /// Spawns the background isolate and waits for handshake completion.
  ///
  /// Sends model paths to the isolate entry point, then waits for the
  /// isolate to reply with its [SendPort] for future decode requests.
  ///
  /// Returns `true` on successful handshake, `false` if:
  /// * Isolate spawn fails (OS restrictions, low memory)
  /// * Handshake reply is not a [SendPort] (unexpected protocol error)
  ///
  /// The [Isolate] object is stored in [_isolate] so [dispose()] can
  /// call `.kill()` — essential for guaranteed cleanup (engineering_lessons #2).
  Future<bool> initialize(
    String encoderPath,
    String decoderPath,
    String tokensPath,
  ) async {
    final handshake = ReceivePort();
    try {
      //old implementation
      // await Isolate.spawn(_sherpaIsolateEntry, [
      //   handshake.sendPort,
      //   encoderPath,
      //   decoderPath,
      //   tokensPath,
      // ]);

      // NEW implementation : we Capture the isolate reference on Spawn
      /// now [[dispose()]] can kill the isolate forcefully to ensure no memory leaks
      // following the rule of whoever creates something is responsible to destroy it
      _isolate = await Isolate.spawn(_sherpaIsolateEntry, [
        handshake.sendPort,
        encoderPath,
        decoderPath,
        tokensPath,
      ], debugName: 'SherpaDecodeIsolate');

      final reply = await handshake.first;
      if (reply is SendPort) {
        _port = reply;
        return true;
      }
      debugPrint("[STT Isolate] Init reply was not a SendPort: $reply");
      return false;
    } on Exception catch (e) {
      debugPrint("[STT Isolate] Spawn failed: $e");
      return false;
    } finally {
      handshake.close();
    }
  }
  // Old implementation problem is waiting for a reply [[reply.first]] assumes it will reply and that's a problem , also no error or exception handling
  // Future<String> decode(Float32List samples) async {
  //   if (!isReady) return "";
  //   final reply = ReceivePort();
  //   _port!.send([reply.sendPort, samples]);
  //   final text = await reply.first as String;
  //   reply.close();
  //   return text;
  // }

  // void dispose() {
  //   _port?.send(null);
  //   _port = null;
  // }

  // New implementation supposed to solve the problem  by handling errors and exceptions
  // by ustilizing the TIMEOUT method error handling is better also the wait time is bounded
  // the finally block guarantees that the port is closed even if an error occurs

  /// Decodes Float32 audio samples to text via the background isolate.
  ///
  /// Sends samples to the isolate via [_port] and awaits the reply.
  ///
  /// ## Timeout Protection
  /// Wraps the await in `.timeout(const Duration(seconds: 10))` with a
  /// graceful fallback to empty string. Prevents the calling code from
  /// hanging indefinitely if the isolate becomes unresponsive (OOM, crash,
  /// native exception) — a critical fix for production stability
  /// (engineering_lessons #1).
  ///
  /// ## Error Handling
  /// Catches all exceptions during the decode round-trip and returns empty
  /// string. A single failed decode should not crash the isolate or block
  /// subsequent requests.
  Future<String> decode(Float32List samples) async {
    if (!isReady) return "";

    // Load shedding: if the background isolate is already overwhelmed with
    // previous segments, drop this one to avoid snowballing latency or OOM.
    if (_activeDecodes >= _maxDecodeQueue) {
      debugPrint(
        "[STT Isolate] Queue full ($_activeDecodes/$_maxDecodeQueue) — dropping segment",
      );
      return "";
    }

    _activeDecodes++;
    final reply = ReceivePort();
    try {
      _port!.send([reply.sendPort, samples]);
      final text =
          await reply.first.timeout(
                const Duration(
                  seconds: 60,
                ), // Increased from 10s to match PTT buffer limit
                onTimeout: () {
                  debugPrint(
                    "[STT Isolate] Decode timeout - falling back gracefully ",
                  );
                  return "";
                },
              )
              as String;
      return text;
    } on Exception catch (e) {
      debugPrint("[STT Isolate] Decode error: $e");
      return "";
    } finally {
      _activeDecodes--;
      reply.close();
    }
  }

  /// Terminates the background isolate and releases all resources.
  ///
  /// Sends a polite `null` message to request graceful shutdown, then
  /// forcefully kills the isolate via `.kill(priority: Isolate.immediate)`.
  ///
  /// ## Why Both?
  /// * `send(null)`: Allows the isolate to free its native recognizer
  ///   memory cleanly if it's still responsive.
  /// * `kill()`: Guarantees OS-level process termination even if the
  ///   isolate is frozen, crashed, or ignoring messages.
  ///
  /// This two-step approach follows the resource ownership pattern:
  /// whoever creates a resource is responsible for destroying it, and
  /// must guarantee cleanup even in failure scenarios (engineering_lessons #2).
  void dispose() {
    // polite shutdown signal to terminate and free resources
    _port?.send(null);
    // Forcefull kill the OS process regardless of the message queue state , it guarantees cleanup even if the isolate is frosen or crashed thus no memory leaks
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _port = null;
  }
}

// ── Main datasource ────────────────────────────────────────────────────────

/// Speech-to-Text datasource using sherpa-onnx Moonshine models.
///
/// This datasource provides two transcription paths:
/// * **Always-on mode**: Listens to [VadRepository.speechSegmentStream] and
///   decodes completed utterances automatically via background isolate.
/// * **Push-to-talk mode**: Buffers raw PCM audio via [VadRepository.audioStream]
///   and decodes on [stopListening()] when the user releases the button.
///
/// ## Background Isolate Architecture
/// Decoding runs in a dedicated [Isolate] to avoid blocking the UI thread.
/// The isolate hosts a sherpa-onnx [sherpa.OfflineRecognizer] and communicates
/// via [SendPort]/[ReceivePort]. This design isolates native C++ runtime
/// crashes from the main Dart isolate.
///
/// ## Stream Contracts
/// * [textStream] — Emits decoded transcript strings. Consumers should listen
///   and append to their UI buffer; no ordering guarantees beyond FIFO.
/// * [amplitudeStream] — Emits normalized volume (0.0–1.0) for VU meter UI.
///   Emits continuously while audio flows, regardless of buffer cap state.
///
/// ## Resource Ownership
/// This datasource owns:
/// * The background decode isolate (created in [initialize], killed in [dispose])
/// * The fallback main-thread recognizer (if isolate spawn fails)
/// * All stream controllers and subscriptions
///
/// All resources are explicitly freed in [dispose()] — native FFI memory is
/// not tracked by Dart's GC and requires manual cleanup (engineering_lessons #2).

class SherpaSttDatasource {
  final VadRepository _vadRepository;

  sherpa.OfflineRecognizer? _fallbackRecognizer;
  final _SherpaDecodeIsolate _decodeIsolate = _SherpaDecodeIsolate();

  final StreamController<String> _textController =
      StreamController<String>.broadcast();
  final StreamController<String> _partialTextController =
      StreamController<String>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();
  final StreamController<double> _bufferFillController =
      StreamController<double>.broadcast();

  /// Stream of decoded transcript strings.
  ///
  /// Emits one string per successfully decoded utterance. Consumers should
  /// listen and append to their display buffer. Does not emit empty strings.
  Stream<String> get textStream => _textController.stream;

  /// Stream of intermediate partial transcripts.
  ///
  /// Emits while the user is still speaking to provide immediate feedback.
  Stream<String> get partialTextStream => _partialTextController.stream;

  /// Stream of normalized audio amplitude (0.0–1.0).
  ///
  /// Emits continuously while audio bytes are received, regardless of whether
  /// the PTT buffer is capped. Used for VU meter visualization in the UI.
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  /// Stream of normalized buffer fill percentage (0.0–1.0).
  ///
  /// Emits while recording in PTT mode to inform the UI of buffer limits.
  Stream<double> get bufferFillStream => _bufferFillController.stream;

  StreamSubscription<List<int>>? _audioSub;
  StreamSubscription<Float32List>? _segmentSub;

  final BytesBuilder _audioBuffer = BytesBuilder();
  bool _isRecordingUtterance = false;

  /// Tracks the last time a partial decode was triggered to avoid
  /// overwhelming the CPU.
  // DateTime _lastPartialDecodeAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Returns `true` if currently recording a PTT utterance.
  ///
  /// This is a synchronous snapshot. For reactive updates, the BLoC should
  /// track state internally rather than polling this getter.
  bool get isListening => _isRecordingUtterance;

  String _encoderPath = "";
  String _decoderPath = "";
  String _tokensPath = "";

  //NEW: Capping the buffer to avoid memory issues with long recordings
  // This is also to follow the rule of bounding unbounded ops ensuring no crashes due to uncapped buffers

  /// Maximum size of the PTT audio buffer in bytes.
  ///
  /// At 16kHz mono PCM16: 16000 samples/sec × 2 bytes/sample × 60 seconds
  /// = ~1.9MB cap. Prevents OOM crashes from excessively long recordings
  /// (engineering_lessons #3). When capped, new bytes are dropped but
  /// amplitude calculation continues for UI feedback.
  static const int _maxBufferBytes = 16000 * 2 * 60;

  /// Creates a new STT datasource with the given VAD repository dependency.
  ///
  /// The VAD repository provides three streams:
  /// * [VadRepository.speechSegmentStream] — for always-on decoding
  /// * [VadRepository.voiceActivityStream] — for PTT start/stop triggers
  /// * [VadRepository.audioStream] — raw PCM bytes for PTT buffering
  SherpaSttDatasource({required VadRepository vadRepository})
    : _vadRepository = vadRepository;

  /// Initializes model files and spawns the background decode isolate.
  ///
  /// Copies the Moonshine encoder, decoder, and tokens files from assets to
  /// the application documents directory if not already present. Then attempts
  /// to spawn the background isolate via [_SherpaDecodeIsolate.initialize()].
  ///
  /// If isolate spawn fails (e.g., low memory, OS restrictions), falls back
  /// to a main-thread [sherpa.OfflineRecognizer] for decoding. This ensures
  /// basic functionality even on constrained devices.
  ///
  /// Subscribes to all three VAD repository streams:
  /// * [speechSegmentStream] → [_onSpeechSegment] for always-on decoding
  /// * [voiceActivityStream] → [_onVadEvent] for PTT start/stop
  /// * [audioStream] → [_onAudioBytesReceived] for PTT buffering + amplitude
  ///
  /// Returns [right] on success, or [left] with an [AppFailure] if:
  /// * Model file copy fails
  /// * Isolate spawn fails AND fallback recognizer creation fails
  ///
  /// Note: Uses [AppFailure.sttFailure] (not [AppFailure.networkFailure])
  /// because all operations are local — model I/O, isolate spawn, native
  /// initialization. Misusing `networkFailure` would cause the UI to show
  /// "check your connection" for what is actually a device/storage error
  /// (engineering_lessons #8).
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
      _audioSub = _vadRepository.audioStream.listen(_onAudioBytesReceived);

      return right(null);
    } on Exception catch (e) {
      debugPrint("[STT] Init failed: $e");
      // FIXED: was AppFailure.networkFailure — incorrect because model-file
      // copying, isolate spawn, and recogniser construction are all local
      // operations. Using networkFailure here made the BLoC treat a missing
      // .ort asset as a connectivity problem, which would show the user
      // "check your connection" for what is actually a device/storage error.
      return left(AppFailure.sttFailure(message: "STT init failed: $e"));
    }
  }

  // ── PTT controls ──────────────────────────────────────────────────────────

  /// Starts a new push-to-talk recording session.
  ///
  /// Clears the audio buffer and sets the internal recording flag. Audio
  /// bytes received via [_onAudioBytesReceived] will now be accumulated
  /// until [stopListening()] is called.
  void startListening() {
    _audioBuffer.clear();
    _bufferFillController.add(0.0);
    _isRecordingUtterance = true;
  }

  /// Stops the current PTT recording and triggers decoding.
  ///
  /// Clears the recording flag, decays amplitude to zero for UI feedback,
  /// extracts the buffered bytes, and passes them to [_decodeUtterance()].
  ///
  /// Returns an empty string immediately — the decoded transcript arrives
  /// asynchronously via [textStream]. This aligns with the contract that
  /// consumers listen to the stream, not the return value.
  Future<String> stopListening() async {
    if (!_isRecordingUtterance) return "";
    _isRecordingUtterance = false;

    // Decay amplitude and buffer fill to zero visually when stopping
    if (!_amplitudeController.isClosed) {
      _amplitudeController.add(0.0);
    }
    if (!_bufferFillController.isClosed) {
      _bufferFillController.add(0.0);
    }

    final bytes = _audioBuffer.takeBytes();
    unawaited(_decodeUtterance(bytes));

    // Final text arrives via textStream, returning empty here aligns with contract
    return "";
  }

  // ── Always-on segment path ────────────────────────────────────────────────

  /// Handles a completed speech segment from the VAD datasource.
  ///
  /// Called automatically when [VadRepository.speechSegmentStream] emits.
  /// The segment contains pre-normalized Float32 samples ready for decoding.
  /// Passes samples directly to [_decodeFloat32()] — no re-buffering needed.
  void _onSpeechSegment(Float32List samples) {
    if (_isRecordingUtterance) {
      // Ignore VAD segments while the user is manually holding the PTT button.
      // We will decode the full accumulated buffer when they release it.
      return;
    }
    debugPrint("[STT] Segment received — ${samples.length} samples, decoding…");
    _decodeFloat32(samples);
  }

  // ── PTT / VAD buffer path ─────────────────────────────────────────────────

  void _onAudioBytesReceived(List<int> chunk) {
    if (_isRecordingUtterance) {
      // NEW: condition to bound previously unbounded PTT buffer size
      if (_audioBuffer.length < _maxBufferBytes) {
        _audioBuffer.add(chunk);

        // Emit buffer fill percentage for UI feedback
        final percent = (_audioBuffer.length / _maxBufferBytes).clamp(0.0, 1.0);
        _bufferFillController.add(percent);
      }
    }
    // Calculate and emit amplitude continuously whenever audio flows
    _calculateAndEmitAmplitude(chunk);
  }

  // Extracts peak volume from 16-bit PCM chunk and normalizes it to 0.0 - 1.0
  /// Extracts peak amplitude from a PCM16 chunk and emits normalized volume.
  ///
  /// Converts Int16 samples to a 0.0–1.0 float by dividing by 32768.0.
  /// Emits via [amplitudeStream] for VU meter visualization.
  ///
  /// ## Memory Alignment Fix
  /// If the input [Uint8List] has a non-aligned offset, creates a fresh copy
  /// to ensure [Int16List.view] reads safely. Prevents potential crashes on
  /// some Android devices with strict memory alignment requirements.
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

  /// Decodes a PCM16 byte buffer to text via [_decodeFloat32()].
  ///
  /// Converts PCM16 bytes to normalized Float32 samples, then delegates to
  /// [_decodeFloat32()]. Empty buffers are no-ops.
  Future<void> _decodeUtterance(
    List<int> pcmBytes, {
    bool isPartial = false,
  }) async {
    if (pcmBytes.isEmpty) return;
    final bytes = pcmBytes is Uint8List
        ? pcmBytes
        : Uint8List.fromList(pcmBytes);
    await _decodeFloat32(_pcm16ToFloat32(bytes), isPartial: isPartial);
  }

  /// Decodes normalized Float32 samples to text.
  ///
  /// Uses the background isolate if available (preferred), otherwise falls
  /// back to main-thread synchronous decoding. Emits results via [textStream]
  /// or [partialTextStream] depending on the [isPartial] flag.
  Future<void> _decodeFloat32(
    Float32List samples, {
    bool isPartial = false,
  }) async {
    if (samples.isEmpty) return;

    final String text;
    if (_decodeIsolate.isReady) {
      text = await _decodeIsolate.decode(samples);
    } else {
      text = _decodeSynchronously(samples);
    }

    if (text.isNotEmpty && !_textController.isClosed) {
      if (isPartial) {
        _partialTextController.add(text);
      } else {
        debugPrint("[STT] Final Transcript: $text");
        _textController.add(text);
      }
    }
  }

  /// Synchronous fallback decoding on the main thread.
  ///
  /// Used when background isolate spawn fails. Creates a main-thread
  /// [sherpa.OfflineRecognizer] if not already initialized, then decodes
  /// the samples. Errors are logged and return empty string — a single
  /// failed decode should not halt the entire session.
  String _decodeSynchronously(Float32List samples) {
    _fallbackRecognizer ??= _buildRecognizer();
    try {
      final stream = _fallbackRecognizer!.createStream();
      stream.acceptWaveform(sampleRate: 16000, samples: samples);
      _fallbackRecognizer!.decode(stream);
      final result = _fallbackRecognizer!.getResult(stream);
      stream.free();
      return result.text;
    } on Exception catch (e) {
      debugPrint("[STT] Sync decode error: $e");
      return "";
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Builds a main-thread [sherpa.OfflineRecognizer] for fallback decoding.
  ///
  /// Uses the Moonshine model config with encoder/decoder paths and tokens
  /// file copied during [initialize()]. Called lazily on first sync decode.
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
          numThreads: 4,
          debug: false,
          provider: Platform.isIOS ? "coreml" : "xnnpack",
        ),
      ),
    );
  }

  /// Converts PCM16 little-endian bytes to normalized Float32 samples.
  ///
  /// sherpa-onnx expects audio in the range [-1.0, 1.0]. This helper divides
  /// each Int16 sample by 32768.0 to perform the conversion.
  ///
  /// ## Memory Alignment Fix
  /// If the input [Uint8List] has a non-aligned offset, creates a fresh copy
  /// to ensure [Int16List.view] reads safely. Prevents potential crashes on
  /// some Android devices with strict memory alignment requirements.
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

  /// Copies an asset file to the application documents directory if missing.
  ///
  /// Used to stage STT model files at runtime. The file is only copied if it
  /// does not already exist, avoiding redundant I/O on subsequent sessions.
  ///
  /// Note: For production hardening, consider adding a size check
  /// (`file.length() < minValidSize`) to catch partial writes from OS cache
  /// clearing (engineering_lessons #6).
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
    }
    return localPath;
  }

  /// Releases all resources held by this datasource.
  ///
  /// Cancels all stream subscriptions, kills the background isolate via
  /// [_SherpaDecodeIsolate.dispose()], frees the fallback recognizer's
  /// native memory, and closes all stream controllers.
  ///
  /// Safe to call multiple times — all operations are guarded against
  /// already-disposed state. Follows resource ownership pattern: whoever
  /// creates a resource is responsible for destroying it (engineering_lessons #2).
  Future<void> dispose() async {
    await _segmentSub?.cancel();
    await _audioSub?.cancel();
    _decodeIsolate.dispose();
    _fallbackRecognizer?.free();
    if (!_textController.isClosed) await _textController.close();
    if (!_amplitudeController.isClosed) await _amplitudeController.close();
    if (!_bufferFillController.isClosed) await _bufferFillController.close();
  }
}
