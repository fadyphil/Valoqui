---
name: 🚀 Feature: Sprint 3 - Supertonic TTS Integration
about: Replace Piper TTS with Supertonic system service for natural-sounding speech
title: '[Sprint 3] Integrate Supertonic TTS engine'
labels: ['sprint-3', 'tts', 'feature', 'performance']
assignees: ''
---

## Feature Decision Record

**Related ADR:** ADR-011
**Priority:** High
**Sprint:** 3
**Estimated Effort:** 5 days

## Problem Statement

Current Piper TTS implementation has limitations:

- Robotic voice quality affects user engagement
- Large model files (~77MB) impact app size
- Limited voice variety and prosody control
- On-device inference adds latency

Supertonic (tested separately on device) provides:

- ✅ Natural, human-like voice quality
- ✅ System-level integration (no bundled models)
- ✅ Multiple voice options
- ✅ Potentially lower latency via system optimization

## Proposed Solution

Replace `PiperTtsDatasource` with `SupertonicTtsDatasource` that:

1. Interfaces with Android's TextToSpeech service configured with Supertonic engine
2. Maintains existing `TtsRepository` contract (no domain layer changes)
3. Falls back to Piper if Supertonic unavailable (graceful degradation)

### Implementation Approach

```dart
// Pseudo-code structure
class SupertonicTtsDatasource implements TtsDatasource {
  final TextToSpeech _tts; // Android system TTS
  final String _supertonicEngine = "com.supertonic.engine";

  @override
  Future<void> speak(String text) async {
    // Check if Supertonic engine available
    final isAvailable = await _checkEngineAvailability();
    if (!isAvailable) {
      throw TtsEngineUnavailableException('Supertonic not installed');
    }

    // Configure voice parameters
    await _setVoiceParams(voice: 'natural-female', rate: 1.0);

    // Speak via system service
    await _tts.speak(text, queueMode: QUEUE_FLUSH);
  }
}
```

## Acceptance Criteria

- [ ] Supertonic engine availability check implemented
- [ ] Fallback to Piper TTS if Supertonic unavailable
- [ ] Voice quality tested with sample sentences (MOS score ≥ 4.0)
- [ ] Latency measured: time-to-first-audio < 200ms
- [ ] No increase in APK size (system service, no bundled models)
- [ ] Existing TTS tests pass with new datasource
- [ ] Setup docs updated (remove Piper model download instructions)

## Technical Spikes Required

### Spike 1: Supertonic Integration Method (2 days)

**Goal:** Determine how to interface with Supertonic

- [ ] Is it a standalone app with Intent-based communication?
- [ ] Does it provide an SDK/library?
- [ ] Can it be configured as default TTS engine programmatically?
- [ ] What permissions are required?

**Deliverable:** `docs/spikes/supertonic-integration-method.md`

### Spike 2: Voice Parameter Mapping (1 day)

**Goal:** Map Lingua's voice requirements to Supertonic capabilities

- [ ] Available voices list
- [ ] Pitch/rate/speed controls
- [ ] Language support (English primary, others secondary)

**Deliverable:** `docs/spikes/supertonic-voice-params.md`

## Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
| ------ | -------- | ------------- | ------------ |
| Supertonic requires root/unusual permissions | High | Medium | Fallback to Piper, document requirement |
| Supertonic not available on all Android versions | Medium | High | API level checks, graceful fallback |
| Latency worse than expected | High | Low | Benchmark early, revert to Piper if needed |
| Supertonic app discontinued/abandoned | Medium | Low | Keep Piper integration as permanent fallback |

## Dependencies

- **Blocks:** None
- **Blocked by:** Spike 1 completion (integration method)
- **Related:** ADR-012 (STT Performance Overhaul) - concurrent work

## Success Metrics

1. **Voice Quality:** MOS score ≥ 4.0 (vs. Piper's ~3.2)
2. **Latency:** Time-to-first-audio < 200ms (vs. Piper's ~400ms)
3. **APK Size:** Reduction of ~77MB (no bundled model)
4. **User Feedback:** Positive response in beta testing

## References

- Supertonic App: [Play Store Link / GitHub Repo]
- Android TTS Documentation: <https://developer.android.com/reference/android/speech/tts/TextToSpeech>
- ADR-003: Original Piper TTS decision (to be superseded)
- Test results from dedicated Supertonic app (attach screenshots/audio samples)

## Notes

⚠️ **Important:** This feature requires physical device testing. Emulator TTS behavior may differ significantly from real devices with Supertonic installed.
