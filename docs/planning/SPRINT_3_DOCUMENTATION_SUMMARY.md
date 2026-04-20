# Sprint 3 Documentation Summary

**Created:** April 2026  
**Author:** Development Team  

---

## Overview

This document summarizes the new documentation created for Sprint 3, which pivots from the original F5-TTS plan to a performance-focused overhaul addressing two critical user experience issues:

1. **STT Latency:** 2-4 second transcription delay causing noticeable lag
2. **TTS Voice Quality:** Robotic Piper voices lacking natural prosody

---

## New Documents Created

### 1. ADR-011: STT Performance Optimization Strategy
**File:** `docs/decisions/ADR-011-stt-performance-optimization.md`  
**Status:** Proposed  

**Key Decision:** Implement chunked streaming with sherpa-onnx (1.5s chunks, 300ms overlap) to show partial transcripts within 1.5s instead of waiting for full utterance. Research Whisper.cpp integration as swappable backend for future accuracy improvement.

**Highlights:**
- **Problem:** Sequential full-buffer processing causes 2.5s+ delay before first transcript
- **Solution:** Chunked streaming with debouncing for stable partial display
- **Target:** 60% reduction in perceived latency (2.5s → 1.0s to first partial)
- **Fallback:** If Whisper.cpp proves too complex, chunked sherpa-onnx still delivers meaningful improvement
- **Implementation Plan:** 10 days across 4 phases (chunking, Whisper research, abstraction, testing)

**Metrics:**
| Metric | Current | Target |
|--------|---------|--------|
| Time to first transcript | 2.5s avg | <1.0s avg |
| End-to-end latency | 4.2s avg | <2.0s avg |
| Partial transcript stability | N/A | >85% match final |

---

### 2. ADR-012: Supertonic TTS Integration Strategy
**File:** `docs/decisions/ADR-012-supertonic-tts-integration.md`  
**Status:** Proposed  

**Key Decision:** Replace Piper TTS with Supertonic for near-human voice quality and 50% lower synthesis latency. Implement hybrid approach with Piper fallback. Research phase (Days 1-2) to determine integration method (SDK, local HTTP, or system TTS).

**Highlights:**
- **Problem:** Piper voices sound robotic (MOS 3.2/5.0), limited Arabic support
- **Opportunity:** Supertonic tested independently with excellent results (natural prosody, seamless Arabic-English code-switching, ~400ms latency)
- **Risk Mitigation:** Days 1-2 research phase with go/no-go decision point; Piper fallback ensures reliability
- **Integration Options:** Official SDK (if exists), local HTTP server (common pattern), or Android system TTS bridge
- **Implementation Plan:** 10 days across 5 phases (research, integration, fallback, polish, documentation)

**Metrics:**
| Metric | Current (Piper) | Target (Supertonic) |
|--------|-----------------|---------------------|
| TTS latency | 1200ms avg | <500ms avg |
| Voice quality MOS | 3.2/5.0 | >4.2/5.0 |
| Arabic pronunciation | 78% | >92% |
| Code-switching fluency | Poor (robotic) | Natural (seamless) |

**Research Checklist Included:**
- APK analysis (manifest permissions, exported services)
- Runtime testing (system TTS registration, localhost HTTP monitoring)
- API discovery (common ports, endpoint testing)
- Legal & licensing review

---

### 3. ARCH-101: Audio Pipeline Concurrency Model
**File:** `docs/architecture/ARCH-101-audio-pipeline-concurrency.md`  
**Status:** Proposed  

**Key Decision:** Refactor audio pipeline to use isolate-based compute, stream-based chunk processing, and progressive output strategy to achieve <2s perceived latency (60% improvement over Sprint 2).

**Highlights:**
- **Problem:** Sequential pipeline blocks main isolate during STT/TTS compute; no pipelining between stages
- **Architecture Principles:**
  1. Isolate-based compute boundaries (all heavy work off main thread)
  2. Stream-based chunk processing (replace full-buffer with streaming)
  3. Pipeline stage decoupling (independent stages with message passing)
  4. Progressive output strategy (emit intermediate results for perceived speed)
- **Implementation Patterns Provided:**
  - `ChunkedSttProcessor` class with sliding window and debouncing
  - `VoicePipelineOrchestrator` for concurrent LLM + TTS warm-up
  - `BoundedAudioQueue` for backpressure handling
- **Migration Plan:** 10 days across 5 phases (isolate extraction, chunking, pipeline integration, TTS parallelization, optimization)

**Timing Budget:**
| Stage | Sprint 2 | Sprint 3 Target | Improvement |
|-------|----------|-----------------|-------------|
| Time to first partial | 5700ms | 2300ms | **60%** |
| Total end-to-end | 8400ms | 4900ms | **42%** |

---

### 4. Updated SPRINTS.md
**File:** `docs/planning/SPRINTS.md`  
**Changes:**
- Changed Sprint 3 status from "🔄 In Progress" to "📋 Planned"
- Updated title: "Unified Audio Pipeline & Polish" → "Performance Overhaul (STT Chunking + Supertonic TTS)"
- Replaced deliverables with ADR-011, ADR-012, and ARCH-101 references
- Added explicit "Out of Scope" section:
  - On-device LLM (Qwen 0.8B) — deferred to future sprint
  - Groq Whisper API — may be explored in Sprint 4 if Whisper.cpp unfeasible

---

### 5. Updated ADR Index (README.md)
**File:** `docs/decisions/README.md`  
**Changes:**
- Added ADR-011 and ADR-012 to index table
- Updated ADR-001 status to reference ADR-010 and ADR-011 (was incorrectly referencing non-existent ADR-012)
- Updated ADR-003 status from "Partially superseded" to "Superseded by ADR-012"

---

### 6. Fixed ADR-001 References
**File:** `docs/decisions/ADR-001-stt-android-speechrecognizer.md`  
**Changes:**
- Line 4: Fixed reference from "ADR-012" to "ADR-010, ADR-011, ARCH-011" (was broken link)
- Line 88-89: Updated Links section to reference ADR-010 (Unified Audio Pipeline) and ADR-011 (STT Performance) instead of non-existent ADR-012

---

## Documentation Fixes from Audit

The following pre-existing documentation errors were identified and fixed:

| Document | Issue | Fix Applied |
|----------|-------|-------------|
| `ADR-001` line 4 | Referenced non-existent "ADR-012" | Changed to "ADR-010, ADR-011, ARCH-101" |
| `ADR-001` line 88 | Referenced non-existent "ADR-012" | Changed to "ADR-010" and added "ADR-011" |
| `decisions/README.md` | Missing ADR-011/012 entries | Added both to index table |
| `SPRINTS.md` | Sprint 3 marked "In Progress" with no implementation | Changed to "Planned" with accurate deliverables |

---

## Remaining Documentation To Fix

The following documents were identified as having outdated or misleading information but were **not modified** to preserve their "journey doc" nature. They should be annotated rather than rewritten:

### High Priority
1. **`docs/ONBOARDING.md` Section 5, Line 76**
   - **Issue:** States "GroqSttDatasource takes the audio buffer" (doesn't exist)
   - **Reality:** Uses `SherpaSttDatasource` (sherpa-onnx on-device STT)
   - **Recommended Fix:** Add note: "Sprint 2 uses SherpaSttDatasource. Sprint 3 will evaluate Groq Whisper integration."

2. **`docs/planning/lingua-prd-v0.3.md` (throughout)**
   - **Issue:** Specifies Groq Whisper as STT provider
   - **Reality:** Sprint 2 uses sherpa-onnx; Sprint 3 evaluating chunked approach
   - **Recommended Fix:** Add header annotation: "Implementation Status (April 2026): Sprint 2 temporarily uses sherpa-onnx. See ADR-011 for Sprint 3 optimization plan."

### Medium Priority
3. **`docs/extras/sprint-2/lessons learnt/engineering_lessons.md`**
   - **Issue:** Describes bugs without indicating which are fixed vs. ongoing
   - **Section 1:** "`await reply.first` hangs" — **FIXED** (timeout implemented)
   - **Section 4:** "`SherpaSttDatasource` depends on `VadRepository`" — **STILL EXISTS** (architectural violation)
   - **Recommended Fix:** Add status headers: "Analysis Date: March 2026 | Bug Status: Fixed/Pending"

4. **`docs/SETUP.md` Section 6**
   - **Issue:** Instructs to download Piper TTS model without Sprint 3 context
   - **Reality:** Piper will be replaced by Supertonic in Sprint 3
   - **Recommended Fix:** Add note: "Sprint 3 Update: This Piper model will be replaced with Supertonic TTS integration. Instructions will be updated when Sprint 3 is complete."

5. **`docs/ARCHITECTURE.md` Section 4**
   - **Issue:** Generic pipeline description doesn't distinguish Sprint 2 vs. 3 implementations
   - **Recommended Fix:** Add clarification: "Sprint 2: sherpa-onnx on-device STT. Sprint 3 (planned): Chunked streaming with isolate-based compute."

---

## Sprint 3 Timeline Summary

```
Day 1-2:  Supertonic Research Phase [GATE DECISION]
          ├── Analyze APK for integration method
          ├── Test for local HTTP server or system TTS
          └── Go/No-Go decision: Supertonic feasible? → Yes: Day 3-10 | No: Pivot to F5-TTS

Day 3-4:  Chunked STT Infrastructure (ADR-011 Phase 1-2)
          ├── Implement ChunkedSttProcessor
          ├── Sliding window (1.5s chunks, 300ms overlap)
          └── Stream-based partial transcript API

Day 5-6:  Supertonic Integration (ADR-012 Phase 1-2) [Conditional]
          ├── Implement chosen integration method
          ├── Create SupertonicTtsDatasource
          └── Feature detection and fallback logic

Day 7-8:  Pipeline Concurrency (ARCH-101 Phase 3-4)
          ├── Isolate-based compute for STT/TTS
          ├── Parallel TTS warm-up during LLM generation
          └── Progressive state updates in SpeakingBloc

Day 9-10: Optimization & Testing
          ├── Tune chunk size and overlap parameters
          ├── A/B test with real users
          ├── Add telemetry for pipeline timings
          └── Documentation updates
```

---

## Success Criteria for Sprint 3

**Must Have (Sprint 3 Complete):**
- [ ] Partial transcripts appear within 1.5s of speech start (currently 2.5s after speech ends)
- [ ] End-to-end latency <2.5s (currently 4-5s)
- [ ] TTS voice quality rated >4.0/5.0 in user testing (currently 3.2/5.0)
- [ ] Graceful fallback to Piper if Supertonic unavailable
- [ ] No regression in transcript accuracy (WER <9.0%)

**Nice to Have (Stretch Goals):**
- [ ] Whisper.cpp proof-of-concept integration
- [ ] Incremental TTS synthesis (start speaking before LLM finishes)
- [ ] User preference for TTS engine selection
- [ ] Telemetry dashboard for pipeline performance metrics

---

## Related Documents

- **Original PRD:** `docs/planning/lingua-prd-v0.3.md`
- **Sprint 2 Lessons:** `docs/extras/sprint-2/lessons learnt/`
- **Test Coverage:** `docs/testing/USECASE_COVERAGE_EXPANSION_2026-04.md`
- **Setup Guide:** `docs/SETUP.md`
- **Architecture Overview:** `docs/ARCHITECTURE.md`

---

## Next Steps

1. **Review ADRs:** Team to review ADR-011, ADR-012, and ARCH-101 before Sprint 3 kickoff
2. **Fix High-Priority Docs:** Update ONBOARDING.md and lingua-prd-v0.3.md with implementation status notes
3. **Sprint 3 Kickoff:** Begin Day 1-2 Supertonic research phase
4. **Daily Checkpoints:** Verify progress against 10-day timeline; pivot decision at end of Day 2 if needed
