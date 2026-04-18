# Explanatory Guide: Audio Stream Architecture Transition

This document explains the evolution of the audio streaming architecture in Valoqui (Lingua), detailing the shift from a frame-correlated model to a unified segment-based architecture.

## The Problem: Frame Correlation Mismatch

In the early architecture, the system attempted to correlate real-time audio bytes (`audioStream`) with asynchronous Voice Activity Detection (VAD) events.

### The Old "Correlated" Workflow

1. **Microphone** emits raw PCM16 bytes.
2. **VAD Datasource** listens to these bytes and emits `true` (speech start) and `false` (speech end).
3. **STT Datasource** listens to the same `audioStream` and buffers bytes into an `_audioBuffer`.
4. **STT Datasource** also listens to `voiceActivityStream`.
5. **Logic**: When `voiceActivityStream` emits `false`, the STT datasource would take its current `_audioBuffer`, convert it to Float32, and send it for decoding.

### Why it Failed

- **Race Conditions**: By the time the VAD signals "speech ended," the corresponding audio bytes might have already passed through the stream or be stuck in a buffer.
- **Timing Drift**: Correlating two independent streams (`bool` events and `Uint8List` bytes) is inherently fragile. Small delays in event processing lead to "clipped" audio at the beginning or end of utterances.
- **Complexity**: Every consumer had to maintain its own manual buffers and state machines to "stitch" the two streams together.

---

## The Solution: Unified Segment Architecture

The new architecture leverages the inherent behavior of the **Silero VAD** engine: it is segment-based, not frame-based.

### The New "Unified" Workflow

Instead of emitting raw bytes and separate status flags, the VAD now does the heavy lifting:

1. **VAD as Truth**: The `SherpaVadDatasource` feeds the raw mic input into the Silero engine.
2. **Segment Detection**: Silero detects a "Speech Segment" (a complete utterance followed by silence).
3. **Direct Emission**: Once a segment is complete, the VAD datasource extracts the *actual samples* used by the VAD (`Float32List`) and emits them through a single specialized stream: `speechSegmentStream`.
4. **STT Consumption**: The `SherpaSttDatasource` simply listens to `speechSegmentStream`. When a segment arrives, it is immediately sent to the background decode isolate.

### Key Benefits

- **Zero Clipping**: The STT receives exactly the samples the VAD identified as speech. No more manual buffering or timing correlation.
- **Lower Latency**: Decoding starts the millisecond silence is detected, without waiting for the next "frame" of a raw audio stream.
- **Simplified BLoC**: The `SpeakingBloc` no longer needs to manage audio buffers. it only listens to state changes and transcription results.

---

## Technical Comparison

| Feature | Old Architecture | New (Unified) Architecture |
| :--- | :--- | :--- |
| **STT Input** | `Stream<Uint8List>` (Raw Bytes) | `Stream<Float32List>` (Segments) |
| **Correlation** | Manual (VAD Event + Buffer) | Automatic (Segment contains Audio) |
| **Buffering** | `BytesBuilder` in STT | Native Ring-Buffer in VAD |
| **Precision** | Variable (prone to clipping) | Exact (VAD-defined boundaries) |

---

## Implementation Details

### VAD Stream Contracts

The `SherpaVadDatasource` now provides three distinct paths:

- `speechSegmentStream`: The primary path for Always-On mode. Emits full utterances.
- `voiceActivityStream`: Only emits `false` on completion. Used by BLoC for session metrics.
- `audioStream`: Raw bytes for Push-to-Talk (PTT) mode only, where the user defines the segment manually.

### STT Stream Contracts

The `SherpaSttDatasource` consumes these as follows:

- **Always-On**: Subscribes to `speechSegmentStream`. Each emission = One Decode Task.
- **PTT**: Subscribes to `audioStream` + `voiceActivityStream`. Manually buffers bytes while the button is held.

### Resource Lifecycle

With the move to singletons for heavy models, we transitioned to a **Two-Step Disposal** pattern:

1. **Polite Signal**: Send `null` to isolates/streams to allow graceful cleanup.
2. **Forceful Kill**: Call `.kill()` or `.free()` to ensure native C++ memory is reclaimed.

---

## Conclusion

The transition from a correlated frame model to a unified segment model reduced code complexity in the BLoC and Repository layers while significantly improving the reliability and accuracy of the "Lucia" conversation pipeline.
