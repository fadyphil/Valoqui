# ADR-006: API Key Storage — Android Keystore via flutter_secure_storage

**Date:** 2026-03
**Status:** Accepted
**Sprint:** Sprint 1
**Decider:** Fady

---

## Context

Valoqui's BYOK model requires storing user-supplied API keys (Groq, Gemini)
on-device between sessions. These are sensitive credentials: a leaked Groq key
allows arbitrary API usage billed to the user's account. Storage mechanism
must be resistant to extraction on rooted devices and must survive app restarts.

A hard constraint: keys must never leave the device to any Valoqui-controlled
server. Storing even a flag like `groqKeyValue` in Firestore is prohibited.
Only a boolean `groqKeyConfigured: true` is stored server-side.

---

## Decision

API keys are stored exclusively via `flutter_secure_storage` with
`AndroidOptions(encryptedSharedPreferences: true)`, which uses the Android
Keystore system. The `SecureStorageService` class is the single point of
access — nothing outside this service calls `flutter_secure_storage` directly.

---

## Alternatives considered

### Option A — SharedPreferences

**Why considered:** Simple API, zero setup.
**Why rejected:** Plain text storage. Any app with filesystem access on a
rooted device can read SharedPreferences values. Unacceptable for API keys.

### Option B — Hive / SQLite

**Why considered:** Structured local storage.
**Why rejected:** No OS-level encryption. Same attack surface as
SharedPreferences for key extraction.

### Option C — Android Keystore via flutter_secure_storage (chosen)

**Why selected:** Same encrypted storage system used by banking apps. Keys
are encrypted at the OS level and cannot be extracted without the device's
lock screen credentials. Keystore-backed keys survive app reinstall.

---

## Consequences

### Positive

- Keys are protected at the Android OS level — not application-level
  encryption that a sophisticated attacker could reverse.

### Negative / tradeoffs

- `flutter_secure_storage` requires `minSdkVersion 21` in `build.gradle`.
- First read after device reboot may require user authentication depending
  on Keystore configuration. Not an issue with `encryptedSharedPreferences`.

### Constraints introduced

- Keys are NEVER logged, NEVER sent to Firebase, NEVER transmitted anywhere
  except directly to Groq and Gemini endpoints.
- On sign-out: user is offered the option to clear stored keys via
  `SecureStorageService.clearAllKeys()`.
- The `SecureStorageService` is a singleton in GetIt — all key reads and
  writes go through a single instance.

---

## Links

- PRD v0.3 § ADL-008 (API key storage)
- Sprint 1 Guide v2.0 § core/services/secure_storage_service.dart
- Sprint 2 Guide § 6.2 (ApiKeyInterceptor — attaches key per request)
