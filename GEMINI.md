# Valoqui (Lingua) - AI Spanish Conversation Tutor

## Project Overview

Valoqui (internally codenamed Lingua) is a real-time AI conversation partner for language learning. The first phase targets Spanish. It utilizes a hybrid architecture for ultra-low latency voice interactions:

- **STT (Speech-to-Text):** On-device Sherpa-ONNX (Moonshine) engine (migrated from Whisper for lower latency and offline capability).
- **LLM:** Groq LLaMA 3.3 70B Versatile (streaming) for real-time conversation.
- **TTS (Text-to-Speech):** On-device Sherpa-ONNX (VITS/Piper) (eliminating cloud network roundtrips).
- **VAD (Voice Activity Detection):** On-device Silero VAD (segment-based detection for accuracy).
- **Fallback / Redundancy:** Google Gemini 2.0 Flash for LLM failovers.
- **Cost Structure:** "Bring Your Own Key" (BYOK) model storing keys via `flutter_secure_storage` securely in Android Keystore / iOS Keychain.

## Architectural Deep Dive (The "Golden Logic")

### 1. The Audio Pipeline (The "Holy Trinity")

The project is built around an on-device audio processing stack, optimized for 60FPS UI performance.

#### VAD (Voice Activity Detection) - Silero

- **Segment-Based Logic:** `SherpaVadDatasource` uses Silero VAD in segment mode. It emits `Float32List` segments *after* silence is detected, ensuring no audio is lost between detection and transcription.
- **Echo Cancellation (App-Level):** The `SpeakingBloc` stops VAD monitoring during TTS playback to prevent Lucia's voice from being transcribed as user input. VAD is restarted after TTS finishes to flush the internal buffers.

#### STT (Speech-to-Text) - Moonshine

- **Background Isolate Architecture:** Decoding runs in a dedicated `Isolate` (`_SherpaDecodeIsolate`) to avoid blocking the UI thread.
- **Lifecycle Management:** The isolate is captured as an OS-level reference. `dispose()` uses a two-step termination: a polite `null` message followed by `_isolate.kill()` for guaranteed cleanup.
- **PTT Buffer Cap:** Push-to-Talk audio is capped at 60 seconds (~1.9MB) to prevent OOM crashes from abandoned recordings.
- **Memory Alignment:** Explicitly handles `Uint8List` offset alignment (must be a multiple of 2) for `Int16List.view` to prevent crashes on specific Android hardware.

#### TTS (Text-to-Speech) - Piper/VITS

- **WAV Rotation Strategy:** Alternates between `lucia_0.wav` and `lucia_1.wav`. This bypasses `just_audio` URI caching, ensuring the player never serves a stale audio source for consecutive sentences.
- **Truncation Fix:** `maxNumSentences` is raised to 100 to prevent the engine from cutting off audio at the first comma or punctuation mark.
- **State Reset:** Calls `stop()` and `seek(0)` before every sentence to ensure a clean playback state.

### 2. State & Orchestration (SpeakingBloc)

The `SpeakingBloc` acts as the system brain, managing complex transitions between `listening`, `processing`, and `speaking`.

- **Sentence-Boundary TTS:** Instead of waiting for the full LLM response, the BLoC buffers tokens and triggers TTS as soon as a sentence boundary (`.`, `?`, `!`, `…`) is detected. This provides a natural, human-like speaking rhythm.
- **History Window:** Maintains an 8-message rolling window for LLM context while preserving the full session history for the final report card.
- **Error Tiers:**
  - *Business:* Rate limits/Key errors (handled via BLoC UI feedback).
  - *Infrastructure:* Stream exceptions (caught via `onError` handlers).
  - *Fatal:* Both LLM providers down (transitions to `SpeakingState.error`).

### 3. Resilience & Fallbacks

- **Transparent LLM Fallback:** `GroqLlmRepository` manages Groq (Primary) and Gemini (Secondary). If Groq hits a rate limit or fails, it switches to Gemini silently.
- **PTT Fallback:** If the Silero VAD model fails to initialize (e.g., OOM or unsupported hardware), the app automatically falls back to Push-to-Talk mode.

## Development Conventions & Architecture

This project strictly enforces a **Feature-First Modular Architecture**:

- **State Management:** `flutter_bloc` + `freezed`.
  - **NEVER** use `flutter_riverpod` or `provider`.
  - All BLoC states MUST be Freezed unions.
  - Use `state.when()` or `state.maybeWhen()` for exhaustive state handling in UI.
- **Dependency Injection:** `get_it`.
  - All singletons (services) and factories (BLoCs) are registered in `lib/core/di/service_locator.dart`.
  - **Strict Registration Order:** Datasources → Repositories → Use Cases → BLoCs.
- **Error Handling:** `fpdart`.
  - Use `Either<Failure, Success>` instead of `try/catch` blocks in the Domain and Data layers.
  - Failures are defined centrally in `lib/core/domain/models/app_failure.dart`.
- **Network / API:** `dio` with custom interceptors (`ApiKeyInterceptor`, `LoggingInterceptor`, `FallbackInterceptor`).
- **Data Models:** `freezed` and `json_serializable`.
- **Routing:** `go_router`.
- **Backend:** Firebase (Auth, Firestore).

## Project Structure

```text
lib/
├── core/             # Core utilities: DI (get_it), network (dio), router, theme, models (failures.dart)
│   ├── constants/    # Global app constants
│   ├── data/         # Datasources & Repository implementations
│   ├── di/           # service_locator.dart
│   ├── domain/       # UseCases, Models & Repository interfaces
│   ├── network/      # DioClient & Interceptors
│   ├── router/       # app_router.dart
│   └── theme/        # valo_theme.dart
├── features/         # Feature modules: auth, onboarding, home, speaking, report
│   └── [feature]/
│       ├── bloc/     # BLoC, Events, Freezed States
│       └── screens/  # UI Widgets & Screens
├── shared/           # Shared widgets across features
├── app.dart          # MultiBlocProvider, MaterialApp.router setup
└── main.dart         # Entry point, Firebase init, GetIt setup
```

## AI Agent Guidelines (The Valoqui Manifesto)

When working in this directory, AI agents MUST follow these rules:

1. **Adhere to the Finalized Stack:** BLoC + Freezed + get_it + Dio + fpdart.
2. **BYOK Security:** Never log or hardcode API keys. Always use the injected `SecureStorageService`.
3. **Immutability:** Always use Freezed for states and data models.
4. **Isolate Management:** When modifying STT/VAD logic, ensure isolates are killed explicitly to avoid memory leaks.
5. **Audio Integrity:** Preserve the `SpeechSegment` flow between VAD and STT. Ensure background isolates are used for heavy decoding tasks.
6. **Error Type Semantics:** Use `AppFailure.ttsFailure` or `AppFailure.sttFailure` for local errors, NOT `networkFailure`.
7. **Clean Architecture:** Respect boundaries between Data, Domain, and Presentation layers. Never put business logic in UI widgets.
8. **Surgical Edits Only:** ALWAYS prefer surgical replacements over rewriting entire files to preserve architectural comments and context.
9. **ADR Immutability:** Never delete or overwrite the historical context of an Architectural Decision Record (ADR). To update an ADR, change its `Status` and append an "Update" or "Addendum" section at the bottom. Never change the numerical prefix of an existing ADR, and always increment correctly for new ones.

### 4. Definition of Done (The Committer's Checklist)

Before preparing any commit or claiming a task is complete, the AI agent MUST autonomously:

1. **Format Code:** Run `dart format .` to ensure CI compliance.
2. **Lint Check:** Run `flutter analyze` and ensure zero errors/warnings.
3. **Update Changelog:** Surgically add implementation notes to `CHANGELOG.md`, ensuring all new features and ADRs (by ID) are mentioned.
4. **Verify Integrity:** Run `python3 scripts/pulse_audit.py` and ensure a "Pass" message is received.

### 5. Documentation Strategy (The "Linked Brain" v2)

The documentation in `docs/` is self-maintaining using a **Global SSOT Macro System** to ensure 100% integrity across all files (Setup, Onboarding, Architecture, etc.).

- **Single Source of Truth (SSOT):** Decisions (ADRs) are the primary source.

- **Pulse Auditor Macros:** Use the following HTML comments in any `.md` file to auto-inject latest data:

  - `<!-- PULSE:ADR_INDEX -->`: Injects the full markdown table of ADRs (used in README.md).
  - `<!-- PULSE:ADR_LIST -->`: Injects a plain-text list of ADR IDs and titles (used in SETUP.md).
  - `<!-- PULSE:ADR_INLINE:ADR-XXX -->`: Injects a specific ADR's latest title and summary on a single line (used in ARCHITECTURE.md).

- **Automated Sync (`scripts/pulse_audit.py`):** Scans ALL project markdown files and applies macros. Also performs Asset Integrity, DI Registration, and Architecture Boundary audits.
- **Git Enforcement:** A `post-commit` hook (in `.git/hooks/post-commit`) runs the full Pulse Audit on every change.
