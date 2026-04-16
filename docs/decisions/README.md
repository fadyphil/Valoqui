# Architectural Decision Records

This folder contains the ADRs (Architectural Decision Records) for Valoqui.
Each file records a significant technical decision: what was decided, what was
rejected, and why.

**Read these before modifying the voice pipeline or switching any provider.**
The swap pattern (ADR-005) means changes are isolated — but understanding *why*
components were chosen prevents accidentally undoing deliberate tradeoffs.

---

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-000](ADR-000-template.md) | Template | — |
| [ADR-001](ADR-001-stt-android-speechrecognizer.md) | STT: Android SpeechRecognizer (interim) | Accepted — under re-evaluation |
| [ADR-002](ADR-002-llm-groq-with-gemini-fallback.md) | LLM: Groq LLaMA 3.3 70B + Gemini fallback | Accepted |
| [ADR-003](ADR-003-tts-on-device-piper-to-f5tts.md) | TTS: Piper (interim) → F5-TTS ONNX (target) | Partially superseded |
| [ADR-004](ADR-004-state-management-bloc-freezed-getit.md) | State management: BLoC + Freezed + GetIt + fpdart | Accepted |
| [ADR-005](ADR-005-clean-architecture-voice-interfaces.md) | Clean architecture swap pattern | Accepted |
| [ADR-006](ADR-006-api-key-storage-android-keystore.md) | API key storage: Android Keystore | Accepted |
| [ADR-007](ADR-007-conversation-history-rolling-window.md) | Conversation history: rolling 8-turn window | Accepted |
| [ADR-008](ADR-008-sentence-boundary-tts-trigger.md) | Sentence-boundary TTS trigger | Accepted |
| [ADR-009](ADR-009-report-generation-single-llm-call.md) | Report generation: single LLM call, structured JSON | Accepted |
| [ADR-010](ADR-010-unified-audio-pipeline-groq-whisper.md) | Unified audio pipeline (Sprint 3) | Accepted — planned |

---

## Statuses

| Status | Meaning |
|--------|---------|
| **Proposed** | Under discussion, not yet implemented |
| **Accepted** | In effect — implementation matches this decision |
| **Deprecated** | No longer in effect but not replaced |
| **Superseded by ADR-XXX** | Replaced by a newer decision |
| **Under re-evaluation** | Accepted but known issues are being assessed |

---

## How to add a new ADR

1. Copy `ADR-000-template.md` to `ADR-NNN-short-title.md`
2. Fill in every section — especially **Alternatives considered**
3. Add the entry to the index table above
4. Commit the ADR in the same PR as the implementation it describes
5. If the new ADR supersedes an existing one, update the old ADR's Status field
