# 📏 Valoqui Coding Standards & Golden Rules

This document outlines the strict technical conventions required when contributing to Valoqui. These rules ensure the codebase remains maintainable, scalable, and crash-resistant.

## 1. Architecture Rules

Valoqui strictly follows a **Feature-First Modular Clean Architecture**.

* **No Cross-Layer Contamination:**

  * **UI Code (Widgets/Screens)** must NEVER make network requests, handle complex logic, or access local storage. UI only dispatches BLoC events and renders states.
  * **Domain Layer** must NEVER import Flutter packages or UI code. It is pure Dart.
  * **BLoCs** must NEVER depend on concrete Repositories (e.g., `GroqLlmRepository`). They must only depend on Domain Interfaces (e.g., `LlmRepository`) or Use Cases.

## 2. State Management (BLoC + Freezed)

* **Immutability:** All BLoC States, Events, and Data Models MUST use `@freezed`. No mutable state (`var` or `Map`) is allowed in BLoC states.
* **Exhaustive Matching:** Always use `.when()` or `.maybeWhen()` in the UI to handle Freezed union states. This prevents unhandled loading/error states.
* **No Direct Emit from Streams:** If a BLoC subscribes to a stream in its constructor, it must dispatch an internal event (e.g., `add(_OnStreamDataReceived(data))`) rather than calling `emit()` directly.

## 3. Functional Error Handling (fpdart)

* **No Try/Catch in UI:** BLoCs and UI widgets should never contain `try/catch` blocks.
* **Explicit Either Returns:** All Repositories and Use Cases MUST return `Future<Either<AppFailure, SuccessType>>` or `Stream<Either<AppFailure, SuccessType>>`.
* **Map Exceptions to Failures:** The Data layer (Datasources) can use `try/catch`, but it must catch exceptions and return them mapped to an `AppFailure` union case.

## 4. Dependency Injection (GetIt)

* **Registration Order:** Follow the established order in `lib/core/di/service_locator.dart`: Core Services -> Datasources -> Repositories -> Use Cases -> BLoCs.
* **Factories for BLoCs:** BLoCs must be registered as `registerFactory`, NOT `registerLazySingleton`, so that a fresh state machine is created each time a feature is launched.

## 5. Isolate & Resource Safety

* **Audio Isolates:** When working with Moonshine STT or Piper TTS, you are dealing with heavy native memory. Ensure that all isolates and audio players are explicitly stopped and disposed of in the `close()` method of the BLoC or Repository.
* **Two-Step Kill:** Background isolates should be terminated by passing a polite exit message followed by `Isolate.kill()` to guarantee cleanup and prevent OOM (Out of Memory) crashes.

## 6. Code Generation

If you modify or create a class with `@freezed` or `@JsonSerializable`, you MUST run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Do not commit broken generated code.

## 7. Formatting & Linting

Before opening a PR, always run:

```bash
flutter format lib/ test/
flutter analyze
```

Zero warnings are allowed in `flutter analyze`.
