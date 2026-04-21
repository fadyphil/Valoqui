# Sprint 3 Documentation - Files Created/Updated

**Date:** April 2026
**Purpose:** Track all documentation created for Sprint 3 planning

---

## 📄 New Files Created

### GitHub Issues (`.github/ISSUES/`)

1. **`sprint-3-supertonic-tts.md`** — Feature Decision Record
   - Type: Feature Request
   - Labels: `sprint-3`, `tts`, `feature`, `performance`
   - Content: Supertonic TTS integration plan with acceptance criteria, technical spikes, risks
   - Related ADR: ADR-011

2. **`sprint-3-stt-performance-overhaul.md`** — Feature Decision Record
   - Type: Feature Request
   - Labels: `sprint-3`, `stt`, `performance`, `critical`
   - Content: STT latency fix via chunked streaming + Whisper.cpp evaluation
   - Related ADR: ADR-012, ARCH-101

3. **`stt-latency-too-high-sherpa-onnx.md`** — Bug Report
   - Type: Bug
   - Labels: `bug`, `performance`, `stt`, `critical`, `sprint-3`
   - Content: Documents current 3-5s latency issue, root causes, impact metrics
   - Priority: P0 - Blocks Sprint 3

### Pull Request Template (`.github/PRs/`)

1. **`sprint-3-planning-docs.md`** — PR Template
   - Type: Documentation PR
   - Labels: `documentation`, `sprint-3`, `planning`
   - Content: Checklist for Sprint 3 planning documentation PR
   - Use: Template for submitting planning docs

### Architecture Decision Records (`docs/decisions/`)

1. **`ADR-011-supertonic-tts-integration.md`** — ADR
   - Status: Proposed
   - Decision: Replace Piper TTS with Supertonic system service
   - Key Points:
     - MOS score target ≥ 4.0 (vs. Piper's ~3.2)
     - APK size reduction ~77MB
     - Graceful fallback to Piper
     - Research spike: integration method (Intent/SDK)

2. **`ADR-012-stt-performance-overhaul.md`** — ADR
   - Status: Proposed
   - Decision: Two-phase approach (chunked streaming + Whisper.cpp eval)
   - Key Points:
     - Phase 1: Chunked streaming (500ms chunks, 100ms overlap)
     - Phase 2: Whisper.cpp evaluation (3 days, time-boxed, adopt if ≥30% speedup)
     - Target: end-to-end latency < 1.5s (currently 3-5s)
     - Maintain >90% accuracy

### Architecture Documentation (`docs/architecture/`)

1. **`ARCH-101-chunked-audio-streaming.md`** — Architecture Design
   - Status: Proposed
   - Type: Technical design document
   - Components:
     - `AudioChunker`: Split audio into 500ms chunks with overlap
     - `OverlapBlender`: Crossfade between chunks
     - `ContextBuffer`: Carry over incomplete words
     - `IncrementalSttDecoder`: Emit partial transcripts
   - UI States: `listening` → `partial` → `confirmed`
   - Concurrency: Isolate-based decoding, backpressure handling

### Planning Documentation (`docs/planning/`)

1. **`SPRINT_3_SUMMARY.md`** — Sprint Plan Summary
   - Duration: 20 days (April 2026)
   - Theme: "Make it Fast, Make it Natural"
   - Contents:
     - Sprint goals (STT + TTS)
     - Scope boundaries (in/out of scope)
     - Technical spikes (3 spikes, 7 days total)
     - Implementation timeline (4 weeks)
     - Success metrics (quantitative + qualitative)
     - Risk management
     - Resource requirements
     - Definition of done

---

## 📝 Files Updated

### Sprint Plans (`docs/planning/SPRINTS.md`)

**Changes:**

- Updated Sprint 3 section with comprehensive details
- Added duration (20 days), theme, status
- Replaced vague deliverables with specific ADR references
- Added success metrics, timeline, references
- Clarified priority (STT 🔴 Critical, TTS 🟠 High)
- Explicit out-of-scope items listed

**Before:** Generic bullet points about ADRs
**After:** Detailed sprint plan with metrics, timeline, references to new docs

---

### ADR Index (`docs/decisions/README.md`)

**Changes:**

- Fixed ADR-001 reference: Changed "see ADR-010, ADR-011" → "see ADR-010, ARCH-101"
- Fixed ADR-003 status: Changed "Superseded by ADR-012" → "Superseded by ADR-011"
- Swapped ADR-011 and ADR-012 titles to match actual files:
  - ADR-011: Now "Supertonic TTS Integration" (was STT Performance)
  - ADR-012: Now "STT Performance Overhaul" (was Supertonic TTS)
- Updated ADR-001 Links section: Changed ADR-011 reference → ADR-012

**Reason:** ADR numbering was swapped in index vs. actual file content

---

### ADR-001 (`docs/decisions/ADR-001-stt-android-speechrecognizer.md`)

**Changes:**

- Line 4: Updated status reference from "ADR-011" → "ADR-012"
- Line 89: Updated Links section from "ADR-011 — STT Performance Optimization" → "ADR-012 — STT Performance Overhaul"

**Reason:** Consistency with corrected ADR numbering

---

## 📊 Document Relationships

```Markdown
SPRINT_3_SUMMARY.md (Master Plan)
├── ADR-011 (TTS Decision)
│   └── ISSUE: sprint-3-supertonic-tts.md
├── ADR-012 (STT Decision)
│   ├── ISSUE: sprint-3-stt-performance-overhaul.md
│   └── ISSUE: stt-latency-too-high-sherpa-onnx.md (Bug)
└── ARCH-101 (Technical Design)
    └── Implements ADR-012 Phase 1
```

---

## ✅ Verification Checklist

- [x] All ADRs follow existing template format
- [x] Issue templates match `.github/ISSUE_TEMPLATE/` structure
- [x] PR template matches `.github/PULL_REQUEST_TEMPLATE.md` style
- [x] Cross-references between documents are accurate
- [x] ADR index (README.md) updated with correct titles/numbers
- [x] SPRINTS.md reflects new Sprint 3 scope
- [x] No contradictory information between documents

---

## 🎯 Next Steps

1. **Review:** Team reviews all documents (1-2 days)
2. **Approve:** PM/Tech Lead approves sprint plan
3. **Implement:** Create branches for STT and TTS tracks
4. **Track:** Use GitHub issues to track progress
5. **Update:** Revise docs as implementation reveals new information

---

**Total Files Created:** 8
**Total Files Updated:** 3
**Total Word Count:** ~15,000 words
**Estimated Reading Time:** 45-60 minutes (all docs)
