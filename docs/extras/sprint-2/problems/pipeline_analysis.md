# Pipline Analysis

I've completed a deep analysis of the entire STT/VAD/TTS/LLM pipeline. Here are my findings organized by severity:

---
Pipeline Analysis — Valoqui Audio Pipeline
Architecture Overview
The pipeline flows: Mic → VAD (Silero) → STT (Sherpa-ONNX Moonshine) → SpeakingBloc → LLM (Groq→Gemini fallback) → TTS (Sherpa-ONNX Piper) → Speaker
Three modes of operation:

1. Always-on: VAD detects speech segments → emits Float32 samples → STT decodes → transcript
2. Push-to-Talk: Button press starts mic buffering → button release triggers decode
3. Fallback: If VAD model fails to load, session defaults to PTT

---

## CRITICAL ISSUES

## 1. Isolate Decode Has No Timeout — Permanent Hang Risk

File: lib/core/data/datasources/sherpa_stt_datasource.dart:104-111

```dart
Future<String> decode(Float32List samples) async {
  if (!isReady) return "";
  final reply = ReceivePort();
  _port!.send([reply.sendPort, samples]);
  final text = await reply.first as String;  // ← HANGS FOREVER if isolate dies
  reply.close();
  return text;
}
```

---

## Why it's a problem

If the background isolate crashes after initialization (e.g., OOM from model memory, native crash in Sherpa-ONNX), reply.first will never resolve. The entire STT pipeline freezes — stopListening() calls _decodeUtterance() which awaits_decodeFloat32() which awaits this. The user sees an infinite spinner with no recovery path.
Fix: Add a timeout with graceful fallback to synchronous decoding:

```dart
Future<String> decode(Float32List samples) async {
  if (!isReady) return "";
  final reply = ReceivePort();
  try {
    _port!.send([reply.sendPort, samples]);
    final text = await reply.first.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint("[STT Isolate] Decode timed out — falling back to sync");
        return "";
      },
    ) as String;
    reply.close();
    return text;
  } catch (e) {
    debugPrint("[STT Isolate] Decode error: $e");
    reply.close();
    return "";
  }
}
```

---

## 2. Isolate Is Never Explicitly Killed on Dispose — Zombie Process

**File: lib/core/data/datasources/sherpa_stt_datasource.dart:113-116**

```dart
void dispose() {
  _port?.send(null);
  _port = null;
}
```

## Why it's a problem

This sends a null signal to the isolate, which causes the isolate to close its ReceivePort and free the recognizer. However, the Isolate object itself is never killed via Isolate.kill(). If the isolate's message loop is blocked (e.g., mid-decode), the null message sits in the queue unprocessed, and the isolate process persists as a zombie consuming memory.
Fix: Store the Isolate reference and kill it explicitly:

```dart
class _SherpaDecodeIsolate {
  SendPort? _port;
  Isolate? _isolate;  // ← ADD THIS
  bool get isReady => _port != null;
  Future<bool> initialize(...) async {
    final handshake = ReceivePort();
    try {
      _isolate = await Isolate.spawn(...);  // ← CAPTURE REFERENCE
      // ...
    }
  }
  void dispose() {
    _port?.send(null);
    _isolate?.kill(priority: Isolate.immediate);  // ← FORCE KILL
    _isolate = null;
    _port = null;
  }
}
```

---

## 3. VAD VoiceActivityDetector Native Memory Never Freed

**File: lib/core/data/datasources/sherpa_vad_datasource.dart:166-178**

```dart
Future<void> dispose() async {
  await stopMonitoring();
  try {
    await _recorder.dispose();
  } catch (e) { ... }
  // ← _vad.free() is NEVER called
  if (!_vadController.isClosed) await _vadController.close();
  // ...
}
```

## Why it's a problem

sherpa.VoiceActivityDetector wraps native ONNX runtime memory (Silero VAD model ~1MB+). The Sherpa-ONNX API provides a .free() method (same pattern as OfflineRecognizer.free() used in the STT isolate). Without calling it, native memory leaks across session lifecycles. Since SpeakingBloc is route-scoped (fresh BLoC per session), each new speaking session creates a new VAD instance that leaks the previous one.

Fix:

```dart
Future<void> dispose() async {
  await stopMonitoring();
  _vad?.free();  // ← ADD THIS
  _vad = null;
  try {
    await _recorder.dispose();
  } catch (e) { ... }
  // ...
}
```

---

## 4. Unbounded Audio Buffer in PTT Mode — OOM Risk

**File: lib/core/data/datasources/sherpa_stt_datasource.dart:139**

```dart
final BytesBuilder _audioBuffer = BytesBuilder();
```

## Why it's a problem

In PTT mode, if the user holds the mic button for an extended period (e.g., 5+ minutes), the BytesBuilder grows unboundedly. At 16kHz mono PCM16, that's 32KB/second — a 5-minute hold = ~9.6MB. While not catastrophic for a single session, this is unbounded growth with no cap. On low-memory devices, this could trigger OOM.
Fix: Add a maximum buffer duration (e.g., 60 seconds) and truncate:

```dart
static const int _maxBufferBytes = 16000 * 2 * 60; // 16kHz * 2 bytes * 60s = ~1.9MB
void _onAudioBytesReceived(List<int> chunk) {
  if (_isRecordingUtterance) {
    if (_audioBuffer.length < _maxBufferBytes) {
      _audioBuffer.add(chunk);
    }
    // Silently drop excess — better than OOM
  }
  _calculateAndEmitAmplitude(chunk);
}
```

---

## HIGH SEVERITY

## 5. Direct Service Locator Access in UI — BLoC Pattern Violation

**File: lib/features/speaking/screens/speaking_screen.dart:236-241**

```dart
Stream<double>? ampStream;
try {
  ampStream = sl<SttRepository>().amplitudeStream;  // ← DIRECT sl ACCESS
} catch (_) {}
```

Why it's a problem: This bypasses the BLoC pattern entirely. The UI reaches directly into the service locator instead of receiving data through the BLoC state. This makes the amplitude stream untestable (widget tests can't mock it), creates a hidden dependency, and violates the architectural principle that screens should only know about their BLoC.
Fix: Expose amplitude through SpeakingState:

```dart
// In SpeakingState:
@freezed
sealed class SpeakingState with _$SpeakingState {
  const factory SpeakingState.active({
    // ... existing fields ...
    @Default(0.0) double amplitude,  // ← ADD
  }) = SpeakingActive;
}
// In SpeakingBloc constructor, subscribe and emit:
_stt.amplitudeStream.listen((amp) {
  final current = state;
  if (current is SpeakingActive) {
    emit(current.copyWith(amplitude: amp));
  }
});
// In SpeakingScreen:
SpeakingWaveform(
  phase: state.phase,
  amplitude: state is SpeakingActive ? state.amplitude : 0.0,
),
```

---

## 6. _drainQueue() Is Fire-and-Forget — Concurrent Speak Calls Race

**File: lib/core/data/datasources/sherpa_tts_datasource.dart:98-107**

```dart
Future<Either<AppFailure, void>> speak(String text) async {
  if (!_initialized || _tts == null) {
    return left(const AppFailure.ttsNotInitialized());
  }
  _speechQueue.add(text);
  if (!_isDrainingQueue) {
    _drainQueue(); // ← fire-and-forget, no await
  }
  return right(null);
}
```

---
Why it's a problem: When the LLM streams tokens and sentence boundaries are detected in _onLlmTokenReceived, multiple_tts.speak(sentence) calls fire in rapid succession. The first call starts _drainQueue() as fire-and-forget. If a second speak() is called before_isDrainingQueue is set to true (which happens at the top of _drainQueue() on the next microtask), a second_drainQueue() could start, creating two concurrent drain loops both reading from the same _speechQueue. This causes removeAt(0) race conditions.
Fix: Make the queue drain trigger synchronous:

```dart
Future<Either<AppFailure, void>> speak(String text) async {
  if (!_initialized || _tts == null) {
    return left(const AppFailure.ttsNotInitialized());
  }
  _speechQueue.add(text);
  if (!_isDrainingQueue) {
    _isDrainingQueue = true;  // ← SET SYNCHRONOUSLY BEFORE ASYNC
    _drainQueue();
  }
  return right(null);
}
Future<void> _drainQueue() async {
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
```

---

## 7. LLM Stream Subscription Has No Error Handler

**File: lib/features/speaking/bloc/speaking_bloc.dart:226-238**

```dart
void _streamLlmResponse() {
  _llm
      .streamResponse(messages: List.from(_history), systemPrompt: LuciaPrompt.build(_userCefrLevel))
      .listen(
        (event) => event.fold(
          (failure) => add(_LlmError(failure)),
          (token) => add(_LlmTokenReceived(token)),
        ),
        onDone: () => add(const _LlmResponseComplete()),
        // ← NO onError handler
      );
}
```

---

## Why it's a problem

The Either<AppFailure, String> pattern handles business-logic errors correctly. But if the stream itself emits an error event (e.g., an unhandled exception in the Groq/Gemini datasource that bypasses the Either wrapper), the subscription throws an unhandled error. This crashes the BLoC silently without transitioning to an error state.
Fix:

```dart
void _streamLlmResponse() {
  _llm
      .streamResponse(...)
      .listen(
        (event) => event.fold(
          (failure) => add(_LlmError(failure)),
          (token) => add(_LlmTokenReceived(token)),
        ),
        onDone: () => add(const _LlmResponseComplete()),
        onError: (error) => add(
          _LlmError(AppFailure.llmFailure(message: "Unexpected LLM error: $error")),
        ),
      );
}
```

---

## MEDIUM SEVERITY

## 8. VAD Emits true Then false Back-to-Back — Misleading Timing

**File: lib/core/data/datasources/sherpa_vad_datasource.dart:133-135**

```dart
if (!_vadController.isClosed) {
  _vadController.add(true);  // speech was detected
  _vadController.add(false); // silence followed — utterance complete
}
```

## Why it's a problem

Both events fire synchronously in the same callback. Consumers see them as two separate stream events in the same microtask. The voiceActivityStream is documented as being for "active-speaking-time tracking," but since true and false arrive simultaneously, the elapsed time between them is always ~0ms. The BLoC works around this by tracking _speechStartTime at the_VoiceActivityChanged handler level, but any future consumer that expects real-time speech onset/offset will be confused.
Fix: Only emit false (utterance complete). The timing is tracked by the BLoC via _speechStartTime. Or better, emit a single domain event:

```dart
// Option A: Only emit completion
_vadController.add(false); // utterance complete
// Option B: Emit a single event type with duration
// Would require changing Stream<bool> to Stream<VadEvent>
```

---

## 9. _deliverPrecannedGreeting Dispatches Events Synchronously

**File: lib/features/speaking/bloc/speaking_bloc.dart:428-441**

```dart
void _deliverPrecannedGreeting() {
  const greeting = "¡Hola! ...";
  final current = state;
  if (current is SpeakingActive) {
    add(_LlmTokenReceived(greeting));       // ← sync event dispatch
    add(const _LlmResponseComplete());       // ← sync event dispatch
  } else {
    // ...
  }
}
```

## Why it's a problem

Two events are dispatched synchronously via add(). If the BLoC's event queue has any backlog, these could be processed interleaved with other events. The else branch correctly uses Future.microtask (line 439), but the if branch does not. This is currently safe because _deliverPrecannedGreeting is called at the end of_onSessionStarted when the queue is empty, but it's a fragile invariant.
Fix: Use Future.microtask for consistency:

```dart
void _deliverPrecannedGreeting() {
  const greeting = "¡Hola! ...";
  final current = state;
  if (current is SpeakingActive) {
    Future.microtask(() {
      add(_LlmTokenReceived(greeting));
      add(const _LlmResponseComplete());
    });
  } else {
    // ...
  }
}
```

---

## 10. STT Uses AppFailure.networkFailure for Non-Network Errors

**File: lib/core/data/datasources/sherpa_stt_datasource.dart:183**

```dart
return left(AppFailure.networkFailure(message: "STT init failed: $e"));
```

And similarly in **sherpa_vad_datasource.dart:80**:

```dart
return left(AppFailure.networkFailure(message: "VAD init failed: $e"));
```

## Why it's a problem

STT/VAD initialization failures are local (model loading, file I/O, native library issues) — not network errors. Using networkFailure misrepresents the error domain and makes it impossible for the UI to show an appropriate error message. The AppFailure model already has sttFailure and dedicated variants.
Fix:

```dart
// STT datasource:
return left(AppFailure.sttFailure(message: "STT init failed: $e"));
// VAD datasource:
return left(AppFailure.sttFailure(message: "VAD init failed: $e"));
```

---

## 11. Model Files Can Be Deleted by OS — No Re-validation

File: **lib/core/data/datasources/sherpa_stt_datasource.dart:348-363**

```dart
Future<String> _copyAssetToLocal(String assetPath) async {
  final docDir = await getApplicationDocumentsDirectory();
  final localPath = "${docDir.path}/$assetPath";
  final file = File(localPath);
  if (!await file.exists()) {
    // copies...
  }
  return localPath;
}
```

## Why it's a problem

The OS can clear the documents directory on low storage. The exists() check only runs at copy time. If the model files are deleted after first launch but before recognizer creation (or between sessions), the cached paths point to non-existent files. The recognizer will crash when it tries to load a missing .ort file.
Fix: Validate file existence and size before passing to the recognizer:

```dart
Future<String> _copyAssetToLocal(String assetPath) async {
  final docDir = await getApplicationDocumentsDirectory();
  final localPath = "${docDir.path}/$assetPath";
  final file = File(localPath);
  // Re-copy if file is missing OR suspiciously small (corrupted)
  if (!await file.exists() || (await file.length()) < 100) {
    await file.parent.create(recursive: true);
    final byteData = await rootBundle.load(assetPath);
    await file.writeAsBytes(
      byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      flush: true,
    );
  }
  return localPath;
}
```

---

### LOW SEVERITY / CODE QUALITY

#### 12. Duplicate Comment in STT Datasource

**File:** `sherpa_stt_datasource.dart:237-238` — comment appears twice consecutively.

#### 13. Dead Code in VAD Datasource

**File:** `sherpa_vad_datasource.dart:183-191` — commented-out `Int16List.view` approach should be removed.

#### 14. Commented-Out Android STT Code Throughout

Legacy `AndroidSttDatasource` and `AndroidSttRepository` files plus commented-out registrations in `service_locator.dart` should be deleted or moved to an `archive/` directory.

#### 15. `SttRepository` Interface Mismatch — `stopListening()` Always Returns Empty

**File:** `sherpa_stt_datasource.dart:207` — `stopListening()` always returns `""` with the comment "Final text arrives via textStream." The repository interface declares `Future<Either<AppFailure, String>> stopListening()` but the caller (SpeakingBloc) ignores the return value entirely. The interface should either be `Future<void>` or the implementation should actually return the transcript

---

ARCHITECTURAL OBSERVATIONS

1. Cross-layer dependency: SherpaSttDatasource depends on VadRepository (a domain interface). This is architecturally unusual — a datasource (data layer) depending on a repository (domain layer). The VAD repository is used to subscribe to VAD streams. A cleaner approach would be for the datasource to depend on a VadDatasource instead, keeping both in the data layer.
2. SpeakingBloc is a God Object: At 475 lines, it orchestrates STT, VAD, LLM, TTS, session timing, transcript management, and phase transitions. Consider extracting the LLM+TTS pipeline into a separate ConversationOrchestrator use case or service.
3. Route-scoped BLoCs share singleton datasources: SpeakingBloc is a factory (fresh per route), but the underlying datasources (STT, TTS, VAD) are lazy singletons. When SpeakingBloc.close() disposes all datasources, the next session's BLoC gets disposed datasources. This works because go_router pops the speaking route before navigating to report, but it's fragile — navigating back to speaking would fail.
