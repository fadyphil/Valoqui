# Valoqui — Development Setup Guide

Everything required to go from a fresh machine to a running Valoqui build.
Follow every step in order. Do not skip sections.

---

## Prerequisites

| Tool | Required version | Notes |
| ------ | ----------------- | ------- |
| Flutter SDK | 3.22.0+ (stable channel) | `flutter channel stable && flutter upgrade` |
| Dart SDK | Bundled with Flutter | Do not install separately |
| Android Studio | Hedgehog 2023.1.1+ | Required for Gradle and device tools |
| Java JDK | JDK 17 | JDK 21 also works; JDK 11 does NOT |
| Android SDK | API 34 (target) | Also install API 29, 31 for device matrix |
| Git | Any recent | — |
| Physical Android device | API 29+ (Android 10+) | Emulator has mic limitations — use real hardware for voice testing |

Verify your Flutter installation before anything else:

```bash
flutter doctor -v
```

All items must show green checkmarks. Resolve any red X before proceeding.

---

## 1. Clone the repository

```bash
git clone https://github.com/your-username/valoqui.git
cd valoqui
```

---

## 2. Firebase setup

This project uses Firebase Auth and Firestore. You need your own Firebase
project for local development.

### 2.1 Create a Firebase project

1. Go to <https://console.firebase.google.com>
2. Create project — name it `valoqui-dev` (keep prod and dev separate)
3. Disable Google Analytics

### 2.2 Register the Android app

- Package name: `com.valoqui.app`
- Get your debug SHA-1:

```bash
# macOS / Linux
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android

# Windows
keytool -list -v ^
  -keystore %USERPROFILE%\.android\debug.keystore ^
  -alias androiddebugkey ^
  -storepass android -keypass android
```

- Download `google-services.json` and place it at:
  `android/app/google-services.json`

> ⚠️ `google-services.json` is gitignored. You must provide your own.

### 2.3 Enable Authentication

Firebase Console → Authentication → Sign-in method → Enable **Google**.
Set a project support email.

### 2.4 Create Firestore database

Firebase Console → Firestore Database → Create database → **Production mode**
→ Region: `nam5 (us-central)`.

Apply these security rules (Rules tab):

```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
      match /sessions/{sessionId} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;
      }
    }
  }
}
```

### 2.5 Generate firebase_options.dart

```bash
# Install FlutterFire CLI (once)
dart pub global activate flutterfire_cli

# From project root
flutterfire configure
# Select your valoqui-dev project when prompted
# This generates lib/firebase_options.dart
```

> ⚠️ `firebase_options.dart` is gitignored. You must generate it.

---

## 3. Install Flutter dependencies

```bash
flutter pub get
```

---

## 4. Run code generation

Freezed models and JSON serialisation require build_runner:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run this again after any change to a `@freezed` class or `@JsonSerializable`
class. If you see stale generated files causing errors, this is always the fix.

---

## 5. Download font assets

Three fonts are required. Download from Google Fonts and place in the exact
paths shown.

```Markdown
assets/fonts/
  Fraunces/
    Fraunces-Regular.ttf
    Fraunces-SemiBold.ttf
    Fraunces-Bold.ttf
  DMSans/
    DMSans-Regular.ttf
    DMSans-Medium.ttf
    DMSans-SemiBold.ttf
    DMSans-Bold.ttf
  JetBrainsMono/
    JetBrainsMono-Regular.ttf
```

Download links:

- Fraunces: <https://fonts.google.com/specimen/Fraunces>
- DM Sans: <https://fonts.google.com/specimen/DM+Sans>
- JetBrains Mono: <https://fonts.google.com/specimen/JetBrains+Mono>

---

## 6. Download TTS model files

The Piper TTS model (Sprint 2 interim) is not in the repository due to size
(76.7 MB). Download from HuggingFace:

**Source:** <https://huggingface.co/csukuangfj/vits-piper-es_ES-sharvard-medium/tree/main>

Download and place at:

```Markdown
assets/tts/vits-piper-es_ES-sharvard-medium/
  es_ES-sharvard-medium.onnx         (76.7 MB)
  es_ES-sharvard-medium.onnx.json    (4.9 kB)
  espeak-ng-data/                    (folder — download all files inside)
```

Verify the model is a real binary (not an HTML download error page):

```bash
file assets/tts/vits-piper-es_ES-sharvard-medium/es_ES-sharvard-medium.onnx
# Expected: data  (NOT: HTML document)
```

> ⚠️ If you see `HTML document`, the download failed. Use the HuggingFace
> download button in the browser — do not right-click Save As on the file page.

---

## 7. API keys (runtime, not build-time)

Valoqui uses BYOK — no API keys are stored in the repository or in build
configuration. Keys are entered by the user at onboarding and stored in the
Android Keystore via `flutter_secure_storage`.

For development, run the app on a physical device, complete the onboarding
flow, and enter your own keys:

- **Groq API key**: <https://console.groq.com> — free account, starts with `gsk_`
- **Gemini API key** (optional): <https://aistudio.google.com> — free account

> Keys entered during development are stored in the device's secure storage.
> They persist across hot restarts but are cleared when you uninstall the app
> or call `SecureStorageService.clearAllKeys()`.

---

## 8. Run the app

Connect a physical Android device with USB debugging enabled.

```bash
flutter run
```

For verbose output (useful for debugging Firebase issues):

```bash
flutter run -v
```

---

## 9. Build a release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Sensitive files — what is gitignored

These files must never be committed to a public repository. Each must be
provided by the developer locally.

| File | Why excluded | How to get it |
| ------ | ------------- | --------------- |
| `android/app/google-services.json` | Firebase project credentials | Firebase Console → Project Settings → Download |
| `lib/firebase_options.dart` | Generated from google-services.json | Run `flutterfire configure` |
| `android/local.properties` | Local SDK paths | Generated automatically by Android Studio |
| `assets/tts/**/*.onnx` | Large binary model files | HuggingFace (see Section 6) |
| `assets/fonts/**/*.ttf` | Font files | Google Fonts (see Section 5) |

---

## Common errors and fixes

| Error | Fix |
| ------- | ----- |
| `google-services.json not found` | Place file at `android/app/google-services.json` (see Section 2.2) |
| `firebase_options.dart not found` | Run `flutterfire configure` (see Section 2.5) |
| Fonts render as system default | Check `pubspec.yaml` font paths exactly. YAML is whitespace-sensitive. |
| `*.freezed.dart` missing or stale | Run `dart run build_runner build --delete-conflicting-outputs` |
| Google sign-in fails (PlatformException) | SHA-1 fingerprint not added to Firebase Console (see Section 2.2) |
| TTS crashes with file not found | Model file partially written — delete app data, reinstall, re-run |
| STT returns empty string | Do not set `localeId` in `listen()` — auto-detection required |
| LLM stream hangs | `receiveTimeout` in `DioClient` must be ≥ 60 seconds |
| Firestore permission denied | Security rules not saved, or not yet propagated (wait 60 seconds) |
| `build_runner` conflicts | Always use `--delete-conflicting-outputs` flag |

---

## Architecture quick reference

```Markdown
lib/
  core/
    di/           → GetIt service locator (all singletons and factories)
    domain/       → Interfaces and models — no Flutter dependencies
    data/         → Concrete implementations of domain interfaces
    network/      → Dio client and interceptors
    theme/        → Design system (colors, typography, spacing)
    router/       → GoRouter configuration
  features/
    auth/         → Google sign-in BLoC
    onboarding/   → BYOK setup BLoC
    home/         → Home screen BLoC
    speaking/     → Voice conversation BLoC (the core pipeline)
    report/       → Post-session report card BLoC
```

Voice pipeline swap points (see ADR-005):

- STT: change one line in `service_locator.dart`
- TTS: change one line in `service_locator.dart`
- LLM: fallback handled internally in `GroqLlmRepository`

---

## Architectural decisions

All significant technical decisions are documented in `docs/decisions/`.
Read these before making changes to the voice pipeline or switching providers.

```Markdown
docs/decisions/
<!-- PULSE:ADR_LIST -->
  ADR-001  STT Provider — Android SpeechRecognizer via speech_to_text
  ADR-002  LLM Provider — Groq LLaMA 3.3 70B with Gemini 2.0 Flash Fallback
  ADR-003  TTS Engine — On-Device sherpa-onnx Piper (Interim) → F5-TTS ONNX (Target)
  ADR-004  State Management — BLoC + Freezed + GetIt + fpdart
  ADR-005  Clean Architecture Swap Pattern — Domain Interfaces for All Voice Components
  ADR-006  API Key Storage — Android Keystore via flutter_secure_storage
  ADR-007  Conversation History — Rolling 8-Turn Window
  ADR-008  Sentence-Boundary TTS Trigger
  ADR-009  Post-Session Report Generation — Single LLM Call, Structured JSON
  ADR-010  Unified Audio Pipeline — Deprecate speech_to_text, Single Raw PCM Stream
  ADR-011  STT Performance Optimization Strategy
  ADR-012  Supertonic TTS Integration Strategy
  ADR-013  TTS Warm-Up Optimization
  ADR-014  UI Rebuild Optimization (Token Batching)
  ADR-015  Isolate Backpressure & Buffer Safety
  ADR-016  TTS Background Isolate and Pipelining
  ADR-017  Hardware-Accelerated Audio Pipeline and Dynamic STT Throttling
  ADR-018  Strict Turn-Taking and Audio Pipeline Resilience
<!-- /PULSE:ADR_LIST -->
```

---

## Sprint status

| Sprint | Scope | Status |
| -------- | ------- | -------- |
| Sprint 1 | Firebase, auth, BYOK onboarding, design system, navigation | ✅ Complete |
| Sprint 2 | Voice pipeline, conversation loop, report card, XP | ✅ Complete |
| Sprint 3 | Unified audio pipeline (ARCH-101), F5-TTS ONNX, polish | ✅ Complete |
