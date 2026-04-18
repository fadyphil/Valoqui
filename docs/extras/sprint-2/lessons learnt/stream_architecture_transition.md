# Valoqui: Stream Architecture Transition (Zero to Hero)

This document chronicles the architectural evolution of **Valoqui (Lingua)** from a sequential, blocking system to a high-performance, reactive stream-based pipeline. 

As a software engineer, mastering this transition is the difference between building a "toy" application that works in a lab and a "production-grade" system that handles real-time audio, native threading, and hardware constraints.

---

## 1. The Problem: Latency, Jitter, and "The Robot Feel"

In the initial prototype (Sprint 0), the conversation flow was linear:
1. **User stops speaking.**
2. **STT starts decoding** (UI freezes for 500ms because decoding is CPU-intensive).
3. **STT finishes.**
4. **LLM request sent** (Wait 2 seconds for the full response).
5. **TTS starts synthesizing** (Wait 1 second for the full audio file).
6. **Audio plays.**

**Total Latency:** ~4.0 seconds.  
**User Experience:** Feels disjointed, robotic, and frustrating.

---

## 2. Phase 1: The Background Isolate (STT)

### The Theory
Dart is single-threaded. Heavy CPU tasks like audio decoding (Moonshine/Sherpa) block the event loop, causing dropped frames (jank). To solve this, we moved decoding to a dedicated **Background Isolate**.

### Expert Insight: Guaranteed Resource Cleanup
Many developers use `Isolate.spawn` but forget that isolates are separate OS-level processes. If an isolate hangs, it becomes a **Zombie Process**, leaking memory every session.

#### The Transformation (SherpaSttDatasource)

**Before (Sequential/Blocking):**
```dart
Future<String> decode(Float32List samples) async {
  // Runs on the main thread — UI blocks here!
  return _recognizer.decode(samples); 
}
```

**After (Reactive Isolate):**
We implemented a **Two-Step Termination** strategy.
1. **Polite Signal:** Send `null` to the port so the isolate can free native FFI memory.
2. **Forceful Kill:** Call `_isolate.kill()` to ensure the OS process is destroyed even if it's frozen.

```dart
// lib/core/data/datasources/sherpa_stt_datasource.dart

void dispose() {
  _port?.send(null); // 1. Polite request to clean up native memory
  _isolate?.kill(priority: Isolate.immediate); // 2. Forceful OS kill
  _isolate = null;
}
```

---

## 3. Phase 2: Sentence-Boundary TTS (The Latency Killer)

### The Theory
Humans don't wait for a person to finish their 100-word paragraph before they understand the first sentence. By identifying **sentence boundaries** (`.`, `?`, `!`) in the incoming LLM token stream, we can start TTS playback while the LLM is still "thinking" of the next sentence.

### The Transformation (SpeakingBloc)

We track `_ttsSpokenLength` to ensure we never re-speak text that has already been sent to the TTS engine.

```dart
// lib/features/speaking/bloc/speaking_bloc.dart

void _onLlmTokenReceived(_LlmTokenReceived event, Emitter<SpeakingState> emit) {
  final fullText = _currentBuffer + event.token;
  
  // Only search the NEW part of the buffer
  final boundary = _findFirstSentenceBoundary(
    fullText.substring(_ttsSpokenLength),
  );
  
  if (boundary != -1) {
    // Extract the complete sentence
    final sentence = fullText.substring(
      _ttsSpokenLength, 
      _ttsSpokenLength + boundary + 1,
    );
    
    // Trigger TTS immediately for this segment!
    _tts.speak(sentence); 
    
    // Move the pointer forward
    _ttsSpokenLength += sentence.length;
  }
}
```

---

## 4. Phase 3: WAV Rotation & Cache Bypassing (TTS)

### The Theory
Mobile audio players (`just_audio`) are aggressive about caching. If you synthesize speech into `lucia.wav` and then overwrite it with a new sentence, the player might still play the *old* audio because the file path (the URI) hasn't changed.

### The Transformation (SherpaTtsDatasource)

We implemented a **Slot Rotation Strategy**. By alternating between `lucia_0.wav` and `lucia_1.wav`, we guarantee the URI is unique for consecutive sentences, bypassing the cache.

```dart
// lib/core/data/datasources/sherpa_tts_datasource.dart

Future<void> _playSingleSentence(String text) async {
  // Alternate index: 0, 1, 0, 1...
  final wavPath = "${tmpDir.path}/lucia_speech_${_wavIndex % 2}.wav";
  _wavIndex++;

  // Synthesize to the new path
  _tts!.generate(text: text, ...);
  
  // Explicitly reset player state
  await _player.stop();
  await _player.setFilePath(wavPath);
  await _player.seek(Duration.zero);
  await _player.play();
}
```

---

## 5. The "Hero" Engineering Checklist

When moving to a stream-based architecture, apply these **Golden Rules**:

### 1. The Alignment Guard (Native Stability)
When dealing with `Int16List.view` or `Float32List.view` (common in audio), if the `Uint8List` offset is not a multiple of 2 or 4, the app will **crash on Android** with an alignment error. Always check and copy if necessary.
```dart
final bytes = rawBytes.offsetInBytes % 2 == 0 
  ? rawBytes 
  : Uint8List.fromList(rawBytes); // Create aligned copy
```

### 2. Bounding the Unbounded (Memory Safety)
Streams are infinite. Buffers are not. If a user leaves Push-to-Talk on for an hour, your app will crash with **OOM (Out of Memory)**. Always cap your buffers.
```dart
static const int _maxBufferBytes = 16000 * 2 * 60; // 60 seconds cap
if (_audioBuffer.length < _maxBufferBytes) {
  _audioBuffer.add(chunk);
}
```

### 3. Stream-to-Event Mapping (BLoC Integrity)
Never `emit()` inside a stream listener. It violates the BLoC pattern and causes runtime errors in `flutter_bloc ^9.0`. Always add an event.
```dart
_sub = stream.listen((data) => add(_DataReceived(data))); // RIGHT
_sub = stream.listen((data) => emit(NewState(data)));    // WRONG
```

### 4. Semantic Error Tiers
Distinguish between **Business Errors** (LLM Rate Limit) and **Infrastructure Errors** (Native Isolate Timeout). 
* Rate limits → Tell the user to wait.
* Isolate Timeout → Silently restart the isolate or fallback to PTT.

---

## Summary
The Valoqui transition was not just about "adding streams"; it was about building a **fault-tolerant, asynchronous state machine**. By isolating heavy tasks, bypassing caches, and using event-driven logic, we reduced perceived latency from **4s to <500ms**.
