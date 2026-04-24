# Valoqui Sprint Plans

*Tracking the agile development progress of Valoqui. This document provides a historical record of how the project evolved from concept to MVP.*

---

## 🏃‍♂️ Sprint 1: Foundation & Security

**Status: ✅ Complete**
**Goal:** Establish the core architecture, security model, and user onboarding flow.

**Key Deliverables:**

- [x] Project scaffolding (Feature-First Clean Architecture).
- [x] Setup `get_it`, `flutter_bloc`, `freezed`, and `fpdart`.
- [x] Firebase Auth (Google Sign-In) and Firestore profile creation.
- [x] BYOK Onboarding: Securely capture and store Groq/Gemini API keys in device Keystore.
- [x] Basic routing and design system (Theming, Typography).

---

## 🏃‍♂️ Sprint 2: The Conversational Loop (MVP)

**Status: ✅ Complete**
**Goal:** Build the core voice pipeline and post-session reporting.

**Key Deliverables:**

- [x] Integrate `speech_to_text` (Android) as the interim STT.
- [x] Integrate `sherpa_onnx` for VAD and TTS (Piper model).
- [x] Implement `GroqLlmRepository` with streaming and Gemini fallback logic.
- [x] Develop `SpeakingBloc` state machine to orchestrate the pipeline (Listen -> Process -> Speak).
- [x] Implement the "Sentence-Boundary TTS Trigger" trick for perceived zero-latency.
- [x] `ReportBloc`: Generate DELE-graded report cards and calculate XP.

---

## 🏃‍♂️ Sprint 3: Performance Overhaul (STT Chunking + Supertonic TTS)

**Status: 📋 Planned**
**Theme:** "Make it Fast, Make it Natural"
**Summary:** See `SPRINT_3_SUMMARY.md` for complete details
**Goal:** Eliminate transcription latency through chunked streaming STT and upgrade to natural-sounding Supertonic TTS.

**Key Deliverables:**

- [ ] **ADR-011: STT Performance Overhaul** — Implement chunked streaming (500ms chunks, 100ms overlap) to emit partial transcripts within 500ms. Time-boxed Whisper.cpp evaluation (3 days, adopt if ≥30% speedup). Target: end-to-end latency < 1.5s for 3s utterance (currently 3-5s).

- [ ] **ADR-012: Supertonic TTS Integration** — Replace Piper TTS with Supertonic system service for natural voice quality (MOS ≥ 4.0). Implement graceful fallback to Piper. Research spike: determine integration method (Intent/SDK). Target: time-to-first-audio < 200ms, APK size reduction ~77MB.

- [ ] **ARCH-101: Chunked Audio Streaming** — Refactor pipeline with `AudioChunker`, `OverlapBlender`, `ContextBuffer` components. Add UI states: `listening` → `partial` → `confirmed`. Maintain >90% accuracy, work on low-end devices (2GB RAM).

- [ ] **Performance Benchmarking** — Infrastructure for latency measurement, battery profiling, MOS scoring. Test on 3 device tiers (low-end, mid-range, flagship).

- [ ] **Documentation Updates** — Setup guide (Supertonic installation), user guide (troubleshooting), release notes.

**Priority:** STT performance is 🔴 Critical (#1 adoption blocker), TTS upgrade is 🟠 High (secondary).

**Out of Scope:** On-device LLM (Qwen 0.8B), server-side STT/TTS, real-time translation, UI/UX redesign. Defer to future sprints.

**Success Metrics:**

- Time-to-first-partial < 500ms (currently N/A)
- End-to-end latency < 1.5s (currently 3-5s)
- TTS MOS score ≥ 4.0 (currently ~3.2)
- Voice feature adoption > 40% (currently < 15%)

**Timeline:**

- Week 1: Research spikes (chunked design, Whisper.cpp eval, Supertonic integration)
- Week 2: Implementation (chunked STT pipeline, Supertonic datasource)
- Week 3: Integration & testing (BLoC, UI states, benchmarks)
- Week 4: Polish & beta testing (performance optimization, feedback)

**References:**

- Full sprint plan: `docs/planning/SPRINT_3_SUMMARY.md`
- ADR-011: `docs/decisions/ADR-011-stt-performance-optimization.md`
- ADR-012: `docs/decisions/ADR-012-supertonic-tts-integration.md`
- Architecture: `docs/architecture/ARCH-101-chunked-audio-streaming.md`
- Issues: `.github/ISSUES/sprint-3-*.md`

**Out of Scope for Sprint 3:**

- On-device LLM (Qwen 0.8B or similar) — deferred to future sprint
- Groq Whisper API integration — may be explored in Sprint 4 if Whisper.cpp proves unfeasible

---

## 🔮 Future Sprints (Backlog)

- Offline LLM fallback (Gemma / Phi-3 via `llama.cpp` for local inference).
- Multi-language support (French, Arabic).
- Gamification mechanics (Streaks, Leaderboards).

> - **NOTE** : Here is the real used [Sprints](sprints/) .docx
> - **Sprint-1** : [SPRINT-1](sprints/valoqui_sprint1_v2.docx)
> - **Sprint-2** : [SPRINT-2](sprints/valoqui_sprint2_guide.docx)
> - **Sprint-3** : [SPRINT-3](sprints/valoqui_sprint3_guide.docx)
