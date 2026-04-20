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
**Goal:** Eliminate transcription latency through chunked streaming STT and upgrade to natural-sounding Supertonic TTS.

**Key Deliverables:**

- [ ] **ADR-011: STT Performance Optimization:** Implement chunked streaming with sherpa-onnx (1.5s chunks, 300ms overlap) to show partial transcripts within 1.5s instead of waiting for full utterance. Research Whisper.cpp integration as swappable backend for future accuracy improvement.
- [ ] **ADR-012: Supertonic TTS Integration:** Replace Piper TTS with Supertonic for near-human voice quality and 50% lower synthesis latency. Implement hybrid approach with Piper fallback. Research phase (Days 1-2) to determine integration method (SDK, local HTTP, or system TTS).
- [ ] **ARCH-101: Audio Pipeline Concurrency:** Refactor pipeline to use isolate-based compute for STT/TTS operations, stream-based chunk processing, and progressive output strategy. Target <2s perceived latency (60% improvement over Sprint 2).
- [ ] UI Polish: Add waveform animations and transitions during the `SpeakingScreen` states.
- [ ] Comprehensive end-to-end widget testing.

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
