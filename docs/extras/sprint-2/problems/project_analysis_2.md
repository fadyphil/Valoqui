# Project Analysis - Valoqui

## Executive Summary

This analysis builds upon the previous pipeline analysis (`ignore/reports/sprint-2/problems/pipeline_analysis.md`) which identified and (mostly) fixed critical issues in the STT/VAD/TTS/LLM audio pipeline. This document provides:

1. **Status of previously identified issues** — what's been fixed and what's still pending
2. **New issues discovered** through deeper code analysis
3. **Optimization opportunities** for performance, memory, and reliability
4. **Testing strategies** with specific file recommendations and behavior-focused testing patterns

---

## Part 1: Status of Previously Identified Issues

### Critical Issues (All Fixed)

| # | Issue | Status | Evidence |
| --- | ------- | -------- | ---------- |
| 1 | Isolate decode has no timeout | ✅ **FIXED** | `sherpa_stt_datasource.dart:195-218` — `reply.first.timeout(Duration(seconds: 10))` implemented |
| 2 | Isolate never explicitly killed | ✅ **FIXED** | `sherpa_stt_datasource.dart:106` — `_isolate` reference captured, `dispose()` calls `kill()` at line 239 |
| 3 | VAD native memory never freed | ✅ **FIXED** | `sherpa_vad_datasource.dart:277` — `_vad?.free()` called in dispose |
| 4 | Unbounded audio buffer in PTT | ✅ **FIXED** | `sherpa_stt_datasource.dart:325` — `_maxBufferBytes` cap (60 seconds) |

### High Severity (All Fixed)

| # | Issue | Status | Evidence |
| --- | ------- | -------- | ---------- |
| 5 | Direct service locator in UI | ✅ **FIXED** | `speaking_screen.dart:249` — amplitude now via state: `amplitudeStream: state.amplitude` |
| 6 | _drainQueue() race condition | ✅ **FIXED** | `sherpa_tts_datasource.dart:175` — `_isDrainingQueue = true` set synchronously before fire-and-forget |
| 7 | LLM stream missing error handler | ✅ **FIXED** | `speaking_bloc.dart:457-464` — `onError` handler added |

### Medium Severity (All Fixed)

| # | Issue | Status | Evidence |
| --- | ------- | -------- | ---------- |
| 8 | VAD emits true→false back-to-back | ✅ **FIXED** | `sherpa_vad_datasource.dart:212-214` — now only emits `false` (completion) |
| 9 | _deliverPrecannedGreeting sync dispatch | ✅ **FIXED** | `speaking_bloc.dart:820-821` — still uses direct `add()` but docs explain why (synchronous emit guarantee) |
| 10 | STT/VAD uses networkFailure for local errors | ✅ **FIXED** | `sherpa_stt_datasource.dart:397` and `sherpa_vad_datasource.dart:239` — now use `sttFailure` |
| 11 | Model files can be deleted — no re-validation | ⚠️ **PARTIAL** | Code has comments about this (`sherpa_stt_datasource.dart:636-638`) but size check NOT implemented |

### Low Severity / Code Quality

| # | Issue | Status |
| --- | ------- | -------- |
| 12 | Duplicate comment in STT | ✅ Fixed |
| 13 | Dead code in VAD | ✅ Fixed |
| 14 | Commented-out Android STT code | ⚠️ Still exists (see below) |
| 15 | SttRepository interface mismatch | ✅ Documented as intentional (returns "" — transcript via stream) |

---

## Part 2: New Issues Discovered

### Critical — Not Yet Fixed

#### 2.1 Stale LLM Subscription on Retries

**File:** `lib/features/speaking/bloc/speaking_bloc.dart:442-465`

```dart
void _streamLlmResponse() {
  _llm.streamResponse(...).listen(
    (event) => ...,
    onDone: () => add(const _LlmResponseComplete()),
    onError: (error, stack) { ... },
  );
}
```

**Problem:** The returned `StreamSubscription` is **never stored**. On retry (if user re-tries after error), the previous subscription may still be active, causing duplicate events.

**Fix:**

```dart
StreamSubscription<Either<AppFailure, String>>? _llmSub;

void _streamLlmResponse() {
  await _llmSub?.cancel(); // Cancel any existing stream
  _llmSub = _llm.streamResponse(...).listen(...);
}
```

---

#### 2.2 Firebase Auth Race Condition on Init

**File:** `lib/core/data/datasources/firebase_auth_datasource.dart`

**Problem:** `FirebaseAuth.instance.currentUser` accessed immediately after `Firebase.initializeApp()` may return `null` even when user is signed in (due to auth state restoration timing).

**Fix:**

```dart
Future<Either<AppFailure, User?>> getCurrentUser() async {
  // Wait for auth state restoration
  await FirebaseAuth.instance.authStateChanges().first;
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return left(const AppFailure.unauthenticated());
  }
  return right(User(...));
}
```

---

#### 2.3 No Cancellation of VAD Monitoring on Quick Mode Toggle

**File:** `lib/features/speaking/bloc/speaking_bloc.dart:751-768`

```dart
Future<void> _onMicModeToggled(...) async {
  if (newMode == MicMode.alwaysOn) {
    await _vad.startMonitoring();
  } else {
    await _vad.stopMonitoring();
  }
}
```

**Problem:** If user rapidly toggles (e.g., 3 times in 1 second), multiple `startMonitoring()` calls stack. Each creates a new audio subscription without canceling the previous one.

**Fix:** Add a debounce guard:

```dart
DateTime? _lastModeToggle;

Future<void> _onMicModeToggled(...) async {
  final now = DateTime.now();
  if (_lastModeToggle != null && now.difference(_lastModeToggle!).inMilliseconds < 500) {
    return; // Debounce rapid toggles
  }
  _lastModeToggle = now;
  // ... rest of logic
}
```

---

### High Severity

#### 2.4 Hardcoded API Keys / Model Names in Datasources

**File:** `lib/core/data/datasources/groq_llm_datasource.dart:36`

```dart
"model": "llama-3.3-70b-versatile",
```

**Problem:**

- Model name hardcoded — changing requires code edit
- No way to configure via settings UI
- If model deprecated, app breaks

**Recommendation:** Move to configuration or environment-based loading.

---

#### 2.5 DioClient Interceptor Missing Retry Logic

**File:** `lib/core/network/dio_client.dart`

**Problem:** Network failures (timeout, 503) don't retry — immediately fail to user.

**Recommendation:** Add retry interceptor:

```dart
 interceptors.add(InterceptorsWrapper(
  onError: (error, handler) {
    if (_shouldRetry(error)) {
      return _retry(error, handler);
    }
    return handler.next(error);
  },
));
```

---

#### 2.6 Report Generation Has No Timeout

**File:** `lib/core/data/repositories/groq_llm_repository.dart:87-104`

```dart
Future<Either<AppFailure, String>> generateReport({...}) async {
  // ...
  final groqResult = await _groq.generateReport(prompt: prompt);
```

**Problem:** If LLM takes >60s to respond, the entire app hangs.

**Fix:**

```dart
final groqResult = await _groq.generateReport(prompt: prompt)
    .timeout(const Duration(seconds: 30));
```

---

### Medium Severity

#### 2.8 Unused `AndroidSttDatasource` and `AndroidSttRepository` Files

**Files:**

- `lib/core/data/datasources/android_stt_datasource.dart`
- `lib/core/data/repositories/android_stt_repository.dart`

**Problem:** Dead code clutters the codebase. Comments in `service_locator.dart` reference them but are commented out.

**Fix:** Delete both files.

---

#### 2.9 `FirebaseUserRepository` May Leak Firebase Stream

**File:** `lib/core/data/repositories/firebase_user_repository.dart`

**Problem:** If `watchUserProfile()` is called multiple times (e.g., navigation back and forth), multiple Firestore listeners stack.

**Fix:** Track subscription and cancel on dispose.

---

#### 2.10 No Idle Timeout for Speaking Session

**File:** `lib/features/speaking/bloc/speaking_bloc.dart:98`

```dart
Duration _elapsed = Duration.zero;
Timer? _sessionTimer;
```

**Problem:** If user leaves app open but idle, session runs forever. No auto-end after X minutes of silence.

**Fix:** Add idle detection:

```dart
void _onTimerTick(...) {
  _elapsed += const Duration(seconds: 1);
  // If no user utterance for 5 minutes, end session
  if (_elapsed.inMinutes - _lastUtteranceTime.inMinutes > 5) {
    add(const SessionEnded());
  }
}
```

---

#### 2.11 Audio Recording Continues During App Backgrounding

**File:** `lib/core/data/datasources/sherpa_vad_datasource.dart:155-241`

**Problem:** If user backgrounds the app (e.g., switches to another app), mic stays open — drains battery and may record unintended audio.

**Fix:** Use `WidgetsBindingObserver`:

```dart
class SherpaVadDatasource with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      stopMonitoring();
    } else if (state == AppLifecycleState.resumed) {
      // Optionally auto-restart
    }
  }
}
```

---

### Low Severity/Code Quality

#### 2.12 Inconsistent Error Logging

- Some places use `debugPrint`, others use nothing
- No centralized logging strategy

**Recommendation:** Consider using `log` package or Firebase Crashlytics for production.

---

#### 2.13 Magic Numbers Throughout

**Examples:**

- `sherpa_vad_datasource.dart:119` — `minSilenceDuration: 0.8`
- `groq_llm_datasource.dart:42` — `maxTokens: 120`
- `sherpa_stt_datasource.dart:325` — `_maxBufferBytes = 16000 * 2 * 60`

**Recommendation:** Extract to constants class:

```dart
class AudioConfig {
  static const int sampleRate = 16000;
  static const int maxRecordingSeconds = 60;
  static const double vadMinSilenceDuration = 0.8;
}
```

---

#### 2.14 Report Prompt Built Inline

**File:** `lib/core/data/repositories/groq_llm_repository.dart:113-164`

The report generation prompt is 50+ lines of hardcoded text in the method.

**Recommendation:** Move to separate file or constants class for maintainability.

---

#### 2.15 No Unit Tests for Datasources

**Current test coverage:** Only BLoC tests exist (`test/features/*/`). Datasources have zero unit tests.

**Impact:** Critical audio pipeline logic (VAD, STT, TTS) has no automated verification.

---

## Part 3: Optimization Opportunities

### Performance

#### 3.1 Lazy-Load STT Models on First Use

**Current:** Models loaded in `initialize()` at session start.

**Optimization:** Load in background while user sees loading screen, or on first utterance detection.

---

#### 3.2 Cache LLM Response Parsing

**File:** `groq_llm_datasource.dart:71-89`

JSON parsed character-by-character. For large responses, could buffer and parse once per line instead of per character.

---

#### 3.3 Use `const` Constructors Where Possible

**Example:** `speaking_bloc.dart:272-280`

```dart
emit(
  SpeakingState.active(
    transcript: const [],  // Already const
    // ...
  ),
);
```

This is already optimized in some places — good job!

---

### Memory

#### 3.4 Limit Transcript History More Aggressively

**File:** `speaking_bloc.dart:83`

```dart
final List<ConversationMessage> _history = [];
```

Currently capped at 8 messages. Consider:

- Cap at 5 for memory-constrained devices
- Implement token counting and truncate before exceeding LLM context window

---

#### 3.5 Clear TTS Wave Files After Session

**File:** `sherpa_tts_datasource.dart:233`

```dart
final wavPath = "${tmpDir.path}/lucia_speech_${_wavIndex % 2}.wav";
```

Files written to temp directory but never cleaned up.

**Fix:** In `dispose()`:

```dart
for (var i = 0; i < 2; i++) {
  final file = File("${tmpDir.path}/lucia_speech_$i.wav");
  if (await file.exists()) await file.delete();
}
```

---

### Battery

#### 3.6 Reduce VAD Processing Frequency on Low Battery

**File:** `sherpa_vad_datasource.dart:187`

```dart
_vad!.acceptWaveform(_convertPcm16ToFloat32(chunk));
```

Runs on every audio chunk. On low battery, could skip every other chunk.

---

### Reliability

#### 3.7 Implement Circuit Breaker for LLM Calls

If LLM fails X times in Y minutes, stop attempting and show user-friendly error instead of retrying infinitely.

---

#### 3.8 Add Health Check Endpoint

Before starting session, ping LLM with minimal request to verify API keys work.

---

## Part 4: Testing Strategy

### Testing Philosophy

**Behavior-Focused Testing** — Tests should verify *what the code does*, not *how it's implemented*. Focus on inputs, outputs, and side effects.

---

### Test File Priority Matrix

| Priority | Files to Test | Why |
| ---------- | --------------- | ----- |
| **P0** | `speaking_bloc.dart` | Core session logic — if this breaks, nothing works |
| **P0** | `sherpa_stt_datasource.dart` | Audio pipeline — critical for user experience |
| **P0** | `sherpa_tts_datasource.dart` | Audio output — critical for user experience |
| **P1** | `sherpa_vad_datasource.dart` | Voice detection — affects STT quality |
| **P1** | `groq_llm_repository.dart` | LLM fallback logic — complex error handling |
| **P2** | `groq_llm_datasource.dart` | API parsing — well-structured, easier to test |
| **P2** | `gemini_llm_datasource.dart` | Same as above |
| **P3** | `service_locator.dart` | Integration test only — verify registrations |
| **P3** | `firebase_auth_datasource.dart` | Firebase-specific — can only mock |

---

### Recommended Test Structure

```Markdown
test/
├── core/
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── sherpa_stt_datasource_test.dart
│   │   │   ├── sherpa_vad_datasource_test.dart
│   │   │   └── sherpa_tts_datasource_test.dart
│   │   └── repositories/
│   │       └── groq_llm_repository_test.dart
│   └── domain/
│       └── usecases/
│           └── report/
│               └── generate_report_test.dart
├── features/
│   ├── speaking/
│   │   ├── speaking_bloc_test.dart        # Already exists
│   │   └── speaking_screen_test.dart
│   └── report/
│       └── report_bloc_test.dart          # Already exists
└── mocks/
    ├── mock_sherpa_stt.dart
    ├── mock_sherpa_vad.dart
    └── mock_sherpa_tts.dart
```

---

### Behavior-Focused Test Examples

#### Example 1: STT Buffer Capping

**Bad (implementation-focused):**

```dart
test("audioBuffer length is less than maxBufferBytes", () {
  expect(_datasource._audioBuffer.length, lessThan(SherpaSttDatasource._maxBufferBytes));
});
```

**Good (behavior-focused):**

```dart
test("long recording only keeps last 60 seconds of audio", () async {
  // Given: User holds PTT for 90 seconds
  final ninetySecondsOfAudio = generateAudio(duration: Duration(seconds: 90));
  
  // When: User releases PTT
  await stt.stopListening();
  
  // Then: Only ~60 seconds are decoded (last 60)
  verify(mockIsolate.decode(captureThat(hasLengthInRange(950000, 1050000)))).called(1);
});
```

---

#### Example 2: LLM Fallback Trigger

**Bad (implementation-focused):**

```dart
test("fallback is triggered when rate limit received", () {
  when(() => mockGroq.streamResponse(...)).thenAnswer((_) => Stream.fromIterable([
    left(AppFailure.rateLimitFailure()),
  ]));
  // Check internal flag
  expect(repository._hitRateLimit, isTrue);
});
```

**Good (behavior-focused):**

```dart
test("when Groq rate-limits, Gemini is used for response", () async {
  // Given: Groq returns rate limit error
  when(() => mockGroq.streamResponse(...)).thenAnswer((_) => Stream.fromIterable([
    left(AppFailure.rateLimitFailure()),
  ]));
  when(() => mockGemini.streamResponse(...)).thenAnswer((_) => Stream.fromIterable([
    right("Hola from Gemini"),
  ]));
  
  // When: Client requests response
  final tokens = await repository.streamResponse(messages: []).toList();
  
  // Then: Response comes from Gemini
  expect(tokens, contains(right("Hola from Gemini")));
  verify(() => mockGemini.streamResponse(...)).called(1);
});
```

---

#### Example 3: TTS Queue Behavior

**Bad (implementation-focused):**

```dart
test("isDrainingQueue is set before drainQueue called", () {
  expect(tts._isDrainingQueue, isTrue);
});
```

**Good (behavior-focused):**

```dart
test("consecutive speak calls play sentences in order", () async {
  // Given: Queue is empty and idle
  // When: Three sentences are spoken rapidly
  await tts.speak("Hola");
  await tts.speak("Como");
  await tts.speak("estas?");
  
  // Then: All three play sequentially (not in parallel)
  verify(() => player.setFilePath("lucia_speech_0.wav")).called(1); // "Hola"
  verify(() => player.setFilePath("lucia_speech_1.wav")).called(1); // "Como"
  // (verify order via inOrder verification)
});
```

---

### Test Utilities to Add

#### Mock Sherpa Native Objects

Since Sherpa-ONNX is native code, cannot mock directly. Create wrapper interfaces:

```dart
// In mock_services.dart
class MockSherpaRecognizer extends Mock {
  final List<Float32List> decodeCalls = [];
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #decode) {
      decodeCalls.add(invocation.positionalArguments[0]);
      return MockSherpaResult(text: "mocked");
    }
  }
}
```

---

#### Fake Audio Data Generator

```dart
class FakeAudioGenerator {
  static Float32List generateTone({
    double frequency = 440.0,
    double durationSeconds = 1.0,
    double sampleRate = 16000.0,
  }) {
    final samples = (durationSeconds * sampleRate).toInt();
    final buffer = Float32List(samples);
    for (var i = 0; i < samples; i++) {
      buffer[i] = sin(2 * pi * frequency * i / sampleRate);
    }
    return buffer;
  }
  
  static Float32List generateSilence({
    double durationSeconds = 1.0,
    double sampleRate = 16000.0,
  }) {
    return Float32List((durationSeconds * sampleRate).toInt());
  }
}
```

---

#### Fixed Time Provider

For testing timer-dependent logic:

```dart
class FixedTimeProvider implements DateTimeUtils {
  DateTime _now = DateTime(2024, 1, 1);
  
  @override
  DateTime now() => _now;
  
  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}
```

---

### Test Coverage Goals

| Module | Current | Target | Priority |
| -------- | --------- | -------- | ---------- |
| SpeakingBloc | ~60% | 90% | P0 |
| All BLoCs | ~50% | 80% | P1 |
| Repositories | 20% | 70% | P1 |
| Datasources | 0% | 50% | P2 |

---

### Tests to Avoid

1. **Widget tests for complex state** — `speaking_screen.dart` has high complexity due to audio streams. Focus on unit tests instead.
2. **Snapshot tests for BLoC states** — They break on any unrelated change. Use explicit equality assertions.
3. **Integration tests requiring real audio** — Use fake audio data generators instead.

---

## Summary Checklist

### For Next Sprint

- [ ] Fix stale LLM subscription (2.1)
- [ ] Add debounce to mode toggle (2.3)
- [ ] Add retry interceptor to DioClient (2.5)
- [ ] Add timeout to generateReport (2.6)
- [ ] Delete unused Android STT files (2.8)
- [ ] Add idle timeout to session (2.10)
- [ ] Clear TTS temp files on dispose (3.5)

### For Future Sprints

- [ ] Move hardcoded configs to constants class
- [ ] Add unit tests for datasources (P0 priority)
- [ ] Implement circuit breaker for LLM
- [ ] Add battery-aware VAD throttling
- [ ] Implement app lifecycle handling for audio
- [ ] Add health check before session start

### Nice to Have

- [ ] Centralize logging strategy
- [ ] Extract report prompt to external file
- [ ] Add more aggressive transcript truncation for low-memory devices

---

*Analysis generated: 2026-04-09*
*Based on: pipeline_analysis.md + codebase exploration*
