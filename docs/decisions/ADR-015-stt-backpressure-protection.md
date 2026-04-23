# ADR-015: Isolate Backpressure & Buffer Safety

**Date:** April 2026  
**Status:** Accepted  
**Author:** Development Team  

## Summary

Implement isolate queue bounding and load shedding to prevent memory leaks and OOM crashes during heavy STT decoding.

## Context

The STT pipeline uses a background isolate for Moonshine decoding. Unbounded requests could lead to OOM crashes or massive latency spikes if the isolate falls behind real-time speech.

## Decision

Implement **Isolate Queue Bounding** and **Load Shedding**:

1. **Backpressure Limit:** Introduced a hard cap of 3 concurrent decodes (`_maxDecodeQueue = 3`) in the isolate wrapper.
2. **Load Shedding:** If the queue is full, new segments are dropped with an empty string response to prioritize system stability.
3. **PTT Buffer Capping:** Audio recording in PTT mode is capped at 60 seconds.
4. **Visual Warning:** The `MicButton` UI visualizes the buffer fill percentage, changing color to red as the 60s limit approaches.

## Consequences

- ✅ **Crash Prevention:** Eliminates OOM due to isolate mailbox flooding.
- ✅ **Deterministic Latency:** Isolate only works on the most relevant (recent) segments.
- ✅ **Transparency:** Users are warned before their recording is cut off.
