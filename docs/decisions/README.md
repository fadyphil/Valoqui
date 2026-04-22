# Architectural Decision Records

This folder contains the ADRs (Architectural Decision Records) for Valoqui.
Each file records a significant technical decision: what was decided, what was
rejected, and why.

**Read these before modifying the voice pipeline or switching any provider.**
The swap pattern (ADR-005) means changes are isolated — but understanding *why*
components were chosen prevents accidentally undoing deliberate tradeoffs.

---

## Index

<!-- PULSE:ADR_INDEX -->
| ADR | Title | Status |
| ----- | ------- | -------- |
| [ADR-000](ADR-000-template.md) | Template | — |
| [ADR-001](ADR-001-stt-android-speechrecognizer.md) | STT Provider — Android SpeechRecognizer via speech_to_text | Accepted — under re-evaluation (see ADR-010, ADR-011, ARCH-101) |
| [ADR-002](ADR-002-llm-groq-with-gemini-fallback.md) | LLM Provider — Groq LLaMA 3.3 70B with Gemini 2.5 Flash Fallback | Accepted |
| [ADR-003](ADR-003-tts-on-device-piper-to-f5tts.md) | TTS Engine — On-Device sherpa-onnx Piper (Interim) → F5-TTS ONNX (Target) | Partially superseded — Piper is interim placeholder, F5-TTS ONNX |
| [ADR-004](ADR-004-state-management-bloc-freezed-getit.md) | State Management — BLoC + Freezed + GetIt + fpdart | Accepted |
| [ADR-005](ADR-005-clean-architecture-voice-interfaces.md) | Clean Architecture Swap Pattern — Domain Interfaces for All Voice Components | Accepted |
| [ADR-006](ADR-006-api-key-storage-android-keystore.md) | API Key Storage — Android Keystore via flutter_secure_storage | Accepted |
| [ADR-007](ADR-007-conversation-history-rolling-window.md) | Conversation History — Rolling 8-Turn Window | Accepted |
| [ADR-008](ADR-008-sentence-boundary-tts-trigger.md) | Sentence-Boundary TTS Trigger | Accepted |
| [ADR-009](ADR-009-report-generation-single-llm-call.md) | Post-Session Report Generation — Single LLM Call, Structured JSON | Accepted |
| [ADR-010](ADR-010-unified-audio-pipeline-groq-whisper.md) | Unified Audio Pipeline — Deprecate speech_to_text, Single Raw PCM Stream | Accepted — planned Sprint 3 |
| [ADR-011](ADR-011-stt-performance-optimization.md) | STT Performance Optimization Strategy | Proposed |
| [ADR-012](ADR-012-supertonic-tts-integration.md) | Supertonic TTS Integration Strategy | Proposed |
| [ADR-013](ADR-013-tts-warmup-optimization.md) | TTS Warm-Up Optimization | Accepted |
<!-- /PULSE:ADR_INDEX -->
---

## Statuses

| Status | Meaning |
| -------- | --------- |
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
