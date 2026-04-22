# ADR-013: TTS Warm-Up Optimization

**Date:** 2026-04-21  
**Status:** Accepted  
**Sprint:** Sprint 2  
**Decider:** Fady  

---

## Context

The Valoqui speaking pipeline suffers from significant latency, particularly in the TTS stage. Performance analysis revealed that the TTS engine experiences a "cold start" delay of 500-2000ms on first use due to:

- Model loading from disk
- First synthesis pass initialization  
- Player preparation

This delay occurs after the user has finished speaking, STT has decoded the utterance, and LLM has generated a response, significantly impacting perceived responsiveness.

Current flow:

```Markdown
User speaks → VAD detects end → STT decodes (~2-4s) → LLM streams tokens → 
Sentence boundary detected → TTS speak() (cold start delay) → Audio plays
```

## Decision

We will implement a TTS warm-up mechanism that pre-initializes the TTS engine during LLM generation to overlap initialization with other processing stages.

Specifically:

1. Added `warmUp()` method to `TtsRepository` interface and `SherpaTtsDatasource`
2. Modified `SherpaTtsDatasource.warmUp()` to perform a silent synthesis pass
3. Updated `SherpaTtsRepository` to delegate warm-up to datasource
4. Modified `SpeakingBloc._streamLlmResponse()` to call `_tts.warmUp()` when LLM streaming begins

New flow:

```Markdown
User speaks → VAD detects end → STT decodes (~2-4s) → 
LLM streams tokens → [TTS warmUp() called in background] → 
Sentence boundary detected → TTS speak() (already warmed) → Audio plays
```

## Alternatives considered

### Option A — No warm-up, accept cold start latency

**Why considered:** Simplest implementation, no code changes
**Why rejected:** Results in poor user experience with noticeable delays after each utterance

### Option B — Warm-up at session start only

**Why considered:** Would eliminate cold start for first utterance
**Why rejected:**

- Doesn't help if TTS engine is disposed and recreated
- Still causes delay if significant time passes between session start and first use
- Less effective than warming during actual LLM generation

### Option C — Warm-up on first speak() call (lazy initialization)

**Why considered:** Automatic, no explicit calls needed
**Why rejected:**

- Still causes delay on first utterance
- Doesn't overlap with other processing
- Less predictable performance

## Consequences

### Positive

- Eliminates 500-2000ms TTS cold start delay
- Overlaps TTS initialization with LLM generation (free performance gain)
- Minimal implementation complexity (single method addition)
- Maintains backward compatibility
- Follows existing pattern of repository-based service delegation

### Negative / tradeoffs

- Slight increase in code complexity
- Minimal CPU usage during warm-up (negligible impact)
- Requires calling warm-up at appropriate times in the BLoC

### Constraints introduced

- Must ensure TTS repository is initialized before calling warm-up
- Warm-up should not be called excessively (though implementation is idempotent)

---

## Links

- Pipeline performance analysis: `pipeline-performance-analysis.md` (Bottleneck #1)
- Implementation files:
  - `lib/core/data/datasources/sherpa_tts_datasource.dart`
  - `lib/core/domain/repositories/tts_repository.dart`  
  - `lib/core/data/repositories/sherpa_tts_repository.dart`
  - `lib/features/speaking/bloc/speaking_bloc.dart`
- Related ADRs: ADR-011 (STT performance), ADR-012 (Supertonic TTS)
