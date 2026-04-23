# Sprint 3 Summary: Performance Overhaul

**Sprint Duration:** 20 days (April 2026)
**Theme:** "Make it Fast, Make it Natural"
**Status:** 📋 Planned

## Executive Summary

Sprint 3 addresses the two critical blockers identified in Sprint 2 beta testing:

1. **STT Latency Crisis** - 3-5 second transcription delay breaks conversation flow
2. **Robotic TTS Voice** - Piper's unnatural prosody reduces user engagement

This sprint transforms Lingua from "technically functional" to "conversational and natural."

---

## Sprint Goals

### Primary Goal #1: STT Performance Overhaul

**Target:** Reduce end-to-end transcription latency from 3-5s to <1.5s

**Key Results:**

- [ ] Time-to-first-partial transcript < 500ms (currently 2-4s)
- [ ] End-to-end latency < 1.5s for 3-second utterance (currently 3-5s)
- [ ] Maintain >90% transcription accuracy (no regression)
- [ ] Work on low-end devices (2GB RAM, quad-core A53)

**Approach:**

- Phase 1: Implement chunked streaming (500ms chunks with overlap)
- Phase 2: Evaluate Whisper.cpp (time-boxed 3 days, adopt if ≥30% speedup)

**Owner:** Core Engineering Team
**Priority:** 🔴 Critical (#1 blocker for adoption)

---

### Primary Goal #2: TTS Engine Upgrade

**Target:** Replace Piper TTS with Supertonic for natural voice quality

**Key Results:**

- [ ] MOS score ≥ 4.0/5.0 (vs. Piper's ~3.2)
- [ ] Time-to-first-audio < 200ms (vs. Piper's ~400ms)
- [ ] APK size reduction ≥ 70MB (no bundled model)
- [ ] Graceful fallback to Piper if Supertonic unavailable

**Approach:**

- Research spike: Determine integration method (Intent? SDK?)
- Implement `SupertonicTtsDatasource` with availability checks
- Keep Piper as permanent fallback option

**Owner:** Core Engineering Team
**Priority:** 🟠 High (secondary to STT work)

---

## Scope Boundaries

### ✅ In Scope

**STT Work:**

- Chunked audio streaming pipeline
- Overlap blending and context carryover
- Partial transcript emission
- Whisper.cpp evaluation (time-boxed)
- Performance benchmarking infrastructure

**TTS Work:**

- Supertonic integration research
- `SupertonicTtsDatasource` implementation
- Engine availability detection
- Fallback mechanism to Piper

**Documentation:**

- ADRs for both features
- Architecture design docs
- Setup guide updates
- User guide for Supertonic installation

### ❌ Out of Scope

**Explicitly Excluded:**

- On-device LLM (Qwen 0.8B mentioned as future consideration)
- Server-side STT/TTS (violates offline-first principle)
- Real-time translation feature
- Speaker diarization
- Emotion detection
- UI/UX redesign (separate track)
- CI/CD pipeline changes

**Future Sprints:**

- Groq Whisper API integration (Sprint 4+)
- F5-TTS ONNX export (when available)
- Multi-language support expansion
- Advanced VAD tuning

---

## Technical Spikes

### Spike 1: Chunked Streaming Design (2 days)

**Goal:** Design optimal chunking strategy

**Questions to Answer:**

- What chunk duration balances latency vs. accuracy? (300ms? 500ms? 1000ms?)
- How much overlap prevents gaps without redundancy?
- How to handle word boundaries across chunks?
- What context buffer size maintains sentence coherence?

**Deliverable:** `docs/spikes/chunked-streaming-design.md`

**Success Criteria:**

- Clear recommendation for chunk duration and overlap
- Prototype demonstrates feasibility
- Edge cases identified and addressed

---

### Spike 2: Whisper.cpp Evaluation (3 days, time-boxed)

**Goal:** Benchmark Whisper.cpp against sherpa-onnx

**Tasks:**

- Build Whisper.cpp for Android ARM64
- Test all model variants (tiny, base, small)
- Measure inference speed on test devices
- Evaluate streaming API availability
- Assess integration complexity (JNI/FFI)

**Deliverable:** `docs/spikes/whisper-cpp-evaluation.md`

**Decision Criteria:**

| Metric | Threshold for Adoption |
| -------- | ---------------------- |
| Speed | ≥30% faster than sherpa-onnx |
| Model Size | ≤50MB (tiny variant) |
| Integration Effort | ≤3 days for basic integration |
| Accuracy | WER within 2% of current model |

**Go/No-Go Decision:** Day 3 EOD

---

### Spike 3: Supertonic Integration Method (2 days)

**Goal:** Determine how to interface with Supertonic app

**Questions to Answer:**

- Does Supertonic expose an Intent-based API?
- Is there an official SDK or library?
- Can we programmatically select Supertonic as TTS engine?
- What permissions are required?
- Is root access needed?

**Deliverable:** `docs/spikes/supertonic-integration-method.md`

**Fallback Plan:** If integration proves too complex, defer to Sprint 4 and keep Piper

---

## Implementation Timeline

### Week 1 (Days 1-5): Research & Design

```Markdown
Day 1-2: [████████░░] Chunked streaming design spike
Day 3-5:  [░░████████] Whisper.cpp evaluation spike (parallel)
Day 3-5:  [████░░░░░░] Supertonic integration spike (parallel)
```

**Milestones:**

- ✅ Day 2: Chunked streaming design approved
- ✅ Day 5: Whisper.cpp go/no-go decision
- ✅ Day 5: Supertonic integration method confirmed

---

### Week 2 (Days 6-10): Implementation

```Markdown
Day 6-8:  [████████░░] Implement chunked STT pipeline
Day 9-10: [░░████████] Integrate Supertonic TTS
```

**Milestones:**

- ✅ Day 8: Chunked pipeline functional (partial transcripts emitting)
- ✅ Day 10: Supertonic speaking first words

---

### Week 3 (Days 11-15): Integration & Testing

```Markdown
Day 11-12: [████████░░] BLoC integration, UI states
Day 13-14: [░░████████] Comprehensive testing
Day 15:    [░░░░██████] Bug fixes, polish
```

**Milestones:**

- ✅ Day 12: End-to-end flow working (speech → partial → confirmed → TTS)
- ✅ Day 14: All tests passing, benchmarks met
- ✅ Day 15: Sprint demo ready

---

### Week 4 (Days 16-20): Polish & Release Prep

```Markdown
Day 16-17: [████████░░] Performance profiling, optimization
Day 18-19: [░░████████] Beta testing, feedback incorporation
Day 20:    [░░░░██████] Documentation, sprint review
```

**Milestones:**

- ✅ Day 17: Performance targets met on all device tiers
- ✅ Day 19: Beta tester feedback positive
- ✅ Day 20: Sprint 3 complete, ready for release

---

## Success Metrics

### Quantitative Metrics

| Metric | Baseline (Sprint 2) | Target (Sprint 3) | Measurement Method |
| -------- | --------------------- | ------------------- | ------------------- |
| Time-to-first-partial | N/A | < 500ms | Stopwatch from speech start |
| End-to-end latency | 3-5s | < 1.5s | Speech end → final transcript |
| TTS MOS score | ~3.2 | ≥ 4.0 | Blind listening test (10+ users) |
| TTS time-to-first-audio | ~400ms | < 200ms | Audio measurement |
| APK size | ~150MB | ~80MB | Build artifact analysis |
| Battery drain (STT) | ~5%/min | < 7%/min | Battery Historian |
| Voice feature adoption | < 15% | > 40% | Analytics tracking |

### Qualitative Metrics

**User Feedback Targets:**

- "Feels conversational" — ≥ 70% of beta testers agree
- "Voice sounds natural" — ≥ 60% prefer Supertonic over Piper
- "Would recommend voice feature" — ≥ 50% Net Promoter Score

**Developer Experience:**

- Code complexity (cyclomatic) increase < 15%
- Test coverage maintained > 85%
- Documentation completeness score > 90%

---

## Risk Management

### High-Priority Risks

| Risk | Probability | Impact | Mitigation | Owner |
| ------ | ------------- | -------- | ------------ | ------- |
| Chunking reduces accuracy | Medium | High | Overlap chunks, carry context, extensive testing | Tech Lead |
| Whisper.cpp evaluation inconclusive | Medium | Medium | Chunked streaming works regardless, defer Whisper.cpp | STT Team |
| Supertonic integration blocked | Low | High | Keep Piper as permanent fallback | TTS Team |
| Battery drain increases >20% | Low | Medium | Profile early, optimize thread pool, add battery saver mode | Performance Team |
| Timeline slippage | Medium | High | Cut TTS work before STT, strict time-boxing | PM |

### Contingency Plans

**If STT work slips:**

- Extend Sprint 3 by up to 5 days (pre-approved)
- Defer Whisper.cpp evaluation to Sprint 4
- Ship chunked-only solution (still 8x improvement)

**If TTS work slips:**

- Defer Supertonic to Sprint 4
- Keep Piper with documented limitations
- No user-visible regression

**If both slip:**

- Prioritize STT performance (critical blocker)
- TTS upgrade is "nice to have" relative to latency fix

---

## Resource Requirements

### Team Composition

**Required:**

- 2 Flutter/Dart developers (STT + TTS tracks)
- 1 Android native developer (JNI/FFI if Whisper.cpp adopted)
- 1 QA engineer (performance testing)
- 1 PM (coordination, stakeholder management)

**Optional:**

- ML engineer (Whisper.cpp optimization, if adopted)
- UX designer (UI state refinements, minimal involvement)

### Infrastructure

**Hardware:**

- Test devices: 3 tiers (low-end, mid-range, flagship)
- Audio recording equipment for benchmarking
- Battery monitoring tools

**Software:**

- Android Profiler licenses
- Battery Historian setup
- CI/CD for performance regression testing

---

## Dependencies

### Internal Dependencies

**Blocks:**

- Sprint 4 planning (Groq Whisper API integration)
- User acceptance testing cycle
- Play Store release (v1.3.0)

**Blocked By:**

- None (can start immediately)

### External Dependencies

**Supertonic App:**

- Must remain available on Play Store
- API stability (no breaking changes)
- Compatibility with Android 10+

**Whisper.cpp (if adopted):**

- Android build toolchain stability
- Community maintenance continuity
- License compliance (MIT)

---

## Communication Plan

### Stakeholder Updates

**Weekly:**

- Sprint review demo (Fridays, 3 PM)
- Written status report (Slack #sprint-3-updates)
- Risk register update (shared doc)

**Bi-Weekly:**

- Stakeholder sync (product + engineering)
- Beta tester feedback review

**Ad-Hoc:**

- Blocker escalation (immediate Slack ping)
- Go/no-go decisions (documented in ADR comments)

### Developer Coordination

**Daily:**

- Standup (10 AM, 15 minutes)
- Blocker check-in (async Slack thread)

**Weekly:**

- Architecture review (Wednesday, 1 hour)
- Code walkthrough (Thursday, 1 hour)

---

## Definition of Done

### Sprint 3 Complete When

**Code:**

- [ ] All acceptance criteria met for both features
- [ ] Unit tests passing (>85% coverage)
- [ ] Integration tests passing (end-to-end latency targets)
- [ ] Performance benchmarks met on all device tiers
- [ ] No critical/open bugs

**Documentation:**

- [ ] ADRs merged (ADR-011, ADR-012)
- [ ] Architecture docs updated (ARCH-101)
- [ ] Setup guide reflects Supertonic installation
- [ ] User guide includes troubleshooting section

**Release:**

- [ ] Beta release deployed to 20+ testers
- [ ] Feedback incorporated (critical issues fixed)
- [ ] Release notes drafted
- [ ] Play Store listing updated

**Post-Sprint:**

- [ ] Sprint retrospective completed
- [ ] Lessons learned documented
- [ ] Sprint 4 planning initiated

---

## Appendices

### Appendix A: Device Test Matrix

| Tier | Device | Android | RAM | CPU | Priority |
| ------ | -------- | --------- | ----- | ----- | ---------- |
| Low-end | Redmi Note 9 | 11 | 4GB | Helio G85 | 🔴 Critical |
| Low-end | Samsung A12 | 10 | 3GB | Helio P35 | 🔴 Critical |
| Mid-range | Samsung A52 | 12 | 6GB | SD 720G | 🟠 High |
| Mid-range | Pixel 5a | 12 | 6GB | SD 765G | 🟠 High |
| Flagship | Pixel 6 | 13 | 8GB | Tensor G2 | 🟡 Medium |
| Flagship | Galaxy S22 | 13 | 8GB | SD 8 Gen 1 | 🟡 Medium |

### Appendix B: Benchmark Scripts

**STT Latency Benchmark:**

```bash
# Run on physical device
flutter test integration_test/stt_latency_test.dart \
  --device-id=<DEVICE_ID> \
  --dart-define=UTTERANCE_DURATION=3 \
  --dart-define=EXPECTED_LATENCY_MS=1500
```

**TTS Quality Benchmark:**

```bash
# Generate audio samples
dart bin/generate_tts_samples.dart --engine=supertonic --output=samples/

# MOS scoring (manual)
# 10+ listeners rate samples 1-5
# Average must be ≥ 4.0
```

### Appendix C: Glossary

| Term | Definition |
| ------ | ------------ |
| **Chunked Streaming** | Processing audio in fixed-duration segments (500ms) instead of waiting for full utterance |
| **Overlap** | 100ms of audio repeated between consecutive chunks to prevent gaps |
| **Context Buffer** | Carry-over of incomplete words across chunk boundaries |
| **MOS Score** | Mean Opinion Score (1-5 scale) for voice quality assessment |
| **WER** | Word Error Rate (lower is better, target ≤ 10%) |
| **Time-to-First-Partial** | Delay from speech start to first visible transcript |
| **End-to-End Latency** | Total delay from speech end to final confirmed transcript |

---

## References

- ADR-011: STT Performance Overhaul
- ADR-012: Supertonic TTS Integration
- ARCH-101: Chunked Audio Streaming Architecture
- Bug Report: STT latency too high (`.github/ISSUES/stt-latency-too-high-sherpa-onnx.md`)
- Feature Request: Supertonic TTS (`.github/ISSUES/sprint-3-supertonic-tts.md`)
- Feature Request: STT Overhaul (`.github/ISSUES/sprint-3-stt-performance-overhaul.md`)
- Sprint 2 Lessons Learned: `docs/extras/sprint-2/lessons learnt/engineering_lessons.md`

---

**Last Updated:** April 2026
**Document Owner:** Product Engineering Team
**Review Cycle:** Weekly during sprint, post-sprint retrospective
