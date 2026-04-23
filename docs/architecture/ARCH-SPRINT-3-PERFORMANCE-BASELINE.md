# Pipeline Performance Analysis

**Date:** April 2026  
**Author:** Documentation & Code Review  
**Context:** Sprint 3 is planned but not yet in development. This analysis reviews the current STT→LLM→TTS pipeline for performance bottlenecks.

---

## 1. Current Pipeline Architecture

### 1.1 Pipeline Flow

```
[Microphone] → [VAD (Silero/sherpa-onnx)] → [STT (Moonshine/sherpa-onnx)]
                                                           ↓
                                                      [Transcript]
                                                           ↓
[LLM Stream] ← [Groq LLaMA 3.3 70B + Gemini fallback]
   ↓
[Tokens arrive] → [Sentence boundary detected] → [TTS (Piper/sherpa-onnx)] → [Speaker]
```

### 1.2 Actual Implementation Components

| Component | Implementation | Location |
|-----------|---------------|----------|
| VAD | `SherpaVadDatasource` (Silero) | `lib/core/data/datasources/sherpa_vad_datasource.dart` |
| STT | `SherpaSttDatasource` (Moonshine) | `lib/core/data/datasources/sherpa_stt_datasource.dart` |
| LLM | `GroqLlmDatasource` → `GroqLlmRepository` | `lib/core/data/datasources/groq_llm_datasource.dart` |
| TTS | `SherpaTtsDatasource` (Piper VITS) | `lib/core/data/datasources/sherpa_tts_datasource.dart` |
| Orchestration | `SpeakingBloc` | `lib/features/speaking/bloc/speaking_bloc.dart` |

### 1.3 Current Processing Model

**Sequential (no overlap between stages):**

1. **Recording**: VAD monitors mic, detects speech end
2. **STT Decode**: Full utterance decoded in background isolate (~2-4s measured)
3. **LLM Request**: Transcript sent to Groq, tokens stream back
4. **TTS Synthesis**: After LLM completes (or sentence boundary), TTS speaks

**Problem**: Each stage waits for the previous to fully complete.

---

## 2. Identified Performance Bottlenecks

### 2.1 Bottleneck #1: TTS Cold Start

**Location:** `SherpaTtsDatasource.initialize()` (line 116-151)

**Issue:** TTS engine is initialized once at session start but is NOT warmed up before first use. The first `speak()` call triggers:

1. Model loading (if not cached)
2. First synthesis pass
3. Player preparation

**Impact:** First sentence has额外 500-2000ms delay before audio plays.

**Current State:** No `warmUp()` method exists. TTS starts cold every session.

**Evidence:**

```dart
// SherpaTtsDatasource - no warmUp() method
// speak() is the first interaction with the engine
Future<Either<AppFailure, void>> speak(String text) async {
  if (!_initialized || _tts == null) {
    return left(const AppFailure.ttsNotInitialized());
  }
  // ... starts immediately, no warm-up
}
```

**Fix Required:** Add `warmUp()` method that pre-loads model and runs a silent synthesis pass.

---

### 2.2 Bottleneck #2: No LLM→TTS Pipelining

**Location:** `SpeakingBloc` - token processing

**Issue:** The LLM tokens arrive and are buffered. TTS only starts after:

- A sentence boundary is detected (`.`, `?`, `!`)
- AND the LLM stream has yielded enough tokens to form a sentence

**Current Flow:**

```
LLM: "Hola, ¿cómo estás?" ---tokens stream in--->
                                              ↓
                              BLoC detects "?" → triggers TTS
                                                          ↓
                              TTS: generate → write WAV → play
```

**Problem:** TTS warm-up and first synthesis happen AFTER the sentence boundary is detected, adding latency.

**Evidence (SpeakingBloc token handling):**

```dart
// Tokens stream in, buffer accumulates
_buffer.write(token);
if (_isSentenceEnd(token)) {
  final text = _buffer.toString();
  _buffer.clear();
  await _tts.speak(text);  // TTS starts HERE
}
```

**Fix Required:** Pre-warm TTS during LLM generation (while tokens are still streaming), then trigger synthesis immediately on sentence boundary.

---

### 2.3 Bottleneck #3: TTS Sequential Synthesis

**Location:** `SherpaTtsDatasource._drainQueue()` (line 194-211)

**Issue:** Each sentence is synthesized fully before the next one starts. For multi-sentence responses:

```
Sentence 1: [generate 500ms] → [write 50ms] → [play 2s]
Sentence 2:                               [generate 500ms] → [write 50ms] → [play 2s]
                                                     ↑
                                           Must wait for play() to complete
```

**Problem:** The `await _player.play()` (line 250) blocks the queue drain until playback finishes. This means:

- If sentence 1 is 3 seconds of audio, sentence 2 synthesis doesn't even START until 3s mark
- Gap between sentences = synthesis time (not overlapped)

**Evidence:**

```dart
// Line 250 - blocks until playback completes
await _player.play(); // resolves when this sentence finishes

// Then loop continues to next sentence
while (_speechQueue.isNotEmpty) {
  final text = _speechQueue.removeAt(0);
  await _playSingleSentence(text);  // Next sentence ONLY starts here
}
```

**Fix Required:** Implement parallel synthesis:

1. While sentence N is playing, pre-synthesize sentence N+1
2. Queue the pre-synthesized audio, play immediately when ready

---

### 2.4 Bottleneck #4: STT→LLM Sequential Handoff

**Location:** `SpeakingBloc._onTranscriptReceived()`

**Issue:** LLM cannot start until STT fully completes the transcript. For long utterances:

```
User speaks: "Buenos días, me gustaría practicar mi español..."
                                    ↓
                      [VAD detects end of speech]
                                    ↓
                      [STT decodes full utterance] --- 2-4s ---
                                    ↓
                      [LLM receives full transcript]
                                    ↓
                      [LLM first token] --- 100-200ms ---
```

**Problem:** STT and LLM could theoretically overlap - as soon as STT produces partial transcript, LLM could start generating. Currently no partial transcript support.

**Evidence:** `SherpaSttDatasource.textStream` only emits FULL transcripts, not partials.

**Fix Required:** Implement streaming/chunked STT to emit partial transcripts, allowing LLM to start earlier.

---

### 2.5 Bottleneck #5: Isolate Communication Overhead

**Location:** `SherpaSttDatasource._SherpaDecodeIsolate` (lines 104-243)

**Issue:** Decode requests go through `SendPort`/`ReceivePort` with 10s timeout. For every decode:

1. Serialize `Float32List` (potentially 480KB for 3s audio at 16kHz)
2. Send to isolate
3. Isolate processes
4. Deserialize result
5. Return via port

**Evidence:**

```dart
// Line 200-201: Data serialization round-trip
_port!.send([reply.sendPort, samples]);
final text = await reply.first.timeout(...);
```

**Fix Required:** For very short utterances (<1s), the overhead of isolate communication may exceed the actual decode time. Consider:

- Short-circuit for very small buffers (decode inline)
- Use `TransferableTypedData` for zero-copy transfer where possible

---

### 2.6 Bottleneck #6: VAD numThreads=1

**Location:** `SherpaVadDatasource` (line 123)

**Issue:** VAD runs with only 1 thread. Audio processing is single-threaded despite having access to more cores.

**Evidence:**

```dart
// Line 123 - numThreads: 1
numThreads: 1,
debug: false,
provider: "cpu",
```

**Fix Required:** Increase to 2-4 threads for VAD processing to reduce latency.

---

### 2.7 Bottleneck #7: STT numThreads=2 (Could Be Higher)

**Location:** `_sherpaIsolateEntry` (line 44)

**Issue:** STT decoder uses 2 threads. On modern mid-range Android (6+ cores), this could safely increase to 4.

**Evidence:**

```dart
// Line 44
numThreads: 2,
```

**Fix Required:** Benchmark with 4 threads on target devices. May need to be adaptive based on device tier.

---

## 3. Performance Metrics Summary

### 3.1 Current Latency Breakdown (Estimated)

| Stage | Duration | Cumulative |
|-------|----------|------------|
| VAD detection | ~0ms (continuous) | 0ms |
| User speaks (3s utterance) | ~3000ms | 3000ms |
| VAD silence detection | ~800ms (minSilenceDuration) | 3800ms |
| STT decode (isolate) | ~2000ms | 5800ms |
| LLM first token | ~150ms | 5950ms |
| TTS warm-up (first use) | ~500ms | 6450ms |
| TTS synthesis (first sentence) | ~500ms | 6950ms |
| TTS playback starts | ~50ms | 7000ms |

**Total to first audio playback:** ~7 seconds for a 3-second utterance.

### 3.2 Target (Sprint 3 Goals)

| Metric | Current | Target |
|--------|---------|--------|
| End-to-end latency | ~7s | <1.5s |
| Time to first partial | N/A | <500ms |
| TTS time-to-first-audio | ~1200ms | <200ms |

---

## 4. Recommended Fixes (Priority Order)

### 4.1 Priority 1: TTS Warm-Up (Easy Win)

**Impact:** Eliminates 500-2000ms cold start  
**Effort:** Low (1 day)

```dart
// Add to SherpaTtsDatasource
Future<void> warmUp() async {
  if (!_initialized) return;
  // Pre-synthesize a silent/near-silent sentence
  // This forces model loading and first-time initialization
  await _tts!.generate(text: " ", sid: 0, speed: 1.0);
}
```

**Call site:** In `SpeakingBloc`, call `tts.warmUp()` when entering `speaking` state, before user starts talking.

---

### 4.2 Priority 2: TTS Parallel Synthesis (Medium Effort)

**Impact:** Eliminates inter-sentence gap latency  
**Effort:** Medium (2-3 days)

Modify `_drainQueue()` to:

1. Pre-synthesize next sentence while current one plays
2. Use a double-buffer approach for audio data
3. Start playback of pre-synthesized audio immediately when current sentence ends

---

### 4.3 Priority 3: LLM→TTS Warm-Up Pipelining (Medium Effort)

**Impact:** Overlaps TTS init with LLM generation  
**Effort:** Medium (2 days)

**Current:**

```
LLM streams tokens... → detects sentence end → TTS speak()
                      ↑
                      This could warm up TTS while LLM generates
```

**Fix:** When LLM starts streaming, fire-and-forget `tts.warmUp()`. By the time first sentence boundary is hit, TTS is already ready.

---

### 4.4 Priority 4: Chunked/STT Streaming (High Effort)

**Impact:** Enables partial transcripts, reduces perceived latency  
**Effort:** High (Sprint 3 main goal)

This is the primary Sprint 3 goal - see ADR-011, ADR-012, and ARCH-101.

---

### 4.5 Priority 5: Thread Count Tuning (Low Effort)

**Impact:** 10-20% improvement in STT/VAD latency  
**Effort:** Low (1 day benchmarking)

Increase `numThreads` for both VAD and STT decoders. Test on 3 device tiers.

---

## 5. Clean Architecture Violations Found

### 5.1 VadRepository Dependency in STT Datasource

**Location:** `SherpaSttDatasource` constructor (line 333)

```dart
SherpaSttDatasource({required VadRepository vadRepository})
    : _vadRepository = vadRepository;
```

**Issue:** `SherpaSttDatasource` is a datasource, but datasources should only deal with external systems (APIs, hardware). Depending on `VadRepository` (a domain interface) violates the layer contract.

**Impact:** Harder to test, hidden coupling, violates ADR-005 clean architecture principle.

**Fix:** Both VAD and STT should be initialized and owned by the BLoC/Orchestrator, which coordinates them.

---

## 6. Files to Modify

| File | Change | Priority |
|------|--------|----------|
| `lib/core/data/datasources/sherpa_tts_datasource.dart` | Add `warmUp()` method | P1 |
| `lib/core/data/datasources/sherpa_vad_datasource.dart` | Increase `numThreads` to 2 | P5 |
| `lib/core/data/datasources/sherpa_stt_datasource.dart` | Increase `numThreads` to 4, consider zero-copy transfer | P5 |
| `lib/features/speaking/bloc/speaking_bloc.dart` | Call `tts.warmUp()` during LLM generation | P3 |
| `lib/features/speaking/bloc/speaking_bloc.dart` | Implement parallel TTS synthesis | P2 |
| `lib/core/data/datasources/sherpa_stt_datasource.dart` | Remove `VadRepository` dependency | P5 |

---

## 7. Sprint 3 Planning Notes

The Sprint 3 goals (ADR-011, ADR-012, ARCH-101) address several bottlenecks identified here:

- **Chunked STT** addresses Bottleneck #4 (STT→LLM sequential)
- **Supertonic TTS** would address Bottleneck #1 (TTS cold start) if it has fast initialization
- **Pipeline Concurrency** (ARCH-101) addresses Bottlenecks #2 and #3

However, even before Sprint 3:

1. **TTS warm-up** can be implemented immediately (1 day) for immediate improvement
2. **Thread tuning** is a quick win (1 day benchmarking)
3. **LLM→TTS pipelining** is feasible without chunked STT

---

**Last Updated:** April 2026  
**Next Review:** After Sprint 3 implementation
