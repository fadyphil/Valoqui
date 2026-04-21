# ADR-001: STT Provider — Android SpeechRecognizer via speech_to_text

**Date:** 2026-03
**Status:** Accepted — under re-evaluation (see ADR-010, ADR-011, ARCH-101)
**Sprint:** Sprint 2
**Decider:** Fady

---

## Context

Valoqui requires speech-to-text that satisfies three constraints simultaneously:

1. **Code-switching support** — users speak Arabic, English, and Spanish mixed
   within a single utterance. This is a core product requirement for personas
   like Layla (heritage speaker).
2. **Zero developer cost** — the BYOK model means STT must be either on-device
   or routed through the user's own API key.
3. **Latency budget** — total pipeline (VAD → STT → LLM first token → TTS first
   sentence) must land under 600ms P95.

The PRD v0.3 originally specified Groq Whisper large-v3-turbo for STT. Sprint 2
re-evaluated this against Android SpeechRecognizer before committing to a cloud
STT dependency.

---

## Decision

Valoqui Sprint 2 uses Android SpeechRecognizer via the `speech_to_text` package
as the STT engine. Groq Whisper remains the planned Sprint 3 upgrade path and is
already abstracted behind `SttRepository`.

---

## Alternatives considered

### Option A — Groq Whisper large-v3-turbo (original PRD spec)

**Why considered:** Handles code-switching accurately. Same API key already
required for LLM — no additional BYOK friction. Groq STT latency ~175ms.
**Why rejected for Sprint 2:** Requires recording raw audio, Opus encoding,
multipart HTTP upload, and response parsing — significant implementation
complexity. Android SpeechRecognizer provides the same outcome for Sprint 2
with far less code, allowing the conversation loop to be validated first.
Deferred to Sprint 3 behind the existing `SttRepository` interface.

### Option B — On-device Whisper (tiny / base via sherpa-onnx)

**Why considered:** Fully offline, zero network cost.
**Why rejected:** Documented failure on code-switching in small models. Adding
a ~74–244MB model to the APK for inferior quality is not acceptable.

### Option C — Android SpeechRecognizer (chosen)

**Why considered:** Zero implementation cost — `speech_to_text` package
abstracts the Android API. No model bundled. Works for both Spanish and English
input without locale configuration (auto-detect).
**Why selected:** Sufficient for Sprint 2 pipeline validation. Fully replaceable
via `SttRepository` interface when Groq Whisper is integrated in Sprint 3.

---

## Consequences

### Positive

- Sprint 2 conversation loop implemented without cloud STT complexity.
- `SttRepository` interface already written — STT swap in Sprint 3 touches
  exactly one datasource file and one line in `service_locator.dart`.

### Negative / tradeoffs

- Android SpeechRecognizer has a hard ~7-second OS ceiling on any single
  listening session. This cannot be overridden via the `speech_to_text`
  package. Long user utterances are cut off.
- Always-on mode is degraded: VAD and SpeechRecognizer cannot hold the
  microphone simultaneously. VAD was removed from always-on mode to eliminate
  this hardware conflict, leaving turn detection dependent on the OS.
- Code-switching accuracy is lower than Groq Whisper large-v3-turbo.

### Constraints introduced

- Any fix to the 7-second cutoff must operate at a different architectural
  layer (unified audio pipeline — see ARCH-101) rather than via
  `speech_to_text` configuration.

---

## Links

- PRD v0.3 § ADL-001 (original Groq Whisper decision)
- Sprint 2 Guide § 6.1 `android_stt_datasource.dart`
- GitHub Issue: ARCH-101 — Resolve Audio Pipeline Deadlock & Native STT Cutoffs
- ADR-010 — Unified Audio Pipeline (supersedes this decision for Sprint 3)
- ADR-011 — STT Performance Optimization (chunked streaming approach)
