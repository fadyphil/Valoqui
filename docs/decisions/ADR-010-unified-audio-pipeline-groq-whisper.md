# ADR-010: Unified Audio Pipeline — Deprecate speech_to_text, Single Raw PCM Stream

**Date:** 2026-03
**Status:** Accepted — planned Sprint 3
**Sprint:** Sprint 3
**Decider:** Fady

---

## Context

Sprint 2 shipped with two independent audio components: `speech_to_text`
(Android SpeechRecognizer) for STT and `sherpa-onnx` (Silero VAD) for voice
activity detection. This architecture has two critical failures identified in
ARCH-101:

1. **7-second PTT ceiling**: Android SpeechRecognizer enforces a hard ~7-second
   OS ceiling on any listening session. This cannot be overridden via the
   `speech_to_text` package. Long user sentences are cut off mid-utterance.

2. **Mic hardware conflict**: `speech_to_text` and the `record` package both
   require exclusive microphone access on Android. Running both simultaneously
   causes crashes or silent blocking. The VAD was disabled from always-on mode
   as a workaround — meaning always-on mode relies entirely on the OS deciding
   the user stopped speaking.

These are not logical bugs. They are fundamental limitations of Android's
SpeechRecognizer API, which was designed for short voice search queries, not
continuous dictation.

---

## Decision

Sprint 3 replaces the split audio pipeline with a **Unified Audio Pipeline**:

1. **Single mic holder**: The `record` package opens one continuous 16kHz
   PCM audio stream — the only process holding the microphone.
2. **VAD routing**: Every audio chunk is fed to Silero VAD in sherpa-onnx.
3. **Buffer management**: While VAD detects speech (or PTT button is held),
   audio bytes accumulate in a `BytesBuilder` in memory.
4. **Transcription trigger**: When VAD detects silence end (or PTT button
   is released), the buffer is wrapped in a WAV header and sent to
   Groq Whisper large-v3-turbo via multipart HTTP.
5. **BLoC receives completed utterance**: `SpeakingBloc` receives a fully
   transcribed string, not partial results.

Implementation impact:

- `speech_to_text` removed from `pubspec.yaml`.
- `AndroidSttDatasource` deprecated — replaced by `GroqSttDatasource` which
  accepts `Uint8List` audio and returns transcribed `String`.
- `SherpaVadDatasource` refactored to own the mic stream and emit complete
  audio buffers (`Stream<Uint8List>`) rather than just `Stream<bool>`.
- `SpeakingBloc` updated to consume the new `SttRepository` interface — no
  other BLoC logic changes.
- `service_locator.dart`: one line change (SttRepository registration).

---

## Alternatives considered

### Option A — Fix speech_to_text workarounds

**Why considered:** Less code change.
**Why rejected:** The 7-second ceiling is enforced at the Android OS level.
No configuration in `speech_to_text` can override it. Workarounds (e.g.,
restarting the listener) introduce gaps in transcription and audible UX
interruptions.

### Option B — Unified pipeline with Groq Whisper (chosen)

**Why selected:** Removes the OS ceiling entirely — audio recording is
controlled by the application, not by Android's SpeechRecognizer lifecycle.
Groq Whisper large-v3-turbo provides better code-switching accuracy than
Android SpeechRecognizer. Single mic holder eliminates the hardware conflict.

---

## Consequences

### Positive

- PTT sessions can be arbitrarily long — no OS ceiling.
- Actual Silero VAD drives always-on turn detection — not OS timeout heuristics.
- Groq Whisper accuracy for code-switching (Arabic + English + Spanish) is
  significantly better than Android SpeechRecognizer.
- STT and VAD run from one audio stream — no mic hardware conflict.

### Negative / tradeoffs

- STT is now a cloud call (Groq Whisper) rather than on-device. Adds ~175ms
  latency per exchange. This was always the PRD target latency and is within
  the 600ms P95 budget.
- Groq Whisper uses the user's Groq API key audio quota: ~7,200 sec/day.
  A 1-hour session uses ~50% of that quota.
- Live partial transcript (word-by-word display while speaking) is no longer
  available. Replace with audio waveform or "Listening..." indicator during
  recording, then transcript appears after Whisper returns.
- Implementation complexity is higher than `speech_to_text`. WAV header
  construction and multipart upload required in `GroqSttDatasource`.

### Constraints introduced

- `SherpaVadDatasource` must emit `Stream<Uint8List>` (complete utterance
  audio buffers) in addition to `Stream<bool>` (voice activity).
  The `VadRepository` interface may need an additional method or a new
  combined stream type.
- 16kHz mono PCM is required by Silero VAD. Audio recording config must
  match exactly.

---

## Links

- GitHub Issue: ARCH-101 — Resolve Audio Pipeline Deadlock & Native STT Cutoffs
  (full root cause analysis)
- ADR-001 (Android SpeechRecognizer — superseded by this decision)
- PRD v0.3 § ADL-001 (original Groq Whisper STT decision — now reinstated)
- Sprint 3 implementation guide (forthcoming)
