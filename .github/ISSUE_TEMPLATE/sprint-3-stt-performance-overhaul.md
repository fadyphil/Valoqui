---
name: 🚀 Feature: Sprint 3 - STT Performance Overhaul
about: Reduce transcription latency via chunked streaming and/or Whisper.cpp integration
title: '[Sprint 3] Overhaul STT pipeline for low-latency transcription'
labels: ['sprint-3', 'stt', 'performance', 'critical']
assignees: ''
---

## Feature Decision Record

**Related ADR:** ADR-012, ARCH-101
**Priority:** Critical
**Sprint:** 3
**Estimated Effort:** 7 days

## Problem Statement

Current sherpa-onnx STT implementation has unacceptable latency:

- **Full utterance processing time:** 3-5 seconds (measured on mid-range device)
- **Time-to-first-transcript:** 2-4 seconds after user stops speaking
- **Sequential bottleneck:** VAD → buffer complete audio → decode → transcript
- **User experience:** Conversational flow broken by long pauses

Root causes identified:

1. **Buffering strategy:** Waits for complete silence before processing
2. **Model size:** Moonshine base model inference is slow on mobile CPU
3. **No streaming:** No partial results shown to user during processing
4. **Single-threaded:** Audio capture, VAD, and decoding happen sequentially

## Proposed Solution

### Phase 1: Chunked Streaming (Lower Risk, Immediate Gain)

Implement incremental transcription with overlapping chunks:

```dart
// Conceptual flow
class ChunkedSttPipeline {
  final Duration chunkDuration = Duration(milliseconds: 500); // 500ms chunks
  final Duration overlapDuration = Duration(milliseconds: 100); // 100ms overlap

  Stream<String> transcribe(Stream<List<int>> audioStream) async* {
    final buffer = AudioBuffer();
    String lastConfirmedTranscript = '';

    await for (final chunk in audioStream.chunk(chunkDuration)) {
      // Process chunk immediately (don't wait for full utterance)
      final partial = await _decodeChunk(chunk);

      // Show partial result to UI immediately
      yield lastConfirmedTranscript + partial;

      // When VAD detects silence, finalize and confirm
      if (vad.isSilent()) {
        lastConfirmedTranscript += partial;
        yield lastConfirmedTranscript; // Final confirmed transcript
      }
    }
  }
}
```

**Expected improvements:**

- Time-to-first-partial: < 500ms (vs. current 2-4s)
- Perceived latency reduction: Users see text appearing while speaking
- Graceful degradation: Still works if Whisper.cpp evaluation fails

### Phase 2: Whisper.cpp Evaluation (Higher Risk, Higher Reward)

Research and potentially integrate Whisper.cpp for better accuracy/speed:

**Evaluation criteria:**

- [ ] Inference speed on mobile CPU (compare to sherpa-onnx)
- [ ] Model size vs. quality tradeoff (tiny/base/small variants)
- [ ] Streaming support (incremental transcription)
- [ ] Android integration complexity (JNI bindings, build process)
- [ ] License compatibility (MIT license ✓)

**Integration approach (if evaluation succeeds):**

```dart
class WhisperCppSttDatasource implements SttDatasource {
  final WhisperCppModel _model;

  @override
  Stream<String> transcribe(Stream<List<int>> audioStream) async* {
    // Use Whisper.cpp's built-in streaming API
    await for (final segment in _model.transcribeStream(audioStream)) {
      yield segment.text; // Partial results as available
    }
  }
}
```

## Acceptance Criteria

### Chunked Streaming (Phase 1 - Required)

- [ ] Partial transcripts appear within 500ms of speech start
- [ ] Overlap handling prevents duplicate/transcription gaps
- [ ] VAD integration maintains chunk boundaries
- [ ] UI shows "listening..." → "partial transcript" → "confirmed" states
- [ ] Latency benchmark: end-to-end < 1.5s for 3-second utterance
- [ ] No regression in transcription accuracy (>90% WER maintained)

### Whisper.cpp Evaluation (Phase 2 - Optional, Time-Boxed)

- [ ] Benchmark report comparing sherpa-onnx vs. Whisper.cpp
- [ ] Decision documented: adopt, defer, or reject
- [ ] If adopted: basic integration with fallback to sherpa-onnx
- [ ] If deferred: clear rationale and future reconsideration criteria

## Technical Spikes Required

### Spike 1: Chunked Streaming Design (2 days)

**Goal:** Design chunking strategy that balances latency vs. accuracy

- [ ] Determine optimal chunk duration (300ms? 500ms? 1000ms?)
- [ ] Handle overlap/blend between chunks
- [ ] Manage context carryover (incomplete words at chunk boundaries)
- [ ] Test with various speech patterns (fast/slow, accented, etc.)

**Deliverable:** `docs/spikes/chunked-streaming-design.md`

### Spike 2: Whisper.cpp Feasibility (3 days)

**Goal:** Evaluate Whisper.cpp for mobile deployment

- [ ] Build Whisper.cpp for Android (ARM64)
- [ ] Benchmark inference speed on test device
- [ ] Test streaming API availability
- [ ] Assess integration effort (JNI, Flutter FFI, or platform channel)

**Deliverable:** `docs/spikes/whisper-cpp-evaluation.md`

## Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
| ------ | -------- | ------------- | ------------ |
| Chunking reduces accuracy (lost context) | High | Medium | Overlap chunks, carry over context buffer |
| Whisper.cpp too complex to integrate | Medium | Medium | Time-box spike, fall back to chunked-only approach |
| Increased battery drain from parallel processing | Medium | Low | Profile power usage, optimize thread pool size |
| Network dependency if using server-side Whisper | High | Low | Keep on-device only, no network calls |
| Regression in noise handling | High | Medium | Extensive testing with background noise samples |

## Dependencies

- **Blocks:** None
- **Blocked by:** None (can start immediately)
- **Related:** ADR-011 (Supertonic TTS) - concurrent work, shared audio pipeline

## Success Metrics

1. **Latency:** Time-to-first-partial < 500ms (currently 2-4s)
2. **End-to-End:** Complete transcript < 1.5s after 3s utterance (currently 3-5s)
3. **Accuracy:** Word Error Rate (WER) ≤ 10% (maintain current level)
4. **User Satisfaction:** Beta testers report "conversational feel" improved
5. **Code Quality:** No increase in cyclomatic complexity > 15%

## Implementation Plan

### Week 1: Research & Design

- Days 1-2: Chunked streaming spike
- Days 3-5: Whisper.cpp evaluation spike

### Week 2: Implementation

- Days 1-3: Implement chunked streaming pipeline
- Days 4-5: Integrate with existing VAD/BLoC, add tests

### Week 3: Polish & Benchmark

- Days 1-2: Performance profiling, optimization
- Days 3-4: User testing, bug fixes
- Day 5: Documentation, sprint review

## References

- Whisper.cpp: <https://github.com/ggerganov/whisper.cpp>
- sherpa-onnx current implementation: `lib/core/data/datasources/sherpa_stt_datasource.dart`
- ADR-001: Original STT decision (Android SpeechRecognizer → sherpa-onnx)
- Engineering lessons: `docs/extras/sprint-2/lessons learnt/engineering_lessons.md` (latency issues documented)

## Notes

⚠️ **Critical:** This is the #1 user-reported pain point from Sprint 2 beta testing. Priority over TTS work if time becomes constrained.

⚠️ **Testing requirement:** Must test on low-end devices (2GB RAM, quad-core ARM Cortex-A53) to ensure accessibility.
