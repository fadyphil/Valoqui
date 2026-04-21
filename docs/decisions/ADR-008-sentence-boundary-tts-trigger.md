# ADR-008: Sentence-Boundary TTS Trigger

**Date:** 2026-03
**Status:** Accepted
**Sprint:** Sprint 2
**Decider:** Fady

---

## Context

Waiting for the full LLM response before starting TTS playback means the
user waits for the entire reply to generate before hearing anything. At Groq's
~280 tokens/second, a 3-sentence reply (~60 tokens) takes ~215ms to complete
generation. Starting TTS only after that adds another ~50ms. Total perceived
latency from speech end to first audio: ~600ms+.

The target is ≤350ms P50, ≤600ms P95. TTS must begin before the full response
has arrived.

---

## Decision

`SpeakingBloc` accumulates LLM stream tokens in `currentLuciaBuffer`. On
every token received, it checks if the token ends with `.`, `?`, or `!`. When
a sentence boundary is detected, `TtsRepository.speak()` is called immediately
with the accumulated buffer, and the buffer is cleared. TTS for the first
sentence begins before subsequent sentences have been generated.

---

## Consequences

### Positive

- Perceived latency: STT (~175ms) + LLM first sentence (~100ms) + TTS (~50ms)
  = ~325ms. Within the P50 target of 350ms.

### Negative / tradeoffs

- If Lucia's reply does not end with punctuation, remaining text in the buffer
  is spoken after `_LlmResponseComplete` fires. Edge case handled in BLoC.
- TTS may speak a first sentence whose meaning changes with the second
  sentence. Not a problem for 2–3 sentence conversational replies.

### Known pitfalls

- `maxNumSentences: 1` in sherpa-onnx config truncates at internal
  punctuation. Must be set to 100.
- TTS output filename must rotate per sentence (sentence_0.wav, sentence_1.wav)
  to prevent `just_audio` cache serving stale audio.

---

## Links

- PRD v0.3 § 5 (pipeline), § 14 (pseudocode)
- Sprint 2 Guide § 9.3 `_onLlmTokenReceived`, `_onLlmResponseComplete`
