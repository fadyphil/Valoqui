# ADR-007: Conversation History — Rolling 8-Turn Window

**Date:** 2026-03
**Status:** Accepted
**Sprint:** Sprint 2
**Decider:** Fady

---

## Context

Each LLM request must include conversation history for Lucia to maintain
context. Without history, every response ignores what was said previously.
With full history, each request grows larger as the session progresses,
increasing latency and token consumption for every exchange.

Groq free tier quota: ~500,000 tokens/day. A 1-hour session with full history
accumulation could exceed this. Consistent per-exchange cost is required to
make quota math predictable.

---

## Decision

`SpeakingBloc` maintains two separate lists:

1. `_history` — rolling window of the last 8 conversation turns, sent to the
   LLM with every request. Oldest turn removed when length exceeds 8.
2. `_fullTranscript` — complete session transcript, never truncated, used
   only for post-session report generation.

Target per-exchange token cost: ~1,430 tokens regardless of session length.

---

## Alternatives considered

### Option A — Full history per request

**Why considered:** Maximum context coherence.
**Why rejected:** By turn 20, a request sends ~3,000+ tokens of context for
a ~100-token reply. Latency increases monotonically through the session.
Quota consumption becomes unpredictable.

### Option B — Rolling 8-turn window (chosen)

**Why selected:** Every request is the same size regardless of session length.
Quota math is predictable. 8 turns preserves sufficient context for natural
conversation flow — enough to remember what was discussed a minute ago.

### Option C — Summarisation approach

**Why considered:** LLM summarises earlier conversation, summary prepended
to each request.
**Why rejected:** Requires an additional API call per N turns. Adds latency
and complexity disproportionate to the benefit at MVP scale.

---

## Consequences

### Positive

- Consistent ~1,430 tokens/exchange throughout the entire session.
- Quota math: 1-hour session = ~257,400 tokens = ~51% of Groq daily limit.
- Latency is predictable — no per-exchange growth.

### Negative / tradeoffs

- Lucia may lose memory of something said more than ~4 exchanges ago. For
  typical 20–30 minute sessions this is acceptable.
- The full transcript is still captured separately for report generation —
  report quality is not affected by the rolling window.

---

## Links

- PRD v0.3 § ADL-006 (conversation history strategy), § 14 (quota math)
- Sprint 2 Guide § 9.3 `speaking_bloc.dart` (`_history`, `_fullTranscript`)
