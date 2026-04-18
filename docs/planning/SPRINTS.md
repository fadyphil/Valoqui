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

## 🏃‍♂️ Sprint 3: Unified Audio Pipeline & Polish

**Status: 🔄 In Progress**
**Goal:** Remove OS-level bottlenecks and upgrade to a premium voice model.

**Key Deliverables:**

- [ ] **ARCH-101 Unified Audio Pipeline:** Deprecate `speech_to_text`. Use `record` for a raw PCM stream, feeding both Silero VAD and Groq Whisper (Multipart HTTP). This removes the Android 7-second listening ceiling.
- [ ] Upgrade TTS: Replace interim Piper model with F5-TTS ONNX for high-fidelity Castilian Spanish.
- [ ] UI Polish: Add waveform animations and transitions during the `SpeakingScreen` states.
- [ ] Comprehensive end-to-end widget testing.

---

## 🔮 Future Sprints (Backlog)

- Offline LLM fallback (Gemma / Phi-3 via `llama.cpp` for local inference).
- Multi-language support (French, Arabic).
- Gamification mechanics (Streaks, Leaderboards).

> - **NOTE** : Here is the real used [Sprints](sprints/) .docx
> - **Sprint-1** : [SPRINT-1](sprints/valoqui_sprint1_v2.docx)
> - **Sprint-2** : [SPRINT-2](sprints/valoqui_sprint2_guide.docx)
> - **Sprint-3** : [SPRINT-3](sprints/valoqui_sprint3_guide.docx)
