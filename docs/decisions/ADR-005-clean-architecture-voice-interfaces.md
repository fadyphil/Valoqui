# ADR-005: Clean Architecture Swap Pattern — Domain Interfaces for All Voice Components

**Date:** 2026-03
**Status:** Accepted
**Sprint:** Sprint 2
**Decider:** Fady

---

## Context

The voice pipeline has four independently replaceable components: STT, TTS,
VAD, and LLM. Each component has at least one planned upgrade (STT: Android →
Groq Whisper; TTS: Piper → F5-TTS; LLM: fallback strategy). Without
architectural isolation, each swap risks cascading changes through the BLoC,
screens, and tests.

---

## Decision

Every voice component is hidden behind a domain interface. The BLoC depends
only on interfaces, never on concrete implementations.

```
SttRepository         ← interface (domain)
    ↑
AndroidSttRepository  ← Sprint 2 concrete
GroqSttRepository     ← Sprint 3 swap-in

TtsRepository         ← interface (domain)
    ↑
SherpaTtsRepository   ← Sprint 2 (Piper)
F5TtsRepository       ← Sprint 3 swap-in

VadRepository         ← interface (domain)
    ↑
SherpaVadRepository   ← Sprint 2

LlmRepository         ← interface (domain)
    ↑
GroqLlmRepository     ← Sprint 2 (handles Gemini fallback internally)
```

Swapping any component = one new datasource file + one new repository file +
one line change in `service_locator.dart`. Zero upstream impact.

---

## Consequences

### Positive
- STT swap in Sprint 3 (Android → Groq Whisper, per ARCH-101) requires
  writing `GroqSttDatasource` and `GroqSttRepository`. `SpeakingBloc`,
  `SpeakingScreen`, and all tests are completely unchanged.
- TTS swap (Piper → F5-TTS) follows the identical pattern.
- Every repository is independently mockable in tests via `mocktail`.

### Negative / tradeoffs
- More files per component (datasource + repository + interface) compared to
  a direct implementation. Acceptable given the known swap schedule.

---

## Links
- Sprint 2 Guide § 2.2 (domain interfaces and swap architecture)
- Sprint 2 Guide § 5 (domain layer interfaces)
- Sprint 2 Guide § 11 (service locator updates)
- ADR-001 (STT — swap planned Sprint 3)
- ADR-003 (TTS — swap planned Sprint 3)
- GitHub Issue: ARCH-101
