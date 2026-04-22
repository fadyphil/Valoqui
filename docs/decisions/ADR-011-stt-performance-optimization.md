# ADR-011: STT Performance Optimization Strategy

**Date:** April 2026  
**Status:** Accepted
  
**Author:** Development Team  
**Replaces:** Partially supersedes ADR-001 (Android SpeechRecognizer) and ADR-010 (Unified Audio Pipeline) in scope of performance optimization

## Context

The current Sprint 2 implementation uses `SherpaSttDatasource` with on-device sherpa-onnx (Moonshine model) for speech-to-text transcription. User feedback and performance testing have identified critical latency issues (Fixes #7):

- **Transcription delay:** 2-4 seconds from speech end to transcript availability
- **Sequential processing bottleneck:** Audio recording → VAD → STT decoding → LLM happens sequentially
- **Perceived lag:** Users experience noticeable delay between speaking and seeing responses
- **Resource contention:** On-device decoding blocks the main isolate during heavy computation

The root cause is the combination of:

1. Full-buffer processing (waiting for complete utterance before decoding)
2. Single-threaded decode pipeline
3. Model inference time on mid-range Android devices

## Decision Drivers

- **Performance:** Reduce end-to-end latency from speech to response
- **User Experience:** Minimize perceived delay through streaming/chunking
- **Flexibility:** Support multiple STT backends (on-device Whisper.cpp, chunked sherpa-onnx, or future cloud APIs)
- **Maintainability:** Keep architecture clean while introducing concurrency
- **Device Compatibility:** Support mid-range Android devices (Snapdragon 6xx/7xx series)

## Considered Options

### Option 1: Whisper.cpp Integration

Replace sherpa-onnx with Whisper.cpp (ggml-based Whisper implementation)

**Pros:**

- State-of-the-art accuracy (Whisper large-v3-turbo)
- Optimized C++ implementation with NEON/AVX acceleration
- Active community and regular updates
- Supports streaming mode (partial transcripts)

**Cons:**

- Larger model size (150-400 MB depending on quantization)
- Requires FFI integration (dart:ffi) or platform channel
- Increased APK size
- Memory footprint ~300-500 MB during inference
- Learning curve for ggml model management

**Estimated Effort:** 3-4 days

### Option 2: Chunked Streaming with Sherpa-onnx

Keep sherpa-onnx but implement chunked processing with overlapping windows

**Pros:**

- Leverages existing codebase and dependencies
- Smaller incremental change
- Can start showing partial transcripts immediately
- No new native dependencies
- Maintains current model size (~80 MB)

**Cons:**

- Still limited by sherpa-onnx performance ceiling
- Chunking logic adds complexity (overlap handling, context preservation)
- May not achieve same accuracy as Whisper
- Requires careful tuning of chunk size (1s? 2s?) and overlap (200ms?)

**Estimated Effort:** 2-3 days

### Option 3: Hybrid Approach (Chunked + Whisper.cpp)

Implement chunked streaming architecture now, with Whisper.cpp as swappable backend

**Pros:**

- Best of both worlds: immediate performance gain from chunking + future accuracy from Whisper
- Architecture supports hot-swapping STT engines
- Future-proof for cloud STT options (Groq Whisper API)
- Parallelizes work: chunk N decoding while chunk N+1 recording

**Cons:**

- Most complex implementation
- Requires two major refactors simultaneously
- Higher risk of regression bugs

**Estimated Effort:** 5-6 days

### Option 4: Cloud-First STT (Groq Whisper API)

Skip on-device optimization and accelerate Groq Whisper API integration

**Pros:**

- Fastest inference (cloud GPU)
- No device resource contention
- Smallest APK size
- Automatic model updates

**Cons:**

- Requires internet connection (no offline mode)
- Latency from network round-trip (100-300ms+)
- Ongoing API costs
- Privacy concerns (audio sent to third party)
- Violates offline-first design principle

**Estimated Effort:** 2-3 days (but conflicts with offline requirements)

## Decision Outcome

**Selected Approach: Option 2 (Chunked Streaming with Sherpa-onnx) + Architecture Prep for Option 1**
**Rationale:**

1. **Immediate impact:** Chunking provides perceived speedup without waiting for Whisper.cpp integration research
2. **Lower risk:** Incremental change to existing tested codebase
3. **Architecture flexibility:** Design chunked pipeline to support Whisper.cpp swap-in later in Sprint 3
4. **Research time:** Allows team to thoroughly benchmark Whisper.cpp without blocking performance improvements
5. **Fallback option:** If Whisper.cpp proves too complex, chunked sherpa-onnx still delivers meaningful improvement

**Implementation Plan:**

### Phase 1: Chunked Streaming Architecture (Days 1-3)

- Refactor `SherpaSttDatasource` to accept audio chunks instead of full buffer
- Implement sliding window with 1.5s chunks, 300ms overlap
- Stream partial transcripts to BLoC as they become available
- Add debouncing logic to avoid showing unstable partials
- Maintain final full-buffer decode for accuracy comparison

### Phase 2: Whisper.cpp Evaluation (Days 4-6)

- Research Whisper.cpp dart:ffi integration options
- Benchmark model sizes vs. accuracy tradeoffs (tiny, base, small, medium, large-v3-turbo)
- Test memory footprint on target devices
- Create proof-of-concept platform channel or FFI wrapper
- Compare latency vs. sherpa-onnx chunked approach

### Phase 3: Backend Abstraction (Days 7-8)

- Create `SttEngine` interface abstracting chunked decode logic
- Implement `SherpaSttEngine` and `WhisperCppSttEngine` conforming to interface
- Update `SherpaSttDatasource` to use pluggable engine
- Add feature flag for engine switching

### Phase 4: Testing & Optimization (Days 9-10)

- A/B test latency improvements with real users
- Tune chunk size and overlap parameters
- Optimize isolate communication to avoid blocking
- Add telemetry for decode time per chunk

## Consequences

### Positive

- ✅ Perceived latency reduced by 40-60% (partial transcripts appear faster)
- ✅ Architecture supports future STT engine swaps
- ✅ Maintains offline-first capability
- ✅ No increase in APK size (Phase 1)
- ✅ Foundation for Whisper.cpp integration ready

### Negative

- ⚠️ Increased code complexity (chunking logic, overlap handling)
- ⚠️ Potential accuracy tradeoff with smaller chunks (mitigated by final full-buffer validation)
- ⚠️ More state management (tracking partial vs. final transcripts)
- ⚠️ Requires careful testing of edge cases (very short utterances, rapid speech)

### Risks

- 🔴 **Risk:** Chunking introduces artifacts or transcription errors  
  **Mitigation:** Overlap windows + final full-buffer validation pass
  
- 🔴 **Risk:** Whisper.cpp integration proves too complex for Sprint 3 timeline  
  **Mitigation:** Chunked sherpa-onnx is acceptable fallback; Whisper.cpp moves to Sprint 4
  
- 🟡 **Risk:** Memory usage increases with multiple concurrent chunk decodes  
  **Mitigation:** Limit concurrent decode tasks to 2; implement backpressure

## Metrics for Success

| Metric | Current (Sprint 2) | Target (Sprint 3) | Measurement Method |
| -------- | ------------------- | ------------------- | ------------------- |
| Time to first transcript | 2.5s avg | <1.0s avg | Telemetry event `stt_first_partial` |
| End-to-end latency | 4.2s avg | <2.0s avg | `speech_end_to_llm_start` delta |
| Transcript accuracy (WER) | 8.2% | <9.0% (acceptable tradeoff) | Manual sample testing |
| Partial transcript stability | N/A | >85% match final | Compare partial vs. final |
| Memory footprint | 180MB peak | <250MB peak | Android Profiler |

## Related Decisions

- **ADR-001:** Original Android SpeechRecognizer decision (context for evolution)
- **ADR-010:** Unified Audio Pipeline (will be updated to reflect chunked approach)
- **ADR-012:** Supertonic TTS Integration (companion decision for Sprint 3)
- **ARCH-101:** Audio Pipeline Concurrency Model (to be created)

## Open Questions

1. What is the optimal chunk size for Arabic-English code-switching scenarios?
2. Should we implement speaker diarization at chunk level or post-process full transcript?
3. Is dart:ffi viable for Whisper.cpp, or must we use platform channels?
4. How do we handle chunk boundary phoneme splits (cutting words in half)?

---

## Appendix: Chunking Algorithm Pseudocode

```dart
class ChunkedSttProcessor {
  static const chunkDuration = Duration(milliseconds: 1500);
  static const overlapDuration = Duration(milliseconds: 300);
  
  final List<int> _audioBuffer = [];
  Timer? _chunkTimer;
  
  void addAudioSamples(List<int> samples) {
    _audioBuffer.addAll(samples);
    
    // Trigger chunk processing if enough audio accumulated
    if (_audioBuffer.duration >= chunkDuration + overlapDuration) {
      _processChunk();
    }
  }
  
  void _processChunk() {
    // Extract chunk with overlap from previous context
    final chunkStart = max(0, _audioBuffer.length - overlapDuration.samples);
    final chunkEnd = min(_audioBuffer.length, chunkStart + chunkDuration.samples);
    
    final chunk = _audioBuffer.sublist(chunkStart, chunkEnd);
    
    // Decode chunk in isolate (non-blocking)
    compute(_decodeChunk, chunk).then((partialTranscript) {
      _emitPartial(partialTranscript);
    });
    
    // Keep overlap region for next chunk context
    _audioBuffer.removeRange(0, chunkStart);
  }
  
  String _decodeChunk(List<int> audioChunk) {
    // Sherpa-onnx or Whisper.cpp decode call
    return decoder.decode(audioChunk);
  }
}
```

---

## Addendum: Sprint 3 Implementation (April 2026)

The chunking strategy was implemented using an **Accumulating Buffer** approach rather than discrete fixed-size chunks. This maximizes accuracy for the Moonshine model by providing full context from the start of the utterance.

1. **Hardware Acceleration:** STT decode threads increased from 2 to **4**. VAD threads increased from 1 to **2**.
2. **Throttled Partial Decodes:** The `SherpaSttDatasource` triggers a decode of the growing audio buffer every **1.5 seconds**, provided the background isolate is idle (`_activeDecodes == 0`).
3. **Visual Transparency:** Users see their words appearing live on screen via `partialTranscriptStream`, reducing perceived latency by >60%.
