# 🏛 Valoqui Architecture Deep Dive

This document provides a technical explanation of Valoqui's architecture. It is designed for developers who need to understand *why* the system is built the way it is and *how* the different layers interact.

---

## 1. Feature-First Modular Clean Architecture

Valoqui strictly adheres to a Domain-Driven, Feature-First Clean Architecture. The codebase is organized by feature (`auth`, `speaking`, `report`), and inside each feature, the code is split into three distinct layers:

### The Three Layers

1. **Domain Layer (The Rules):**
   - Pure Dart. No Flutter dependencies. No external packages (except pure Dart ones like `fpdart`).
   - Contains **Entities**, **Repository Interfaces**, and **Use Cases**.
   - Example Interface (`lib/core/domain/repositories/llm_repository.dart`):

     ```dart
     abstract interface class LlmRepository {
       /// Streams the LLM response token by token.
       /// Yields [Right(token)] for each token.
       /// Yields [Left(AppFailure)] if providers fail.
       Stream<Either<AppFailure, String>> streamResponse({
         required List<ConversationMessage> messages,
         required String systemPrompt,
         int maxTokens = 120,
       });
     }
     
     ```

2. **Data Layer (The Implementation):**
   - Implements the Domain interfaces.
   - Contains **Datasources** (APIs, local databases, ONNX model integrations) and **Repositories** (which coordinate datasources and handle errors).

3. **Presentation Layer (The UI & State):**
   - Contains Flutter **Widgets** and **BLoCs**.
   - Reacts to state changes and dispatches events.

### Why this approach? (See ADR-005)

If we want to swap our Text-to-Speech engine from Piper to F5-TTS, we only write a new `F5TtsDatasource` and update the dependency injection. The Domain, UI, and BLoC remain 100% untouched.

---

## 2. State Management: BLoC + Freezed + fpdart (See ADR-004)

We use a highly structured approach to state and errors:

- **BLoC (`flutter_bloc`):** Manages the state machine. Events go in, States come out.
- **Freezed:** All States, Events, and Models are immutable sealed unions. This forces the UI to handle *every possible state* (Loading, Success, Error) at compile time via `.when()`.
- **fpdart (`Either`):** Exceptions are banned in the Domain/Data layers. Repositories return `Either<AppFailure, Success>`. The BLoC explicitly folds this `Either` to emit a Success or Error state.

---

## 3. Dependency Injection (GetIt)

All dependencies are wired up in `lib/core/di/service_locator.dart`.
We register dependencies in a strict order so that interfaces are resolved seamlessly:

```dart
  // ── Step 2: Repositories (singletons) ────────────────────
  // Registered against their INTERFACES — the rest of the app
  // depends on the interface type, never the concrete class

  sl.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepository(datasource: sl<FirebaseAuthDatasource>()),
  );

  sl.registerLazySingleton<UserRepository>(
    () => FirebaseUserRepository(datasource: sl<FirestoreDatasource>()),
  );

```

---

## 4. The Voice Pipeline Orchestration

The most complex part of the app is the `SpeakingBloc`. It manages a 4-stage pipeline:

1. **Listening (`active(listening)`):** VAD is monitoring the mic.
2. **Processing (`active(processing)`):** Audio is sent to STT. Transcript is sent to LLM.
3. **Speaking (`active(speaking)`):** LLM streams tokens. BLoC detects sentence boundaries and triggers TTS.
4. **Push-To-Talk Fallback (`active(pushToTalk)`):** If VAD fails, the system safely falls back to manual control.

### Performance Optimizations

<!-- PULSE:ADR_INLINE:ADR-011 -->- **STT Performance Optimization Strategy (ADR-011):** Implement chunked streaming (1.5s chunks, 300ms overlap) with sherpa-onnx to show partial transcripts within 1.5s instead of waiting for full utterance. Research Whisper.cpp integration as a swappable backend for future accuracy improvement.<!-- /PULSE:ADR_INLINE:ADR-011 -->
<!-- PULSE:ADR_INLINE:ADR-014 -->- **UI Rebuild Optimization (Token Batching) (ADR-014):** Implement UI throttling (10Hz) and scoped rebuilds using `BlocSelector` to reduce CPU usage and eliminate jank during high-frequency token streaming from the LLM.<!-- /PULSE:ADR_INLINE:ADR-014 -->
<!-- PULSE:ADR_INLINE:ADR-015 -->- **Isolate Backpressure & Buffer Safety (ADR-015):** Implement isolate queue bounding and load shedding to prevent memory leaks and OOM crashes during heavy STT decoding.<!-- /PULSE:ADR_INLINE:ADR-015 -->
<!-- PULSE:ADR_INLINE:ADR-013 -->- **TTS Warm-Up Optimization (ADR-013):** Pre-initialize the TTS engine (silent synthesis pass) as soon as the LLM begins streaming tokens to eliminate the 500-2000ms "cold start" delay during the first spoken sentence.<!-- /PULSE:ADR_INLINE:ADR-013 -->
<!-- PULSE:ADR_INLINE:ADR-008 -->- **Sentence-Boundary TTS Trigger (ADR-008):** Trigger TTS synthesis and playback as soon as a sentence boundary (`.`, `?`, `!`) is detected in the LLM token stream, rather than waiting for the entire response to complete, reducing perceived latency by 40-60%.<!-- /PULSE:ADR_INLINE:ADR-008 -->

### Performance Analysis & Benchmarks

To ensure the audio pipeline remains responsive on low-to-mid-range hardware, we maintain detailed performance logs and mathematical models:

- **[STT Performance Analysis Report](architecture/ARCH-STT-PERFORMANCE-ANALYSIS.md):** A mathematical breakdown of Real-Time Factor (RTF) and physical bottlenecks on Snapdragon 680 hardware.
- **[Market Report: Future STT Alternatives](architecture/ARCH-STT-FUTURE-ALTERNATIVES.md):** A comparison of bleeding-edge models (SenseVoice, Zipformer, Moonshine v2) for next-generation on-device ASR.

---

## 5. Security & BYOK (See ADR-006)

Valoqui operates a "Bring Your Own Key" (BYOK) model.

- Keys are stored in the OS-level encrypted **Android Keystore / iOS Keychain** via `flutter_secure_storage`.
- Keys are **never** synced to Firebase.
- A custom Dio `ApiKeyInterceptor` safely injects the key into HTTP headers right before the request leaves the device.

---

## For More Details

To understand the historical context of these choices, read the **[Architectural Decision Records (ADRs)](decisions/README.md)**.
