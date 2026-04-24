# ARCH-101: Audio Pipeline Concurrency Model

**Date:** April 2026  
**Status:** Proposed  
**Author:** Development Team  
**Related ADRs:** ADR-011 (STT Performance), ADR-012 (Supertonic TTS), ADR-010 (Unified Audio Pipeline)

## Context

The current Sprint 2 audio pipeline processes audio sequentially:

```Markdown
[Microphone] → [VAD Detection] → [Full Buffer Recording] → [STT Decode] → [LLM Request] → [TTS Synthesis] → [Speaker]
```

This sequential model creates significant latency bottlenecks:

- **STT blocking:** Full utterance must be recorded before decoding begins
- **Single-threaded decode:** Main isolate blocked during STT/TTS computation
- **No pipelining:** Each stage waits for previous stage completion
- **Perceived lag:** Users wait 3-5 seconds from speech end to hearing response

Sprint 3 introduces concurrent processing to reduce perceived latency through:

1. **Chunked streaming STT** (ADR-011): Decode partial audio while continuing to record
2. **Parallel TTS warm-up**: Prepare TTS engine while LLM generates response
3. **Isolate-based compute:** Offload heavy STT/TTS work to background isolates
4. **Pipeline parallelism:** Overlap STT, LLM, and TTS stages where possible

## Decision Drivers

- **Latency Reduction:** Target <2s end-to-end latency (currently 4-5s)
- **Responsiveness:** Show partial transcripts as soon as available
- **Resource Efficiency:** Avoid blocking main isolate during compute-heavy operations
- **User Experience:** Perceived speed improvement through progressive output
- **Maintainability:** Keep concurrency logic isolated and testable
- **Error Handling:** Graceful degradation when pipeline stages fail independently

## Architecture Principles

### 1. Isolate-Based Compute Boundaries

All CPU-intensive operations (STT decode, TTS synthesis) run in dedicated isolates:

```dart
// ❌ Bad: Blocks main isolate
final transcript = await sherpaDecoder.decode(audioBuffer);

// ✅ Good: Non-blocking isolate compute
final transcript = await compute(_decodeInIsolate, audioBuffer);

static String _decodeInIsolate(List<int> audio) {
  // Heavy computation here doesn't block UI
  return decoder.decode(audio);
}
```

**Rules:**

- Never call blocking decode/synthesis methods on main isolate
- Always wrap heavy compute in `compute()` or spawn dedicated isolate
- Pass data via immutable copies (no shared state between isolates)
- Implement timeout handling for isolate communication

### 2. Stream-Based Chunk Processing

Replace full-buffer processing with streaming chunk pipeline:

```dart
// ❌ Old: Full buffer processing
await vadDataSource.startRecording();
final audioBuffer = await vadDataSource.stopRecording();
final transcript = await sttDatasource.decode(audioBuffer);

// ✅ New: Streaming chunks
final chunkStream = vadDataSource.chunkStream(
  chunkDuration: Duration(milliseconds: 1500),
  overlap: Duration(milliseconds: 300),
);

await for (final chunk in chunkStream) {
  final partial = await sttDatasource.decodeChunk(chunk);
  _emitPartialTranscript(partial);
}
final finalTranscript = await sttDatasource.finalize();
```

**Benefits:**

- First partial transcript available after 1.5s instead of waiting for full utterance
- Overlapping chunks preserve context across boundaries
- Progressive refinement improves perceived responsiveness

### 3. Pipeline Stage Decoupling

Each pipeline stage operates independently with message passing:

```Markdown
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   VAD +     │    │    STT      │    │    LLM      │    │    TTS      │
│  Chunking   │───▶│  Decoder    │───▶│  Generator  │───▶│  Synthesizer│
│  (Isolate)  │    │  (Isolate)  │    │  (Network)  │    │  (Isolate)  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                  │                  │                  │
       ▼                  ▼                  ▼                  ▼
  Stream<Audio>     Stream<String>    Stream<String>     Stream<Audio>
     Chunk            Partial          Response            Speech
```

**Communication Pattern:**

- Stages communicate via `Stream` and `Sink` (no shared mutable state)
- Backpressure handled via bounded buffers
- Each stage can fail independently without crashing entire pipeline
- Error propagation flows downstream with context preservation

### 4. Progressive Output Strategy

Emit intermediate results to improve perceived responsiveness:

**STT Pipeline:**

1. **Partial transcripts** (every 1.5s chunk): Show unstable draft to user
2. **Debounce logic** (300ms stability window): Avoid flickering on unstable partials
3. **Final transcript** (after VAD silence): Replace partial with stable result
4. **Correction pass** (optional): Post-process full buffer for accuracy

**TTS Pipeline:**

1. **Warm-up** (during LLM generation): Pre-load voices, initialize synthesizer
2. **Incremental synthesis** (if supported): Start speaking first sentence while LLM generates rest
3. **Gap filling**: Play ambient sound or "thinking" indicator during synthesis gaps

## Implementation Patterns

### Pattern 1: Chunked STT Processor

```dart
class ChunkedSttProcessor {
  static const chunkDuration = Duration(milliseconds: 1500);
  static const overlapDuration = Duration(milliseconds: 300);
  static const debounceDuration = Duration(milliseconds: 300);
  
  final SttEngine _engine;
  final _audioBuffer = <int>[];
  final _partialController = StreamController<String>.broadcast();
  Timer? _debounceTimer;
  String? _lastStablePartial;
  
  Stream<String> get partialTranscripts => _partialController.stream;
  
  void addAudioSamples(List<int> samples) {
    _audioBuffer.addAll(samples);
    
    if (_audioBuffer.duration >= chunkDuration + overlapDuration) {
      _processChunk();
    }
  }
  
  void _processChunk() async {
    // Extract chunk with overlap context
    final chunkStart = max(0, _audioBuffer.length - overlapDuration.samples);
    final chunkEnd = min(_audioBuffer.length, chunkStart + chunkDuration.samples);
    final chunk = _audioBuffer.sublist(chunkStart, chunkEnd);
    
    // Decode in isolate (non-blocking)
    final partial = await compute(_engine.decodeChunk, chunk);
    
    // Debounce to avoid UI flicker
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      if (partial != _lastStablePartial) {
        _partialController.add(partial);
        _lastStablePartial = partial;
      }
    });
    
    // Retain overlap for next chunk context
    _audioBuffer.removeRange(0, chunkStart);
  }
  
  Future<String> finalize() async {
    _debounceTimer?.cancel();
    // Final decode with full buffer for accuracy
    return compute(_engine.decodeFull, List.unmodifiable(_audioBuffer));
  }
  
  void dispose() {
    _debounceTimer?.cancel();
    _partialController.close();
  }
}
```

### Pattern 2: Pipeline Orchestrator

```dart
class VoicePipelineOrchestrator {
  final ChunkedSttProcessor _sttProcessor;
  final LlmRepository _llmRepo;
  final TtsRepository _ttsRepo;
  
  Stream<VoicePipelineState> executeConversation() async* {
    // State 1: Listening
    yield VoicePipelineState.listening();
    
    final partialsSub = _sttProcessor.partialTranscripts.listen((partial) {
      yield VoicePipelineState.processing(partialTranscript: partial);
    });
    
    // Wait for VAD silence detection
    await _vadSilenceDetector.silenceDetected.first;
    partialsSub.cancel();
    
    // State 2: Finalizing STT
    yield VoicePipelineState.processing(status: 'Finalizing...');
    final transcript = await _sttProcessor.finalize();
    
    // State 3: LLM Generation (with TTS warm-up)
    yield VoicePipelineState.generating();
    
    // Warm up TTS in parallel (don't await)
    final ttsWarmup = _ttsRepo.warmUp().timeout(
      Duration(milliseconds: 500),
      onTimeout: () => null, // Don't block if warm-up slow
    );
    
    final llmResponse = await _llmRepo.generate(transcript);
    await ttsWarmup; // Ensure TTS ready
    
    // State 4: TTS Synthesis
    yield VoicePipelineState.speaking();
    await _ttsRepo.speak(llmResponse);
    
    // State 5: Complete
    yield VoicePipelineState.idle();
  }
}
```

### Pattern 3: Backpressure Handling

```dart
class BoundedAudioQueue {
  final int maxChunks;
  final _queue = <List<int>>[];
  final _notFull = Completer<void>();
  
  BoundedAudioQueue({this.maxChunks = 5});
  
  Future<void> enqueue(List<int> chunk) async {
    while (_queue.length >= maxChunks) {
      // Backpressure: wait until queue has space
      await Future.delayed(Duration(milliseconds: 100));
    }
    _queue.add(chunk);
    _notFull.complete();
  }
  
  Future<List<int>> dequeue() async {
    while (_queue.isEmpty) {
      await Future.delayed(Duration(milliseconds: 50));
    }
    return _queue.removeAt(0);
  }
  
  bool get isFull => _queue.length >= maxChunks;
  int get length => _queue.length;
}
```

## Consequences

### Positive

- ✅ **Latency reduction:** Perceived latency reduced by 50-60% (partial transcripts appear faster)
- ✅ **Responsiveness:** UI remains responsive during heavy compute (isolates)
- ✅ **Scalability:** Pipeline stages can be optimized independently
- ✅ **Error isolation:** Failure in one stage doesn't crash entire pipeline
- ✅ **Testability:** Each pattern can be unit-tested in isolation

### Negative

- ⚠️ **Complexity increase:** Concurrent programming introduces subtle bugs (race conditions, deadlocks)
- ⚠️ **Memory overhead:** Multiple chunk buffers and isolate memory usage
- ⚠️ **Debugging difficulty:** Asynchronous flow harder to trace in debugger
- ⚠️ **State management:** Tracking partial vs. final state adds complexity
- ⚠️ **Testing overhead:** Need to test timing-dependent behavior (debouncing, timeouts)

### Risks

- 🔴 **Risk:** Race conditions in chunk buffer management  
  **Mitigation:** Use immutable data structures, avoid shared mutable state
  
- 🔴 **Risk:** Isolate spawn failure on low-memory devices  
  **Mitigation:** Fallback to main isolate with timeout; monitor memory usage
  
- 🟡 **Risk:** Debounce timing causes noticeable delay on short utterances  
  **Mitigation:** Adaptive debounce (shorter for <3s utterances)
  
- 🟡 **Risk:** Backpressure causes audio dropouts if queue fills  
  **Mitigation:** Increase queue size, optimize decode speed, add telemetry

## Testing Strategy

### Unit Tests

```dart
test('ChunkedSttProcessor emits partials every 1.5s', () async {
  final processor = ChunkedSttProcessor(mockEngine);
  final partials = <String>[];
  processor.partialTranscripts.listen(partials.add);
  
  // Feed 5 seconds of audio
  for (int i = 0; i < 50; i++) {
    processor.addAudioSamples(generateAudioChunk(milliseconds: 100));
    await Future.delayed(Duration(milliseconds: 100));
  }
  
  expect(partials.length, greaterThanOrEqualTo(3)); // At least 3 partials
});

test('Debounce prevents rapid partial updates', () async {
  // Test that partials don't update faster than debounce window
});

test('Backpressure prevents queue overflow', () async {
  // Test that enqueue blocks when queue is full
});
```

### Integration Tests

```dart
test('End-to-end pipeline completes in <2s', () async {
  final stopwatch = Stopwatch()..start();
  
  await pumpWidget(TestApp(
    child: VoicePipelineWidget(),
  ));
  
  // Simulate user speaking
  tester.tap(find.byType(MicButton));
  await tester.pumpAndSettle();
  
  // Wait for TTS to complete
  await find.byType(AudioPlayer).waitForState(AudioPlayerState.completed);
  
  expect(stopwatch.elapsedMilliseconds, lessThan(2000));
});
```

### Performance Benchmarks

```dart
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
class PipelineBenchmarks {
  @Benchmark
  Future<void> benchmarkChunkedStt() async {
    final processor = ChunkedSttProcessor(realEngine);
    final audio = loadTestAudio(duration: Duration(seconds: 5));
    
    for (final chunk in audio.chunks) {
      processor.addAudioSamples(chunk);
    }
    
    await processor.finalize();
  }
  
  @Benchmark
  Future<void> benchmarkSequentialStt() async {
    // Baseline: old full-buffer approach
  }
}
```

## Migration Plan

### Phase 1: Isolate Extraction (Days 1-2)

- Move `SherpaSttDatasource.decode()` to isolate via `compute()`
- Add timeout handling for isolate communication
- Benchmark performance impact (expect minimal overhead)

### Phase 2: Chunking Infrastructure (Days 3-4)

- Implement `ChunkedSttProcessor` class
- Add sliding window with 1.5s chunks, 300ms overlap
- Create stream-based API for partial transcripts

### Phase 3: Pipeline Integration (Days 5-6)

- Update `SpeakingBloc` to consume chunked STT stream
- Add debouncing logic for stable partial display
- Implement progressive state updates (listening → processing → generating → speaking)

### Phase 4: TTS Parallelization (Days 7-8)

- Add `TtsRepository.warmUp()` method
- Start TTS warm-up during LLM generation (parallel execution)
- Implement incremental TTS synthesis if supported

### Phase 5: Optimization & Testing (Days 9-10)

- Tune chunk size and overlap parameters
- Add telemetry for pipeline stage timings
- A/B test with real users
- Document edge cases and troubleshooting

## Related Documentation

- **ADR-011:** STT Performance Optimization (chunking strategy details)
- **ADR-012:** Supertonic TTS Integration (TTS parallelization opportunities)
- **ADR-010:** Unified Audio Pipeline (overall architecture context)
- **Engineering Lessons:** "Await reply.first hangs forever" (historical bug fixed by this pattern)

## Glossary

| Term | Definition |
| ------ | ------------ |
| **Chunk** | Fixed-duration audio segment (e.g., 1.5s) processed independently |
| **Overlap** | Audio region shared between consecutive chunks for context preservation |
| **Partial Transcript** | Intermediate STT result that may change with more context |
| **Final Transcript** | Stable STT result after full utterance processing |
| **Backpressure** | Flow control mechanism to prevent producer overwhelming consumer |
| **Debounce** | Delay emission until value stabilizes for specified duration |
| **Pipeline Stage** | Independent processing unit (VAD, STT, LLM, TTS) in audio pipeline |
| **Isolate** | Dart VM thread with separate memory heap (true parallelism) |

---

## Appendix: Timing Budget Breakdown

| Stage | Current (Sprint 2) | Target (Sprint 3) | Improvement Method |
| ------- | ------------------- | ------------------- | ------------------- |
| VAD detection | 200ms | 200ms | No change |
| Audio recording | 3000ms (full utterance) | 1500ms (first chunk) | Chunked streaming |
| STT decode | 2500ms (sequential) | 800ms (overlapped) | Isolate + chunking |
| Time to first partial | 5700ms | 2300ms | **60% reduction** |
| LLM generation | 1500ms | 1500ms | No change (network bound) |
| TTS warm-up | 0ms (cold start) | 500ms (parallel) | Pre-loading during LLM |
| TTS synthesis | 1200ms | 600ms | Supertonic integration |
| **Total end-to-end** | **8400ms** | **4900ms** | **42% reduction** |
| **Perceived latency** | **5700ms** (to first response) | **2300ms** (first partial) | **60% reduction** |
