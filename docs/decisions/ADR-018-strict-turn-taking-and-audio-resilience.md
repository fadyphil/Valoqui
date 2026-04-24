# ADR-018: Strict Turn-Taking and Audio Pipeline Resilience

**Date:** April 2026  
**Status:** Accepted
  
**Author:** Development Team  
**Supersedes:** Refines stability for ADR-011 (STT Performance) and ADR-008 (Sentence Boundary TTS)

## Context

Following the implementation of on-device Moonshine STT and Piper TTS, real-world testing in Release mode identified several critical race conditions and UX failures in the voice pipeline:

1. **PTT Chunking:** The VAD (Voice Activity Detector) silent-segment listener was active during Push-To-Talk (PTT) mode. When the user paused for breath, VAD emitted segments that prematurely triggered STT decodes, "chopping" a single manual recording into fragmented transcripts.
2. **Audio Focus Theft:** Switching from PTT to Always-On mode while Lucia was speaking would immediately start VAD monitoring. Opening the microphone stream stole AudioFocus on Android, abruptly cutting off Lucia's voice.
3. **PTT "Hung" States:** A bug existed where manual transcriptions were dropped if the BLoC transitioned to the `processing` phase too early (before the background isolate finished decoding).
4. **VAD Buffer Retention:** Switching from PTT to Always-On would occasionally "resend" the last message because the VAD internal buffer wasn't cleared after the manual PTT recording.
5. **Ghost UI Updates:** The 100ms LLM token batching timer could fire *after* a session ended or a new utterance started, injecting stale text into the transcript.

## Decision

To ensure a robust, professional-grade conversation flow, we implemented a series of "Strict Turn-Taking" and isolation rules:

### 1. VAD-PTT Isolation

- **Physically Mute VAD during PTT:** Added an `enableVad` parameter to `VadRepository.startMonitoring()`. When the PTT button is held, the BLoC explicitly sets this to `false`. Audio bytes still flow for PTT buffering, but the VAD engine ignores them, preventing chunking and buffer retention.
- **Ignore VAD Segments during PTT:** `SherpaSttDatasource` now ignores any VAD-emitted segments while `_isRecordingUtterance` is true.

### 2. Strict Turn-Taking Enforcement

- **Enforced "Walkie-Talkie" UX:** Opted for a strict turn-taking model (non-barge-in) for MVP stability. The `MicButton` is now visually disabled and functionally unresponsive during the `processing` and `speaking` phases.
- **Microphone Lockout:** Modified `SpeakingBloc` to only call `startMonitoring()` if the phase is `listening`. If the user toggles Always-On while Lucia is talking, the mic start is deferred until `_onTtsFinished`.
- **Physical Mic Shutoff:** In Always-On mode, the physical microphone stream is now explicitly shut off the moment silence is detected. It remains closed during LLM processing and TTS playback to prevent echo and overlapping input.

### 3. User-Side Resilience

- **Introduced `isTranscribing` State:** Decoupled the wait time for STT decoding from the LLM `processing` phase.
- **User Loading Feedback:** Added a right-aligned `TypingIndicator` (three dots) that appears inside a User bubble while `isTranscribing` is true. This provides immediate haptic/visual feedback that the app heard the user, even if the offline model takes 2-3 seconds to decode.
- **Phase Preservation:** Updated UI batching logic to preserve the `speaking` phase if it's already active, preventing state "regressions" back to `processing` when new LLM tokens arrive.

### 4. Background Isolate Optimization

- **Hardware Profile:** Standardized the background isolate on `xnnpack` with 4 threads for Android to match main-thread performance.
- **Safety Timeout:** Increased the decode timeout from 10s to **60s** (matching the PTT buffer cap) to prevent dropping long utterances on mid-range hardware.

## Consequences

- **Pros:**
  - Zero overlapping audio or cut-off voices.
  - Consistent, bug-free mode switching.
  - Transparent UI feedback for the user's own transcription wait time.
  - Significant performance boost for long recordings on ARM CPUs.
- **Cons:**
  - Users cannot interrupt Lucia mid-sentence (barge-in disabled). This is an acceptable tradeoff for MVP stability and will be revisited post-launch.
  - Slightly higher complexity in the `SpeakingBloc` state machine.
