# Pull Request

## Type
<!-- Mark exactly one -->
- [ ] `feat` — new feature or capability
- [ ] `fix` — bug fix
- [ ] `refactor` — code change with no behaviour change
- [ ] `perf` — performance improvement
- [ ] `test` — adding or correcting tests
- [x] `chore` — build, deps, CI, tooling
- [x] `docs` — documentation only

---

## What changed

Introduces Sprint 3 planning documentation for a performance-focused overhaul of the voice pipeline. This PR adds four new documents (ADR-011, ADR-012, ARCH-101, SPRINT_3_SUMMARY) and updates three existing files (SPRINTS.md, decisions/README.md, ADR-001) to reflect the shift from Sherpa/Piper to Supertonic TTS and the urgent need to address STT transcription latency. No implementation code is included—this is purely planning and research scaffolding to guide the upcoming 10-day sprint.

---

## Why

The current Sprint 2 implementation suffers from two critical performance issues: (1) on-device sherpa-onnx STT produces unacceptably slow transcription with high latency, breaking conversational flow, and (2) Piper TTS quality is robotic and unnatural. As documented in `engineering_lessons.md`, these are known pain points that block production readiness. This PR implements the planning phase of ADR-011 (STT Performance Crisis Resolution) and ADR-012 (Supertonic TTS Integration), establishing clear research gates, success metrics (<1.5s partial transcript delivery, <2.5s end-to-end latency), and fallback strategies before any code changes begin. See linked issues for full problem statements.

---

## Tradeoffs and decisions made

**What we chose NOT to do:**

- **Did NOT commit to Whisper.cpp as the only solution:**
While Whisper.cpp is the primary target, we explicitly documented chunked streaming + perceived latency reduction as a viable fallback if Whisper.cpp proves too complex to integrate. This avoids a single point of failure.
- **Did NOT specify Supertonic integration method:** We deliberately left the integration approach (system service binding vs. SDK vs. cloud API) as "TBD (research required)" because premature commitment could lock us into a suboptimal path. Three options are documented with pros/cons.
- **Did NOT include on-device LLM (Qwen 0.8B):** Explicitly marked as out-of-scope for Sprint 3 to maintain focus on STT/TTS performance only. This prevents scope creep.
- **Did NOT update SETUP.md yet:** Setup instructions remain Sprint 2-accurate (Piper TTS, sherpa-onnx) because Sprint 3 implementation hasn't started. Future updates will come with actual implementation PRs.
**Alternative approaches considered:**
- **Cloud STT (Groq Whisper API):** Rejected for Sprint 3 due to latency concerns (network round-trip) and cost at scale. Kept as a future option if on-device solutions fail.
- **F5-TTS (previous Sprint 3 plan):** Superseded by Supertonic after user testing showed significantly better naturalness. F5-TTS remains a backup if Supertonic integration proves infeasible.
- **Parallel STT+LLM streaming:** Considered but deferred to Sprint 4 due to complexity. Sprint 3 focuses on sequential pipeline optimization first.

---

## Risk areas

**High uncertainty:**

- **Whisper.cpp Android integration complexity:** No prior experience integrating C++ libraries via FFI in this codebase. May require significant build system changes (CMake, NDK). Mitigation: Days 1-3 dedicated to feasibility research with clear "go/no-go" gate.
- **Supertonic integration method unknown:** Could be a system service (requires Android binding), a proprietary SDK (licensing unknown), or a cloud API (latency/cost concerns). Mitigation: Research phase includes contacting Supertonic team for documentation.
- **Chunking strategy may not reduce perceived latency:** If LLM still waits for full transcript before responding, chunking alone won't help. Mitigation: ADR-011 explicitly requires concurrent streaming architecture (chunked STT → incremental LLM → sentence-boundary TTS trigger).
- **Architecture layer violation refactor could break STT:** Fixing `SherpaSttDatasource` → `VadRepository` dependency (tracked in bug report) touches core pipeline. Mitigation: Scheduled for Days 8-9 with full test coverage verification.
**Edge cases:**
- Whisper.cpp model size (>100MB) may exceed app bundle limits, requiring dynamic download.
- Supertonic may not support offline mode, breaking core offline-first requirement.
- Chunked streaming could produce fragmented/incoherent transcripts if chunk boundaries cut words mid-syllable.

---

## Screenshots / recordings

Not required for docs-only PR

---

## Testing checklist

### General

- [x] Builds without errors (`flutter build apk`)
- [x] No new lint warnings (`flutter analyze`)
- [x] `build_runner` run if any Freezed file was modified
- [x] No API keys, `google-services.json`, or `firebase_options.dart` in diff
- [x] No `TODO` comments in shipped code
- [x] All error states handled — no unhandled `Left` or bare `catch (e) {}`

### If voice pipeline touched

- [ ] Tested on physical Android device (not emulator)
- [ ] Full conversation loop works end-to-end
- [ ] PTT mode works correctly
- [ ] Always-on VAD mode works correctly
- [ ] TTS speaks before full LLM response arrives (sentence-boundary trigger)
- [ ] Groq 429 falls back to Gemini silently
- [ ] Session ends cleanly — no dangling streams or subscriptions

### If BLoC touched

- [ ] No `emit()` called outside an event handler
- [ ] All stream subscriptions cancelled in `close()`
- [ ] Freezed `when()` exhaustive — no `orElse` hiding unhandled states

### If Firestore or auth touched

- [ ] Security rules still enforce per-user isolation
- [ ] No sensitive data written to Firestore (keys stay in Keystore only)

### If navigation touched

- [ ] Forward and back navigation tested
- [ ] GoRouter redirect logic does not loop

### Device matrix (mark which were tested)

- [ ] Android 10 (API 29)
- [ ] Android 12 (API 31)
- [ ] Android 14 (API 34)

---

## ADR created or updated
<!-- If this PR encodes a new architectural decision, create the ADR
     file in docs/decisions/ and link it here.
     If an existing ADR is superseded, update its Status field. -->
- [ ] No new architectural decision
- [x] ADR created: `docs/decisions/ADR-011-stt-performance-crisis-resolution.md`
- [x] ADR created: `docs/decisions/ADR-012-supertonic-tts-integration.md`
- [x] ADR created: `docs/architecture/ARCH-101-concurrent-streaming-audio-pipeline.md`
- [x] ADR superseded: `docs/decisions/ADR-001-stt-android-speechrecognizer.md` → Status updated to "Superseded by ADR-011"
- [x] Document created: `docs/planning/SPRINT_3_SUMMARY.md`
- [x] Document updated: `docs/planning/SPRINTS.md` → Sprint 3 details revised
- [x] Document updated: `docs/decisions/README.md` → Index table expanded

---

## Linked issues

Relates to `.github/ISSUES/sprint-3-performance-overhaul.md` (feature decision)
Relates to `.github/ISSUES/arch-layer-violation-sherpa-stt.md` (bug report)
Closes # (none—planning phase only)` did not appear verbatim in /workspace/.github/PRs/sprint-3-planning-docs.md.
