# ADR-009: Post-Session Report Generation — Single LLM Call, Structured JSON

**Date:** 2026-03
**Status:** Accepted
**Sprint:** Sprint 2 (Sprint 3)
**Decider:** Fady

---

## Context

Valoqui's DELE-aligned report card requires grading fluency, grammar, and
vocabulary; identifying specific mistakes with corrections; generating tutor
notes; and calculating XP. This grading must happen without interrupting the
conversation and must produce machine-parseable output for the report card UI.

---

## Decision

After the user taps "End Session", `ReportBloc` sends a single non-streaming
POST to Groq with the full session transcript and a structured JSON prompt.
The prompt explicitly instructs the model to return raw JSON with no markdown
fences. The response is parsed directly into `SessionReport` (Freezed model).
Retry logic: up to 3 attempts with exponential backoff. On total failure:
fallback to a basic completion screen showing only client-calculated XP.

---

## Alternatives considered

### Option A — Real-time per-turn grading during session

**Why considered:** Immediate feedback after each exchange.
**Why rejected:** Cognitively intrusive. Adds an API call and latency to every
exchange. Disrupts conversation flow. Deferred to post-MVP.

### Option B — Single post-session call (chosen)

**Why selected:** User focuses on conversation, not grade. One API call is
cheaper and simpler. Full transcript context produces better evaluation than
per-turn analysis.

---

## Consequences

### Positive

- Report generation does not affect conversation latency.
- Full transcript context gives the LLM maximum information for accurate DELE
  evaluation.

### Negative / tradeoffs

- LLMs occasionally return malformed JSON despite explicit instructions.
  Retry logic and markdown fence stripping are required in `_parseReport`.
- Report appears 3–10 seconds after session end. Loading state required.

### Constraints introduced

- `temperature: 0.3` for report generation (vs. `0.8` for conversation) to
  improve JSON structure reliability.
- `max_tokens: 2000` for report calls (vs. `120` for conversation).
- XP is calculated by the LLM and cross-checked client-side.

---

## Links

- PRD v0.3 § ADL-010, § 10 (report card spec), § 11 (XP system)
- Sprint 2 Guide § 10 (ReportBloc), § 7 (SessionReport model)
