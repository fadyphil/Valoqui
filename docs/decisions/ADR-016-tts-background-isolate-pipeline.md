# ADR-016: TTS Background Isolate and Pipelining

**Date:** 2026-04-23
**Status:** Accepted
**Deciders:** Gemini CLI, Fady

## Context

During the evaluation of the Sprint 3 audio pipeline, Text-to-Speech (TTS) synthesis was identified as a major source of UI jank. The `SherpaTtsDatasource` was calling `sherpa.OfflineTts.generate()` and `sherpa.writeWave()` synchronously on the main Dart isolate. Since these operations involve heavy native C++ inference and disk I/O, they were blocking the 60FPS UI rendering thread.

Additionally, the previous implementation processed sentences sequentially: it would synthesize sentence A, wait for it to finish playing, and only then begin synthesizing sentence B. This created audible gaps in long Lucia responses.

## Decision

We will isolate the TTS engine and implement a pipelined synthesis-playback architecture:

1. **TTS Background Isolate**: Move the `sherpa.OfflineTts` instance and all `generate()` calls to a dedicated background `Isolate` (`_SherpaTtsIsolate`). This follows the successful pattern used for Moonshine STT in ADR-011.
2. **Background File I/O**: The isolate will also handle `sherpa.writeWave()` to prevent main-thread blocking during disk writes.
3. **Pipelined Synthesis**: Refactor `_drainQueue()` to pre-synthesize the next sentence (N+1) in the background while the current sentence (N) is playing.

## Alternatives Considered

### Alternative 1: Migrate STT to Whisper.cpp
- **Pros**: Potentially higher accuracy for some edge cases.
- **Cons**: Benchmarks show Whisper.cpp is up to 50x slower than Moonshine (sherpa-onnx) on Android edge devices.
- **Why not**: It would significantly degrade the STT performance gain achieved in Sprint 2.

### Alternative 2: ConcatenatingAudioSource (just_audio)
- **Pros**: Built-in gapless playback support.
- **Cons**: Requires rewriting the audio player logic and managing a complex playlist of temporary files.
- **Why not**: The alternating WAV file strategy with pipelined pre-fetching provides near-gapless playback with much less architectural complexity.

## Consequences

### Positive
- ✅ **Zero UI Jank**: The main isolate is completely free of heavy TTS inference and I/O.
- ✅ **Reduced Latency**: Sentences are prepared in advance, eliminating the gap between sentences in multi-sentence responses.
- ✅ **Robustness**: Native TTS crashes are isolated from the main UI process.

### Negative
- ⚠️ **Isolate Overhead**: Spawning the isolate adds a small memory overhead (~20-40MB).
- ⚠️ **Complexity**: Pipelined logic in `_drainQueue` is more difficult to reason about than simple sequential loops.

### Risks
- 🔴 **Race Conditions**: If `stop()` is called mid-pipeline, we must ensure the background synthesis for the *next* sentence is also cancelled or ignored.
- **Mitigation**: Checked `_isDrainingQueue` guard before and after every `await` in the pipeline.
