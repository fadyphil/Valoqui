# Valoqui Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- Implemented TTS Background Isolate and Pipelined Synthesis (ADR-016)
  - Created `_SherpaTtsIsolate` to handle all TTS inference and file writing in a background process, eliminating UI jank.
  - Implemented pipelined `_drainQueue` that synthesizes sentence $N+1$ while sentence $N$ is playing, reducing inter-sentence gaps.
  - Refactored `SherpaTtsDatasource` to communicate via isolated message passing with safe lifecycle management (`kill()` on dispose).
- Optimized STT performance for mid-range Android (ADR-017 Tuning):
  - Added precise RTF (Real-Time Factor) and decode latency logging via `Stopwatch` in the background isolate.
  - Reverted Android provider to `"cpu"` to bypass NNAPI operator fallback overhead on Snapdragon 6xx series chips.
  - Reduced `numThreads` to 2 to optimize for BIG.LITTLE architectures and prevent thread contention.
- Retained Sherpa-ONNX Moonshine STT based on benchmarks showing 50x speed advantage over Whisper.cpp on Android.
- Fixed Sherpa-ONNX initialization in background isolates by adding `sherpa.initBindings()` to isolate entry points.
- Implemented TTS warm-up optimization (ADR-013) to eliminate cold start latency
  - Added `warmUp()` method to `TtsRepository` interface
  - Implemented `SherpaTtsDatasource.warmUp()` with silent synthesis pass
  - Updated `SherpaTtsRepository` to delegate warm-up to datasource
  - Modified `SpeakingBloc._streamLlmResponse()` to call `_tts.warmUp()` when LLM streaming begins
- Proposed Supertonic TTS Integration Strategy (ADR-012) for higher-quality on-device voice
- Added PTT buffer limit visualization (ADR-015)
  - `bufferFillPercentage` added to `SpeakingActive` state.
  - `MicButton` displays a dynamic circular progress indicator when approaching the 60-second limit.
- Automated quality gates via Git pre-commit hook
  - Hook enforces `dart format`, `flutter analyze`, and `pulse_audit.py` before every commit.
  - Added "Definition of Done" to `GEMINI.md` for AI agent proactive compliance.

### Changed

- Implemented STT Performance Optimization (ADR-011) to resolve streaming bottlenecks (Fixes #7)
  - Increased STT decode threads to 4 and VAD threads to 2.
  - Implemented throttled accumulating buffer to yield partial transcripts every 1.5s while speaking.
  - Added `partialTranscriptStream` to provide live UI feedback.
- Implemented UI Rebuild Optimization (ADR-014)
  - Batched LLM token emissions to 10Hz using `_tokenBatchTimer`.
  - Scoped active text bubble rebuilds using `BlocSelector` to eliminate UI jank during generation.
- Implemented Isolate Backpressure & Buffer Safety (ADR-015)
  - Hard capped the background STT decode queue to 3 concurrent decodes.
  - Implemented load shedding (dropping segments) to prevent OOM errors and latency spikes.
- Optimized LLM memory usage and fallbacks
  - Replaced char-by-char split parsing with `LineSplitter` in Groq and Gemini datasources.
  - Broadened Groq-to-Gemini fallback to handle server 5xx errors and timeouts.
  - Cached Gemini API key to reduce secure storage lookups.
  - Enforced strict `_llmSub` lifecycle management in `SpeakingBloc` to prevent memory leaks.

## [Sprint 3] - 2026-04-21

### Added

- Documentation for Audio Pipeline Concurrency and Performance Optimization
- Await stream expectations in usecase stream tests
- Behavior-focused usecase coverage and testing rationale docs

### Changed

- Fixed retry logic to be only for parsing errors
- Formatted code using dart format and added missing imports
- Aligned new usecase tests with CI dart format expectations

## [Sprint 1] - 2026-04-18

### Added

- MVP-piper tag
- Screenshots gallery and updated README documentation map
- Extra markdown files for analysis and lessons across all 3 Sprints
- Full PRD and Sprints documentation
- App designs
- README with documentation map and polished layout
- Product requirements and sprint planning
- Project documentation and onboarding guides
- Firestore rules
- Icons generation for iOS/Android
- Dark/Light logos
- Flutter launcher icons dependency

### Changed

- Lowered CI coverage threshold temporarily (behavior-focused tests on blocs only)
- Formatted tests for code quality gate
- Fixed CI test and coverage job (missing mock stubs for stop()/stopMonitoring())
- Fixed test coverage job for assets
- Fixed formatting for Firebase options
- Added placeholders for assets to pass CI and injected Firebase options as secret
- Formatted all code using 'dart format --set-exit-if-changed .'
- Fixed font problem in assets

### Fixed

- Speaking bloc destroying singletons issue - now stops active operations instead of killing singletons
- Added spaces and followed markdown format guidelines in PR template

## [Pre-Sprint] - 2026-04-17

### Added

- Handoff document after testing session of (auth, onboarding, home, speaking, report) features

### Changed

- Removed old redundant bloc tests
- Added permission handler platform interface for tests
- Removed '_' from events for improved testability
- Updated registrations needed for new speaking, report, auth and onboarding bloc tests
- Added const and removed '_' in the permissionChannel
- Added comprehensive layered test suites for AuthBloc, HomeBloc, OnboardingBloc, ReportBloc
- Completed layered test suite for SpeakingBloc
- Updated README.md
- Added PR Template for organized structure and clear communication
- Added Issue templates for features and bugs
- Added documentation for decisions and setup (needs revision)
- Added SECURITY.md policy
- Added MIT license
- Ignored additional agents files

## [March 2026] - 2026-04-09 to 2026-04-08

### Added

- Explicit catch clause type (on Exception)
- Replaced async calls for file creation/writing in copy assets (performance optimization)
- Modified boolean parameter of event to named parameter for cleaner signature
- Added explicit return types to right/left (don't infer everything)
- Updated workflow to evaluate code quality from normal built-in linter
- Changed all imports and formatting to follow lint rules
- Added support for Amplitude (removed from UI, placed in state/BLoC)
- Fixed speaking stream contracts, error handling, and resource cleanup
- Added explicit type casting and defensive I/O (don't trust file-system or API)
- Fixed STT isolate lifecycle, timeout, and resource leak issues
- Fixed TTS truncation, caching, and player state issues
- Fixed VAD lifecycle, stream contract, and error semantics issues
- Enhanced linting rules and infrastructure tooling

### Changed

- Ran dart format
- Commented out custom lints in CI and delayed custom linting due to complexity
- Added CI/CD workflows
- Better formatted mistake card and report screen
- Ignored new project assisting files (dependencies)

## [Early April 2026] - 2026-04-06 to 2026-04-03

### Added

- Polished theme and cleaned up redundant asset entry
- Polished UI for report feature and added descriptive loading state
- Enhanced waveform animation and speaking screen UX
- Refined STT architecture and fixed OS cutoffs
- Updated project manifesto and created professional readme for MVP phase 1
- Synced generated files after restoring speech_to_text
- Added Silero VAD and Sherpa-ONNX STT models
- Marked Android Native STT as deprecated
- Applied fontFamily to BottomNavigationBar labels
- Optimized SpeakingBloc for Sherpa-ONNX unified pipeline
- Implemented on-device Sherpa-ONNX STT and unified VAD pipeline
- Updated namespace and applicationId to com.valoqui.app
- Updated native registrations for linux, macos, and windows
- Implemented speaking and report features and integrated with home
- Updated network, router, and DI for new features
- Implemented LLM, STT, TTS, VAD datasources and repositories
- Defined models and repositories for conversation, LLM, STT, TTS, VAD
- Added speech_to_text, sherpa_onnx, just_audio, record, permission_handler dependencies
- Updated .gitignore to exclude sensitive and large files
- Completed .gitignore
- Migrated opacity calls to Color.withValues (performance)
- Updated secure storage Android options
- Updated root widget smoke test and enabled sl reassignment
- Added widget tests for sign-in and level selection screens
- Implemented comprehensive bloc tests for auth, onboarding, and home
- Added unit tests for auth use cases
- Enhanced mock services with specific use case and repository mocks
- Configured app entry point and enabled edge-to-edge UI
- Implemented auth, home, and onboarding modules
- Implemented clean architecture foundation and shared layers
- Initialized project dependencies and firebase environment
- Updated google-services.json for firestore
- Used set with merge for user profile updates

## [Initial Commit] - 2026-03-18

### Added

- Initial project setup
