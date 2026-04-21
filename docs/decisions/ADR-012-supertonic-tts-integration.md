# ADR-012: Supertonic TTS Integration Strategy

**Date:** April 2026  
**Status:** Proposed  
**Author:** Development Team  
**Replaces:** Supersedes ADR-003 (Piper to F5-TTS transition)

## Context

The current Sprint 2 implementation uses Piper TTS (via sherpa-onnx) for text-to-speech synthesis. While functional, user feedback and comparative testing have identified limitations:

- **Voice quality:** Piper voices sound robotic and lack natural prosody
- **Language support:** Limited Arabic voice options with poor code-switching handling
- **Synthesis speed:** 800ms-1.5s latency from text input to audio output
- **Customization:** Limited control over speech rate, pitch, and emphasis

Independent testing of **Supertonic TTS** (via dedicated app) has demonstrated significantly superior results:

- **Natural voice quality:** Near-human prosody and intonation
- **Arabic support:** Excellent Modern Standard Arabic with dialect flexibility
- **Code-switching:** Seamless Arabic-English mixing within sentences
- **Latency:** ~300-500ms from text to speech start (perceived as "instant")
- **Emotion control:** Supports expressive speech (happy, sad, urgent, calm)

However, Supertonic integration approach is not yet fully understood. This ADR documents the research plan and integration strategy.

## Decision Drivers

- **Voice Quality:** Primary driver — users notice and appreciate natural-sounding voices
- **Latency:** Reduce TTS synthesis time by 50%+ compared to Piper
- **Arabic Support:** Critical requirement for Lingua's target market
- **Integration Complexity:** Must be feasible within Sprint 3 timeline (10 days)
- **Offline Capability:** Prefer on-device or local network solution (privacy requirement)
- **License/Cost:** Must be compatible with open-source project constraints
- **API Stability:** Avoid dependencies on unstable or undocumented APIs

## Research Status

**Current Knowledge (April 2026):**
- ✅ Supertonic TTS app tested on Android device with excellent results
- ✅ App demonstrates real-time synthesis with low latency
- ✅ Voice quality significantly exceeds Piper/F5-TTS expectations
- ❌ Integration method unknown (system service? SDK? Local HTTP server?)
- ❌ Licensing terms not yet reviewed
- ❌ No public documentation found for programmatic access
- ❌ Unclear if Supertonic provides official Android SDK or requires reverse engineering

**Research Tasks (Days 1-2 of Sprint 3):**
1. Investigate Supertonic app architecture (APK analysis, manifest permissions)
2. Check for official Supertonic SDK or developer API
3. Test if Supertonic exposes local HTTP endpoint (like many TTS apps)
4. Review licensing terms and commercial use restrictions
5. Benchmark latency and quality vs. current Piper implementation
6. Evaluate offline capability (does it require cloud API calls?)

## Considered Options

### Option 1: Official Supertonic SDK Integration
If Supertonic provides an official Android SDK

**Pros:**
- Clean, supported integration path
- Stable API with version guarantees
- Documentation and example code available
- Likely optimized performance
- Legal clarity on licensing

**Cons:**
- May require paid license for commercial use
- SDK might not exist (Supertonic may be app-only)
- Potential vendor lock-in
- Dependency on third-party update cycle

**Estimated Effort:** 2-3 days (if SDK exists)

### Option 2: Local HTTP Server Integration
If Supertonic runs a local HTTP server (common pattern for TTS apps)

**Pros:**
- No SDK required — simple HTTP POST requests
- Language-agnostic (works with any HTTP client)
- Easy to test and debug
- Can fall back to Piper if Supertonic unavailable

**Cons:**
- Undocumented API (requires reverse engineering)
- May break with app updates
- Potential security concerns (localhost communication)
- Need to ensure Supertonic app is installed and running
- Additional APK size if bundling Supertonic

**Estimated Effort:** 3-4 days (including reverse engineering)

**Implementation Pattern:**
```dart
class SupertonicTtsDatasource implements TtsDatasource {
  final http.Client _client = http.Client();
  static const String baseUrl = 'http://127.0.0.1:8888'; // Hypothetical port
  
  @override
  Future<void> speak(String text, {String? language, double? rate}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/synthesize'),
      body: jsonEncode({
        'text': text,
        'language': language ?? 'ar-SA',
        'rate': rate ?? 1.0,
        'voice': 'default',
      }),
    );
    
    if (response.statusCode == 200) {
      final audioData = response.bodyBytes;
      await _audioPlayer.play(audioData);
    } else {
      throw SupertonicException('Synthesis failed: ${response.statusCode}');
    }
  }
}
```

### Option 3: Android TTS System Service Bridge
If Supertonic registers as an Android TTS engine (standard `TextToSpeech.Engine`)

**Pros:**
- Standard Android API (`android.speech.tts.TextToSpeech`)
- No special integration required — works automatically
- User can switch TTS engines in system settings
- Well-documented and stable

**Cons:**
- Requires Supertonic to implement standard TTS engine interface
- May not expose advanced features (emotion, fine-grained control)
- Slightly higher latency due to system service overhead
- Limited to Android platform (no iOS parity)

**Estimated Effort:** 1-2 days (if Supertonic supports standard TTS engine)

**Implementation Pattern:**
```dart
class AndroidSystemTtsDatasource implements TtsDatasource {
  late TextToSpeech _tts;
  
  @override
  Future<void> init() async {
    _tts = TextToSpeech(context, (status) {
      if (status == TextToSpeech.SUCCESS) {
        // Set Supertonic as the engine
        _tts.setEngineByPackageName('com.supertonic.tts');
      }
    });
  }
  
  @override
  Future<void> speak(String text) async {
    _tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, null);
  }
}
```

### Option 4: Hybrid Approach (Supertonic + Piper Fallback)
Support both Supertonic (primary) and Piper (fallback)

**Pros:**
- Graceful degradation if Supertonic unavailable
- Users without Supertonic can still use app
- A/B testing capability
- Migration path for future TTS engines

**Cons:**
- Increased complexity (dual implementation)
- Larger APK if bundling Piper models
- Need feature detection logic
- Inconsistent voice quality between engines

**Estimated Effort:** 4-5 days

### Option 5: Continue with F5-TTS (Original Sprint 3 Plan)
Abandon Supertonic research and proceed with F5-TTS ONNX export

**Pros:**
- Original plan already researched (ADR-003)
- Fully on-device, no external dependencies
- Open-source with clear licensing
- Consistent with offline-first principle

**Cons:**
- F5-TTS ONNX export not yet available (blocking factor)
- Voice quality likely inferior to Supertonic based on demos
- Additional research delay waiting for F5-TTS export tools
- Risk: F5-TTS may not support Arabic well

**Estimated Effort:** 5-7 days (waiting on F5-TTS tooling)

## Decision Outcome

**Selected Approach: Option 4 (Hybrid: Supertonic Primary + Piper Fallback) with Research Phase**

**Rationale:**
1. **User experience first:** Supertonic's superior voice quality justifies integration effort
2. **Risk mitigation:** Piper fallback ensures app remains functional if Supertonic integration fails
3. **Research-driven:** Dedicate Days 1-2 to thorough Supertonic investigation before committing
4. **Flexibility:** Hybrid approach allows gradual migration and A/B testing
5. **Contingency:** If Supertonic proves unfeasible, can pivot to F5-TTS or continue with improved Piper

**Implementation Plan:**

### Phase 0: Supertonic Research (Days 1-2) **[GATE DECISION POINT]**
- Analyze Supertonic APK for integration method
- Test for local HTTP server or system TTS engine registration
- Review licensing terms
- **Go/No-Go Decision:** If Supertonic integration appears feasible → proceed to Phase 1. If blocked → pivot to F5-TTS (Option 5).

### Phase 1: Supertonic Integration (Days 3-5) *[Conditional on Phase 0 success]*
- Implement chosen integration method (SDK, HTTP, or system TTS)
- Create `SupertonicTtsDatasource` conforming to `TtsDatasource` interface
- Add feature detection (is Supertonic installed? is service running?)
- Implement basic text-to-speech functionality
- Test latency and voice quality on target devices

### Phase 2: Fallback & Abstraction (Days 6-7)
- Create `TtsEngine` interface abstracting synthesis logic
- Implement `SupertonicTtsEngine` and `PiperTtsEngine`
- Update `TtsRepository` to support engine switching
- Add user preference for TTS engine selection
- Implement graceful fallback logic

### Phase 3: Polish & Optimization (Days 8-9)
- Tune Supertonic parameters (voice selection, rate, pitch)
- Optimize warm-up time (pre-load voices on app start)
- Add error handling and retry logic
- Implement telemetry for TTS latency tracking
- User testing and feedback collection

### Phase 4: Documentation & Cleanup (Day 10)
- Update SETUP.md with Supertonic installation instructions
- Document fallback behavior for developers
- Remove or deprecate F5-TTS research notes if not proceeding
- Create troubleshooting guide for common Supertonic issues

## Consequences

### Positive
- ✅ Significant voice quality improvement (user satisfaction)
- ✅ Reduced TTS latency (~50% faster than Piper)
- ✅ Excellent Arabic and code-switching support
- ✅ Fallback ensures reliability
- ✅ Architecture supports future TTS engine additions

### Negative
- ⚠️ Dependency on third-party app (Supertonic must be installed)
- ⚠️ Increased APK size if bundling Piper fallback models
- ⚠️ Integration complexity (undocumented API risks)
- ⚠️ Potential licensing restrictions (must verify before release)
- ⚠️ Platform-specific (Android-only unless iOS equivalent found)

### Risks
- 🔴 **Risk:** Supertonic does not provide any programmatic access method  
  **Mitigation:** Pivot to F5-TTS or improved Piper on Day 2 go/no-go decision
  
- 🔴 **Risk:** Supertonic licensing prohibits use in open-source/commercial apps  
  **Mitigation:** Negotiate license or revert to Piper/F5-TTS
  
- 🟡 **Risk:** Supertonic local API changes in future updates, breaking integration  
  **Mitigation:** Version pinning, abstraction layer, comprehensive error handling
  
- 🟡 **Risk:** Supertonic app not available in all regions (Play Store restrictions)  
  **Mitigation:** Provide alternative download links or fallback to Piper

## Metrics for Success

| Metric | Current (Piper) | Target (Supertonic) | Measurement Method |
|--------|-----------------|---------------------|-------------------|
| TTS latency (text to audio start) | 1200ms avg | <500ms avg | Telemetry event `tts_synthesis_time` |
| Voice quality MOS score | 3.2/5.0 | >4.2/5.0 | User survey (1-5 scale) |
| Arabic pronunciation accuracy | 78% | >92% | Manual sample testing |
| Code-switching fluency | Poor (robotic transitions) | Natural (seamless) | Qualitative user feedback |
| Fallback trigger rate | N/A | <5% of sessions | Error telemetry |

## Related Decisions

- **ADR-003:** Original Piper to F5-TTS transition plan (superseded by this decision)
- **ADR-011:** STT Performance Optimization (companion Sprint 3 decision)
- **ADR-010:** Unified Audio Pipeline (context for TTS integration)

## Open Questions

1. Does Supertonic provide an official SDK or developer API?
2. What are Supertonic's licensing terms for integration in open-source projects?
3. Is Supertonic available globally, or restricted to specific regions?
4. Can Supertonic operate fully offline, or does it require cloud API calls?
5. What is the minimum Android API level Supertonic supports?
6. Does Supertonic support custom voice training or only pre-built voices?

## Appendix: Supertonic Investigation Checklist

### APK Analysis
- [ ] Extract AndroidManifest.xml — check for exported services, receivers, providers
- [ ] Look for `TextToSpeech.Engine` service declaration
- [ ] Check for HTTP server permissions or localhost bindings
- [ ] Identify package name and version code
- [ ] Review declared permissions (INTERNET, RECORD_AUDIO, etc.)

### Runtime Testing
- [ ] Install Supertonic app on test device
- [ ] Check if it registers as system TTS engine (Settings → Accessibility → TTS)
- [ ] Use `adb shell dumpsys` to inspect running services
- [ ] Monitor network traffic for localhost HTTP requests (Wireshark/tcpdump)
- [ ] Test synthesis latency with stopwatch timing

### API Discovery
- [ ] Try common local ports (8080, 8888, 5000, 3000)
- [ ] Send test HTTP POST to `/synthesize`, `/tts`, `/speak` endpoints
- [ ] Inspect request/response format (JSON? Protobuf? Raw audio?)
- [ ] Test parameter variations (language, rate, voice selection)
- [ ] Document successful API calls

### Legal & Licensing
- [ ] Review Supertonic Play Store description for API mentions
- [ ] Check Supertonic website for developer documentation
- [ ] Contact Supertonic team for integration inquiries
- [ ] Verify open-source compatibility (GPL, MIT, Apache, proprietary?)
- [ ] Document attribution requirements

---

## Contingency Plan: F5-TTS Fallback

If Supertonic integration proves unfeasible, revert to original F5-TTS plan:

1. **Wait for F5-TTS ONNX export tools** (track upstream repository)
2. **Benchmark F5-TTS vs. Piper** once export available
3. **Implement F5-TTS datasource** following ADR-003 architecture
4. **Document limitations** (Arabic support, voice quality) for stakeholders

**Decision Deadline:** End of Day 2 — must commit to Supertonic or F5-TTS path to meet Sprint 3 timeline.
