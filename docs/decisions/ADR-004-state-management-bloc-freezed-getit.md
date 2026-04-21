# ADR-004: State Management — BLoC + Freezed + GetIt + fpdart

**Date:** 2026-03
**Status:** Accepted
**Sprint:** Sprint 1
**Decider:** Fady

---

## Context

The original Sprint 1 guide (v1.0) used Riverpod. Before implementation
began, the stack was replaced with BLoC + Freezed + GetIt + fpdart to align
with the developer's production experience from the Osserva project. This
decision affects every layer of the application.

---

## Decision

Valoqui uses:

- `flutter_bloc` for state management
- `freezed` for sealed union states and data models (compile-time exhaustive
  pattern matching via `when()`)
- `get_it` for dependency injection (service locator pattern)
- `fpdart` `Either<Failure, Success>` for explicit error handling in all
  service and repository methods
- `dio` for HTTP (replaces `http` package)

---

## Alternatives considered

### Option A — Riverpod (original Sprint 1 v1.0 spec)

**Why considered:** Excellent DI integration, compile-safe providers, strong
Flutter community adoption.
**Why rejected:** Developer has no production experience with Riverpod.
BLoC + GetIt matches existing production patterns from Osserva, reducing
cognitive overhead and risk on a solo project.

### Option B — BLoC + Freezed + GetIt (chosen)

**Why selected:** Production-proven on prior project. BLoC's explicit event →
state model maps cleanly onto the voice pipeline state machine (listening →
processing → speaking). Freezed sealed unions enforce exhaustive state
handling at compile time — critical for a pipeline with many failure modes.

---

## Consequences

### Positive

- `when()` on Freezed states means unhandled state variants are compile errors,
  not runtime crashes.
- Clean architecture enforced by convention: datasource → repository →
  use case → BLoC. GetIt makes every layer independently testable.
- `Either` eliminates silent swallowed exceptions in service methods.

### Negative / tradeoffs

- Freezed requires `build_runner` code generation. Every `@freezed` class
  change requires: `dart run build_runner build --delete-conflicting-outputs`.
- More boilerplate than Riverpod for simple state (separate event, state,
  and bloc files per feature).
- `emit()` must only be called from within event handlers — calling it from
  stream subscriptions in constructors causes runtime errors. Internal
  `_PrivateEvent` pattern required for stream-driven state changes.

### Constraints introduced

- All `*.freezed.dart` and `*.g.dart` files must be regenerated after any
  Freezed source change. This must be part of every PR checklist.
- Stream subscriptions in BLoC constructors must dispatch internal events
  (`add(_InternalEvent(...))`) rather than calling `emit()` directly.

---

## Links

- Sprint 1 Guide v2.0 (complete stack definition)
- Sprint 1 Guide v2.0 § 8 (Freezed BLoC states)
- Sprint 1 Guide v2.0 § 4 (failure types)
