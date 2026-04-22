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

<!-- PULSE:ADR_INLINE:ADR-013 -->- **TTS Warm-Up Optimization (ADR-013):** No summary provided.<!-- /PULSE:ADR_INLINE:ADR-013 -->
<!-- PULSE:ADR_INLINE:ADR-008 -->- **Sentence-Boundary TTS Trigger (ADR-008):** No summary provided.<!-- /PULSE:ADR_INLINE:ADR-008 -->

---

## 5. Security & BYOK (See ADR-006)

Valoqui operates a "Bring Your Own Key" (BYOK) model.

- Keys are stored in the OS-level encrypted **Android Keystore / iOS Keychain** via `flutter_secure_storage`.
- Keys are **never** synced to Firebase.
- A custom Dio `ApiKeyInterceptor` safely injects the key into HTTP headers right before the request leaves the device.

---

## For More Details

To understand the historical context of these choices, read the **[Architectural Decision Records (ADRs)](decisions/README.md)**.
