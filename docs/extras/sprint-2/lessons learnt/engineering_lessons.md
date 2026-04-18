# Engineering Lessons from the Valoqui Pipeline Analysis

> These lessons are drawn from real bugs found in your own codebase.
> The goal is not just to know the fixes — it's to build the mental models
> that let you *catch these classes of problem yourself* before an analysis tool does.

---

## Table of Contents

1. [Concurrent Programming — The Async Trap](#1-concurrent-programming--the-async-trap)
2. [Resource Ownership — Who Is Responsible for Cleanup?](#2-resource-ownership--who-is-responsible-for-cleanup)
3. [Bounding Your Data Structures](#3-bounding-your-data-structures)
4. [Layered Architecture — The Contract Between Layers](#4-layered-architecture--the-contract-between-layers)
5. [Lifecycle Mismatches — The Singleton/Factory Trap](#5-lifecycle-mismatches--the-singletonfactory-trap)
6. [Defensive I/O — Never Trust the Filesystem](#6-defensive-io--never-trust-the-filesystem)
7. [Error Handling as Architecture](#7-error-handling-as-architecture)
8. [The Semantics of Types — Using the Right Name](#8-the-semantics-of-types--using-the-right-name)
9. [Stream Contract Design](#9-stream-contract-design)
10. [Mental Model: How to Read Your Own Code for These Issues](#10-mental-model-how-to-read-your-own-code-for-these-issues)

---

## 1. Concurrent Programming — The Async Trap

### The Bug

```dart
// In SherpaSttDatasource
final text = await reply.first as String; // ← hangs forever if isolate dies
```

### What's Actually Happening

When you `await reply.first`, you are suspending the current execution and telling Dart:
*"don't continue until this port sends me something."*

The problem is that you are making an assumption: **the other side will always respond**. But the "other side" here is a background isolate running native Sherpa-ONNX code. It can:

- Crash due to an OOM on a low-memory device
- Throw a native exception inside the C++ runtime
- Be killed by the OS under memory pressure

When any of those happen, no one sends to `reply`. Your `await` never resolves. The function is suspended indefinitely. The call stack above it is also blocked. The user sees a spinner forever.

This is sometimes called a **deadlock** (nothing can make progress) or a **livelock** (things seem to be running but no useful work is happening).

### The Mental Model: Timeouts Are Not Pessimism

Every `await` that crosses a process or isolate boundary should ask:
> *"What happens if the other side never responds? How long am I willing to wait?"*

This is not defensive paranoia — it's the correct default assumption for concurrent code. Local function calls are synchronous and can't "disappear." Async boundaries (isolates, HTTP, sockets, platform channels) can always fail to respond.

```dart
// The pattern:
final result = await someAsyncOperation().timeout(
  const Duration(seconds: 10),
  onTimeout: () => fallbackValue,
);
```

`onTimeout` lets you degrade gracefully instead of hanging. Returning `""` for a failed STT decode is infinitely better than a frozen app.

### The Related Bug: Fire-and-Forget

```dart
_drainQueue(); // ← fire-and-forget, no await
```

This is the inverse problem. Instead of waiting forever, here the code *doesn't wait at all*. It fires an async function and immediately moves on.

The race: between `_drainQueue()` being called and the first line of `_drainQueue()` executing, another `speak()` call can come in. It checks `_isDrainingQueue`, finds it `false` (because `_drainQueue` hasn't set it yet), and starts a second drain loop. Now you have two loops both pulling from the same queue — a **race condition**.

```Markdown
speak("Hola!") → _isDrainingQueue=false → starts drainQueue A
[microtask yields]
speak("¿Cómo estás?") → _isDrainingQueue=false → starts drainQueue B  ← BUG
[drainQueue A sets _isDrainingQueue=true, but it's too late]
```

The fix: set the guard flag **synchronously before any async gap**:

```dart
if (!_isDrainingQueue) {
  _isDrainingQueue = true;  // synchronous — no await gap
  _drainQueue();            // fire-and-forget is now safe
}
```

### What to Ask When Writing Async Code

1. *If the awaited operation never responds, what happens?* → Add a timeout.
2. *If this function is called again before it finishes, what happens?* → Think about re-entrancy guards.
3. *Am I assuming the other side will always cooperate?* → Don't.

---

## 2. Resource Ownership — Who Is Responsible for Cleanup?

### The Bug

```dart
Future<void> dispose() async {
  await stopMonitoring();
  await _recorder.dispose();
  // ← _vad.free() is NEVER called
}
```

### Two Kinds of Memory

Dart's garbage collector handles **Dart objects** automatically. When nothing references an object, it gets collected.

But `sherpa.VoiceActivityDetector` is not a pure Dart object. It's a **wrapper around native memory** — C++ heap allocations made by the Sherpa-ONNX library running through FFI. The Dart GC has no visibility into that memory. It sees a small Dart object (the wrapper), not the ~1MB ONNX model loaded in native memory.

When the Dart wrapper is collected, the native memory is **not freed** unless you explicitly call `.free()`. This is a **native memory leak**.

### The Pattern: Every Resource Has an Owner

The rule is simple: whoever creates a resource is responsible for destroying it. If `SherpaTtsDatasource` creates the TTS engine, it must free it on `dispose()`. There is no one else.

This is especially important in your architecture because `SpeakingBloc` is **route-scoped** — a fresh instance per session. Each new session creates a new datasource, which loads the model again. Without `.free()`, each session's model stays in native memory alongside the new session's. After 5 sessions: 5MB of leaked ONNX model memory.

The checklist for any class that initializes native resources:

```dart
class MyDatasource {
  NativeResource? _resource;

  Future<void> initialize() async {
    _resource = NativeResource.create(...);  // ← you own this
  }

  Future<void> dispose() async {
    _resource?.free();   // ← you must free this
    _resource = null;
  }
}
```

### The Related Bug: Isolate Zombie

```dart
void dispose() {
  _port?.send(null);   // asks the isolate to clean up
  _port = null;
  // ← Isolate object never killed
}
```

An `Isolate` is an OS-level resource. Sending `null` to its receive port is a *polite request* to self-terminate. But if the isolate is mid-decode when `null` arrives, it doesn't process the message immediately — it finishes what it's doing first.

If the isolate crashes before processing the null, the request is never handled, and the isolate process becomes a **zombie**: officially no longer useful, but still consuming OS resources.

`Isolate.kill(priority: Isolate.immediate)` bypasses the message queue entirely. It's a forceful OS-level termination. You should always store and kill the `Isolate` object, using the polite `send(null)` as a first-attempt and the `kill()` as the guaranteed cleanup.

---

## 3. Bounding Your Data Structures

### The Bug

```dart
final BytesBuilder _audioBuffer = BytesBuilder(); // unbounded
```

### The Mental Model: Unbounded Growth is a Bug

Any data structure that can grow indefinitely in a running system is a bug waiting to happen. It might not manifest in testing (your test recordings are 5 seconds), but in production a user holds the PTT button while explaining their entire life story, and the buffer eats 100MB.

At 16kHz mono PCM16:

- 1 second = 32KB
- 1 minute = 1.9MB  
- 5 minutes = 9.6MB  
- 30 minutes = 58MB

The fix is not just adding a cap — it's **deciding what to do when the cap is hit**. Your options:

1. **Truncate silently** — drop excess audio. Acceptable for PTT; the user just spoke too long.
2. **Auto-submit** — when the buffer hits the cap, treat it as if the user released the button. Forces a natural break.
3. **Warn the user** — surface a "max recording length reached" message.

The right choice depends on UX. But all three are better than an OOM crash.

```dart
static const int _maxBufferBytes = 16000 * 2 * 60; // 60 seconds

void _onAudioBytesReceived(List<int> chunk) {
  if (_audioBuffer.length < _maxBufferBytes) {
    _audioBuffer.add(chunk);
  }
  // Always process amplitude regardless of buffer cap
  _calculateAndEmitAmplitude(chunk);
}
```

Notice: amplitude calculation continues even when the buffer is capped. Think about which side effects of a capped operation should still happen.

### General Rule

Whenever you write code that **accumulates** over time — a list you keep appending to, a buffer you keep writing to, a queue that only grows — ask:
> *"What is the maximum size this will ever reach? What happens when it reaches that?"*

If the answer is "I don't know" or "it depends on the user," you need a bound.

---

## 4. Layered Architecture — The Contract Between Layers

### The Bug

```dart
// In SpeakingScreen (UI layer):
ampStream = sl<SttRepository>().amplitudeStream;  // ← reaches past BLoC into domain layer
```

### Why Layers Exist

Your architecture has a deliberate structure:

```Markdown
UI (screens, widgets)
    |
    ↓ only reads BLoC states, dispatches BLoC events
BLoC (business logic)
    |
    ↓ only calls repositories
Repository (domain interfaces)
    |
    ↓ only calls datasources
Datasource (raw data)
```

Each arrow is a **contract**. The UI's contract says: "I only communicate with the BLoC." When the screen reaches directly into `sl<SttRepository>()`, it's violating its own contract. It now has two dependencies: its BLoC AND a repository.

The consequences:

1. **Untestable**: Widget tests can't mock the amplitude stream. You'd have to register a fake `SttRepository` in `get_it` for every test.
2. **Hidden coupling**: Someone reading `SpeakingScreen` sees a BLoC dependency. They don't realize there's also a hidden `SttRepository` dependency unless they read every line carefully.
3. **Double source of truth**: The screen now has its own data pipeline, parallel to the BLoC's pipeline. They can drift out of sync.

### The Fix: Push Data Up to the State

The BLoC already subscribes to the amplitude stream for other purposes. It should simply include the amplitude value in its emitted state:

```dart
// In SpeakingBloc constructor:
_stt.amplitudeStream.listen((amp) {
  final current = state;
  if (current is SpeakingActive) {
    emit(current.copyWith(amplitude: amp));
  }
});

// In SpeakingState.active:
@Default(0.0) double amplitude,
```

Now the screen reads `state.amplitude` from its BLoC — exactly as it should. One dependency. Testable. No hidden coupling.

### The Mental Model: "What Layer Am I In?"

Before writing any line of code, ask: *what layer does this file live in?* Then enforce:

- **UI layer**: only BLoC state and events. No `sl<>` calls. No repository calls.
- **BLoC layer**: only repository interfaces. No datasources. No `sl<>` calls.
- **Repository layer**: only datasources. No BLoC.
- **Datasource layer**: raw I/O only.

If you find yourself in a UI file writing `sl<>`, stop. That data should come from the BLoC.

### The Related Observation: Datasource Depending on a Repository

The analysis also flagged that `SherpaSttDatasource` depends on `VadRepository` (a domain interface). A datasource in the data layer should not depend on a repository in the domain layer. It should depend on another datasource.

This is a subtler violation. The dependency direction should be:

```Markdown
domain/repositories → domain/models
data/repositories   → domain/repositories (implements them)
data/datasources    → other data/datasources (not domain/repositories)
```

When a datasource reaches up into the domain layer, it creates a **circular dependency risk** and makes the layering semantically meaningless. The fix is to have `SherpaSttDatasource` depend on `SherpaVadDatasource` directly.

---

## 5. Lifecycle Mismatches — The Singleton/Factory Trap

### The Bug

```dart
// service_locator.dart
sl.registerFactory<SpeakingBloc>(...);         // ← new instance per request
sl.registerLazySingleton<SttRepository>(...);   // ← one instance forever
sl.registerLazySingleton<TtsRepository>(...);   // ← one instance forever
sl.registerLazySingleton<VadRepository>(...);   // ← one instance forever
```

### The Lifecycle Mismatch

`SpeakingBloc` is a factory — you get a fresh one each time you navigate to the speaking screen. When the BLoC closes (route pops), it calls `dispose()` on all its repositories.

But those repositories are singletons. When session 1's BLoC calls `tts.dispose()`, the singleton `TtsRepository` is now disposed. When session 2's BLoC is created, it gets the **same disposed singleton**.

Session 1 ends → BLoC.close() → tts.dispose() → TtsRepository is dead  
Session 2 begins → new BLoC → gets same dead TtsRepository → calls tts.speak() → crash

This doesn't manifest with a single session, which is why it slipped through. "Speak Again" is the trigger.

### The Root Cause: Lifetime Must Match

The rule: **an object's lifetime must match the lifetime of every object that depends on it**. If the BLoC lives for one session, everything the BLoC owns must also live for one session.

Two valid fixes:
**Option A: Make datasources factories too**

```dart
sl.registerFactory<SttRepository>(...);  // fresh instance per BLoC
```

Pro: simple. Con: model initialization cost on every session start.
**Option B: Add re-initialization guards to datasources**

```dart
Future<Either<AppFailure, void>> initialize() async {
  _disposed = false;
  _initialized = false;
  // ... full init sequence
}
```

The datasource stays as a singleton but resets its internal state on each `initialize()` call. The BLoC calls `initialize()` at session start, which re-arms the singleton.

Option B is better for datasources that load large model files — you don't want to re-copy 76MB on every session. The file stays on disk; you just reinitialize the runtime handle.

### The General Pattern: Registration Type is a Lifecycle Decision

When you register something in `get_it`, you are making a **lifecycle decision**:

| Registration | Lifetime | Use for |
| --- | --- | --- |
| `registerSingleton` | App lifetime | Auth, Firestore, network client |
| `registerLazySingleton` | App lifetime (created on first use) | Same as above |
| `registerFactory` | Per-request (new instance each `sl<>` call) | BLoCs, use cases |
| `registerFactoryParam` | Per-request with parameters | BLoCs that need init params |

Services that should outlive any single screen: singletons.  
Objects that represent a screen's state: factories.  
Objects that the BLoC *owns* (and disposes): should match the BLoC's lifecycle.

---

## 6. Defensive I/O — Never Trust the Filesystem

### The Bug

```dart
Future<String> _copyAssetToLocal(String assetPath) async {
  final file = File(localPath);
  if (!await file.exists()) {
    // copies file...
  }
  return localPath; // assumes the file is valid if it exists
}
```

### Why Android Can Delete Your Files

Android's documents directory (`getApplicationDocumentsDirectory()`) is **not guaranteed to persist**. The OS can clear it under low storage conditions. This is documented behavior, not a bug.

Your `exists()` check only protects against the file never being written. It doesn't protect against:

- The file being partially written (app crashed mid-copy)
- The OS clearing it between sessions
- File corruption

A partially written ONNX file is worse than no file — your Sherpa initializer will try to parse it, fail with an unhelpful native error, and potentially crash rather than giving you a clean error you can handle.

### The Defense: Check Existence AND Validity

```dart
if (!await file.exists() || (await file.length()) < 100) {
  // re-copy from assets
}
```

The size check (`< 100` bytes) catches partial writes. A valid ONNX model is at minimum several KB. This is not a perfect integrity check — a proper implementation would use a checksum — but it catches the most common failure mode at near-zero cost.

### The General Rule for File-Dependent Systems

Any system that caches files on disk must answer three questions:

1. **Does the file exist?** (`File.exists()`)
2. **Is the file complete?** (size check, or a checksum)
3. **Is the file the right version?** (for future upgrades — store a version marker alongside the file)

For your MVP, 1 and 2 are sufficient. Add 3 when you ship a model update and need existing installs to re-download.

---

## 7. Error Handling as Architecture

### The Bug

```dart
_llm.streamResponse(...).listen(
  (event) => event.fold(
    (failure) => add(_LlmError(failure)),
    (token)   => add(_LlmTokenReceived(token)),
  ),
  onDone: () => add(const _LlmResponseComplete()),
  // ← NO onError handler
);
```

### Two Kinds of Errors in Dart Streams

A Dart `Stream<T>` can fail in two distinct ways:

**1. A value of type `T` that represents an error**  
This is what `Either<Failure, Token>` does — the stream emits a "value" that is semantically an error. Your `fold` handles this correctly.

**2. The stream itself throws an exception**  
This is different. The stream emits an **error event** (not a data event). If your listener has no `onError`, Dart treats this as an unhandled exception. In a BLoC context, this can crash the BLoC silently without transitioning to an error state — the user sees nothing, the BLoC is dead.

The `Either` pattern catches *expected* business errors. The `onError` handler catches *unexpected* infrastructure errors — things that bypass your `Either` wrapper entirely.

```dart
// The defensive pattern — always include onError on stream subscriptions
.listen(
  (event) => ...,
  onDone: () => ...,
  onError: (error, stackTrace) {
    // Log it
    debugPrint('[Stream] Unexpected error: $error\n$stackTrace');
    // Recover gracefully
    add(_LlmError(AppFailure.llmFailure(message: "Unexpected error: $error")));
  },
);
```

### The Principle: Error Handling at Every Layer

The architecture uses `Either<Failure, T>` for expected failures. That's good. But it's not sufficient alone. Think of error handling in three tiers:

| Tier | Mechanism | Catches |
| --- | --- | --- |
| Expected business errors | `Either<Failure, T>` | Rate limits, invalid keys, empty responses |
| Unexpected exceptions | `try/catch` and stream `onError` | Library bugs, null dereferences, parsing failures |
| Fatal unrecoverable | BLoC `error` state | Mic permission denied, both LLMs down |

Tier 2 is the one developers most often skip. It's the catch-all that keeps unexpected things from silently breaking the system.

---

## 8. The Semantics of Types — Using the Right Name

### The Bug

```dart
// STT datasource:
return left(AppFailure.networkFailure(message: "STT init failed: $e"));

// VAD datasource:
return left(AppFailure.networkFailure(message: "VAD init failed: $e"));
```

### Why This Matters

STT and VAD initialization failures are **local** — model files, memory, native library issues. Using `networkFailure` misrepresents what happened.

This isn't just aesthetics. Code that handles errors downstream does things like:

```dart
failure.when(
  networkFailure: (_) => showNetworkErrorMessage(),  // ← wrong behavior shown
  sttFailure: (_) => showMicPermissionGuide(),
  ...
)
```

If a model file is missing and you throw `networkFailure`, the user sees "Check your connection" when the real problem is a corrupted file. The error type is a semantic contract — it tells callers *what kind of thing went wrong* so they can respond appropriately.

### The Broader Principle: Types Carry Meaning

Dart's type system is a communication tool. `AppFailure.networkFailure` means "the network did something wrong." Using it for local failures is like writing a function named `getUserProfile()` that actually deletes the user.

When you create a type (especially a sealed union like `AppFailure`), you are defining vocabulary. Every use of that vocabulary should be precise.

Rule of thumb: if the error message inside the type has to contradict the type name (e.g., `networkFailure(message: "model file not found")`), you have the wrong type.

---

## 9. Stream Contract Design

### The Bug

```dart
// VAD emits both events synchronously in the same callback:
_vadController.add(true);   // speech detected
_vadController.add(false);  // silence — utterance complete
```

### What This Does to Consumers

When both `true` and `false` arrive in the same callback execution, consumers see them as two stream events in the same microtask. The time between "speech started" and "speech ended" is measured as ~0ms.

If you are using `voiceActivityStream` to measure speaking duration:

```dart
onData: (isActive) {
  if (isActive) {
    _startTime = DateTime.now();
  } else {
    final duration = DateTime.now().difference(_startTime!);
    // ← this will always be ~0ms
  }
}
```

The bug is in the **contract of the stream**. What does `voiceActivityStream` promise? Based on the name, consumers expect:

- `true` = "user is currently speaking" (onset)
- `false` = "user has stopped speaking" (offset)
- Time between them = utterance duration

But the implementation delivers them simultaneously, violating that intuitive contract.

### Designing Stream Contracts

Before creating a stream, write down what it promises:

## `voiceActivityStream` emits ->

> - `true` when VAD detects the onset of speech
> - `false` when VAD detects the end of speech (after silence threshold)
> - Guarantee: `true` and `false` always arrive in alternating order
> - Guarantee: there is measurable time between `true` and `false`

If the implementation can't fulfill that contract (because both events happen in the same callback), change the design. Options:

- **Option A: Only emit completion (the simpler contract)**

```dart
// voiceActivityStream only emits on utterance completion
// No "started" event — consumers assume silence between emissions
_vadController.add(false); // utterance complete
```

- **Option B: Change the event type to carry the duration**

```dart
// Instead of Stream<bool>, use Stream<UtteranceDuration>
_durationController.add(UtteranceDuration(milliseconds: elapsed));
```

Option A is simpler and sufficient for your current use case. Option B is semantically richer but adds complexity. Since your BLoC already tracks start time independently, Option A is the right choice here.

---

## 10. Mental Model: How to Read Your Own Code for These Issues

These bugs share a pattern. They're almost invisible when you're writing the code — you're focused on making the happy path work. They become visible when you ask adversarial questions about each piece of code.

### The Five Questions

After writing any non-trivial method, ask:

**1. What happens if this never returns?**  
For every `await`: what if the other side is silent? Do you have a timeout?

**2. What happens if this is called twice?**  
For any stateful operation: re-entrancy. What if `initialize()` is called on an already-initialized object? What if `speak()` is called while already speaking? What if `dispose()` is called twice?

**3. What is the maximum size of this data structure?**  
For every buffer, list, queue, or stream: what's the worst case? Is it bounded?

**4. Who frees this?**  
For every resource created (especially native): is there a matching `.free()`, `.dispose()`, `.close()`? Is it guaranteed to be called even if an exception is thrown?

**5. What layer am I in, and am I staying in it?**  
Before every dependency: does this file *belong* in this layer? Would a reader expect this dependency?

### The Review Habit

When you finish a feature, do a second pass where you only look at:

- Every `await` — has a timeout if it crosses a process boundary?
- Every `StreamSubscription` — has an `onError`?
- Every `initialize()`/`dispose()` pair — are they both called? Is the lifecycle correct?
- Every data structure that accumulates — is it bounded?
- Every `sl<>` call — is it in the right layer?

This takes 10 minutes and catches 80% of these issues before they reach production.

---

## Summary Table

| Issue | Category | Key Mental Model |
| --- | --- | --- |
| Isolate decode hangs | Async trap | Every cross-boundary `await` needs a timeout |
| Fire-and-forget race | Concurrency | Set state guards synchronously, before async gaps |
| Isolate zombie | Resource ownership | OS resources need explicit kill, not just polite requests |
| VAD native memory leak | Resource ownership | FFI memory is invisible to the GC — you must free it |
| Unbounded audio buffer | Data structure safety | Every accumulating structure needs a cap |
| Direct `sl<>` in UI | Layer violation | UI talks to BLoC only. Data flows up through state |
| Datasource depends on Repository | Layer violation | Dependency arrows only point inward (to domain), never outward |
| Singleton/factory mismatch | Lifecycle | An object's registration type is a lifetime decision |
| Missing model file validation | Defensive I/O | Existence ≠ validity. Check size too |
| Missing stream `onError` | Error handling | `Either` catches business errors. `onError` catches infrastructure failures |
| Wrong `AppFailure` variant | Type semantics | Type names are contracts. Misuse corrupts downstream logic |
| VAD simultaneous events | Stream contract | Design streams around what consumers need to know, not what's convenient to emit |

---

*These are not exotic bugs. They appear in almost every system that handles audio, native code, or concurrent state. The engineers who catch them early are not smarter — they've just been burned by them before and built the habit of asking adversarial questions about their own code.*
