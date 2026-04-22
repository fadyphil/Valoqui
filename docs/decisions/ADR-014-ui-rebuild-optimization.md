# ADR-014: UI Rebuild Optimization (Token Batching)

**Date:** April 2026  
**Status:** Accepted  
**Author:** Development Team  

## Context

LLM response tokens stream in at high frequency (50-100Hz). Emitting a new BLoC state for every token caused the entire `SpeakingScreen` to rebuild constantly, leading to UI jank and high CPU usage.

## Decision

Implement **UI Throttling (Batching)** and **Scoped Rebuilds**:

1. **Throttling (10Hz):** Tokens are accumulated in a private buffer. A timer dispatches a state update every 100ms, consolidating multiple tokens.
2. **Scoped Rebuilds (BlocSelector):** The active Lucia message bubble uses a `BlocSelector` to listen strictly to the token buffer, preventing the rest of the screen from redrawing.
3. **Instant Audio:** Sentence-boundary detection for TTS remains immediate (0ms delay) to ensure audio responsiveness is unaffected by UI batching.

## Consequences

- ✅ **Butter-smooth animations:** 60FPS maintained during streaming.
- ✅ **CPU Efficiency:** Rebuild frequency reduced by 90%.
- ✅ **Minimal Perception Impact:** 100ms is faster than human reading speed.
