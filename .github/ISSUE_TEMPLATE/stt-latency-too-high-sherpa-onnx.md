---
name: 🐛 Bug: STT Transcription Latency Too High (sherpa-onnx)
about: Transcription takes 3-5 seconds, breaking conversational flow
title: '[Bug] STT latency unacceptable - 3-5s delay after speaking'
labels: ['bug', 'performance', 'stt', 'critical', 'sprint-3']
assignees: ''
---

## Bug Report

**Severity:** Critical
**Priority:** P0 - Blocks Sprint 3
**Component:** `SherpaSttDatasource`
**Related ADR:** ADR-012 (STT Performance Overhaul)
**First Observed:** Sprint 2 MVP testing

## Current Behavior

When user speaks an utterance:

1. VAD detects speech start ✅
2. Audio buffered during speech ✅
3. VAD detects silence (speech end) ✅
4. **⏳ WAIT 2-4 seconds** (decoding happens here)
5. Transcript appears in UI ❌ (unacceptable delay)

**Measured latencies (mid-range device, Android 13):**

| Utterance Length | Time-to-Transcript | Expected |
| ------------------ | ------------------- | ---------- |
| "Hello" (0.5s) | 2.1s | < 0.8s |
| "What is the weather today?" (2s) | 3.8s | < 1.5s |
| 5-second sentence | 5.2s | < 2.0s |

## Expected Behavior

Conversational transcription should feel immediate:

- **Partial transcripts:** Appear within 500ms of speech start
- **Final transcript:** Confirmed within 1.5s of speech end
- **Perceived latency:** User sees text building as they speak

## Steps to Reproduce

1. Launch app on physical device (not emulator)
2. Navigate to speaking feature
3. Tap microphone button
4. Speak a complete sentence (e.g., "What is the capital of France?")
5. Stop speaking and wait for silence detection
6. Observe delay before transcript appears

**Reproduction rate:** 100% (all devices tested)

## Root Cause Analysis

### Primary Cause: Sequential Buffering

Current implementation (`sherpa_stt_datasource.dart`):

```dart
// Simplified current flow
await vad.waitForSpeech();      // Block until speech detected
await vad.waitForSilence();     // Block until silence (full utterance buffered)
final transcript = await _decode(fullBuffer); // Decode entire buffer at once
yield transcript;               // Only now does UI receive transcript
```

**Problem:** User must wait for complete silence + full decoding before seeing any output.

### Secondary Cause: Model Inference Speed

- sherpa-onnx Moonshine base model: ~40MB parameters
- Single-threaded CPU inference on mobile
- No incremental/early-exit optimization

### Tertiary Cause: No Streaming Architecture

- Current design: batch processing only
- No partial result emission during decoding
- UI has no intermediate states ("listening...", "processing...")

## Impact

**User Experience:**

- Conversational flow completely broken
- Users report "feels like app froze" or "is it listening?"
- Beta testers abandon voice feature after 2-3 attempts
- Perceived as "broken" despite technically working

**Business Metrics:**

- Voice feature adoption: < 15% of beta users
- Session duration: 40% shorter when using voice vs. text input
- User complaints: #1 reported issue in Sprint 2 feedback

## Technical Details

**Affected Files:**

- `lib/core/data/datasources/sherpa_stt_datasource.dart` (primary)
- `lib/core/data/repositories/sherpa_stt_repository.dart` (secondary)
- `lib/features/speaking/presentation/speaking_bloc.dart` (UI state handling)

**Device Configurations Tested:**

| Device | Android | RAM | CPU | Latency |
| -------- | --------- | ----- | ----- | --------- |
| Pixel 6 | 13 | 8GB | Tensor G2 | 2.8s avg |
| Samsung A52 | 12 | 6GB | Snapdragon 720G | 3.5s avg |
| Redmi Note 9 | 11 | 4GB | Helio G85 | 4.2s avg |

**Performance Profile:**

```Markdown
[0.0s] Speech starts
[0.5s] VAD detects speech, buffering begins
[2.5s] User stops speaking
[2.7s] VAD detects silence, buffering ends
[2.7s → 5.2s] Decoding happens HERE (2.5s blocked)
[5.2s] Transcript yielded to BLoC, UI updates
```

## Proposed Fix

See companion feature request: `sprint-3-stt-performance-overhaul.md`

**Summary:**

1. Implement chunked streaming (500ms chunks with overlap)
2. Emit partial transcripts incrementally
3. Evaluate Whisper.cpp for faster inference
4. Add UI states for "listening", "partial", "confirmed"

## Workarounds (Temporary)

None available. This requires architectural changes to the STT pipeline.

**Mitigation for beta testing:**

- Inform users "voice feature is experimental, expect delays"
- Provide text input fallback prominently
- Limit beta tester expectations in onboarding

## Acceptance Criteria for Fix

- [ ] Partial transcript appears within 500ms of speech start
- [ ] Final transcript confirmed within 1.5s of speech end
- [ ] No regression in Word Error Rate (>90% accuracy maintained)
- [ ] Works on low-end devices (2GB RAM, quad-core A53)
- [ ] Battery drain increase < 10% during active use

## Related Issues

- **Blocks:** Sprint 3 success criteria
- **Related to:** ADR-011 (Supertonic TTS) - shared audio pipeline
- **Historical context:** ADR-001 documents original STT decision
- **Engineering lessons:** `docs/extras/sprint-2/lessons learnt/engineering_lessons.md` §1

## Attachments

- [ ] Performance profiling logs (to be added)
- [ ] Screen recording of latency (to be added)
- [ ] Beta tester feedback compilation (to be added)

## Notes

⚠️ **This is the highest-priority bug from Sprint 2.** Multiple beta testers cited this as reason for abandoning voice feature entirely.

⚠️ **Do not attempt quick fixes** like reducing model size without benchmarking accuracy impact. This requires thoughtful architectural redesign.
