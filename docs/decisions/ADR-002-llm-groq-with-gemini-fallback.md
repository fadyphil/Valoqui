# ADR-002: LLM Provider — Groq LLaMA 3.3 70B with Gemini 2.5 Flash Fallback

**Date:** 2026-03
**Status:** Accepted
**Sprint:** Sprint 2
**Decider:** Fady

---

## Context

The LLM powers Lucia's conversational responses and post-session report
generation. Requirements:

- Fast enough for real-time streaming sentence-boundary TTS — first token
  must arrive in ~100–200ms.
- Intelligent enough to evaluate Spanish grammar against the Instituto
  Cervantes DELE rubric in the report card.
- Free to operate — BYOK model, routed through the user's own account.
- Resilient — a single provider is a single point of failure.

---

## Decision

Valoqui uses Groq LLaMA 3.3 70B Versatile as the primary LLM with streaming
enabled. Google Gemini 2.5 Flash is the silent fallback on any Groq 429
(rate limit) response. Fallback logic lives entirely inside
`GroqLlmRepository` — the BLoC and all callers see only `LlmRepository`.

---

## Alternatives considered

### Option A — OpenAI GPT-4o

**Why considered:** Best-in-class instruction following and Spanish evaluation.
**Why rejected:** Paid API. Defeats the BYOK free-forever model. Developer
cost at scale is unsustainable.

### Option B — On-device small LLM (Phi-3, Gemma 2B via llama.cpp)

**Why considered:** Zero network cost, works offline.
**Why rejected:** 2–7B parameter models lack the reasoning depth required to
evaluate Spanish grammar against formal DELE rubrics and generate structured
JSON report cards reliably. Quality bar not met.

### Option C — Groq LLaMA 3.3 70B (chosen primary)

**Why selected:** Groq's LPU hardware generates ~280 tokens/second — fast
enough for sentence-boundary streaming TTS. 70B parameter size is sufficient
for DELE-level evaluation. Free on user's own Groq account (~500k tokens/day).

### Option D — Gemini 2.5 Flash (chosen fallback)

**Why considered as fallback:** Independent provider. Free tier of ~1M
tokens/day. Google infrastructure has different failure modes than Groq,
making simultaneous outage extremely unlikely.
**Why not primary:** Groq's LPU latency is structurally faster than Gemini's
standard inference for first-token time.

---

## Consequences

### Positive

- Combined daily token budget (Groq + Gemini): ~1.5M tokens ≈ 5–6 hours
  of practice before any limit is hit.
- User never sees an error unless both providers fail simultaneously
  (probability: very low).
- Fallback is transparent — no UI change, no session interruption.

### Negative / tradeoffs

- Groq free tier limits are set per user account, not per app. If Groq
  changes their free tier, users are directly affected.
- Gemini fallback requires a second key in BYOK setup. Optional but creates
  a two-key onboarding step.
- Two different API response shapes (Groq OpenAI-compatible SSE vs. Gemini
  SSE) require two datasources and translation logic in the repository.

### Constraints introduced

- `LlmRepository.streamResponse()` must never expose which provider is
  responding. The BLoC is provider-agnostic by design.
- Report generation uses `temperature: 0.3` (lower than conversation `0.8`)
  to improve JSON structure reliability.

---

## Links

- PRD v0.3 § ADL-002 (LLM provider), § ADL-007 (fallback provider)
- Sprint 2 Guide § 6.3 `groq_llm_datasource.dart`
- Sprint 2 Guide § 6.4 `gemini_llm_datasource.dart`
- Sprint 2 Guide § 6.5 `groq_llm_repository.dart`
