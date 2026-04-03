# Valoqui (Lingua) - Real-Time AI Spanish Tutor

Valoqui is a high-performance, real-time AI conversation partner designed for immersive language learning. This MVP focuses on **ultra-low latency** voice interactions, utilizing an offline-first audio pipeline to provide a seamless, human-like speaking experience.

---

## 🚀 Key Technical Achievements

### 1. Ultra-Low Latency Audio Pipeline (On-Device)
To eliminate cloud round-trip latency, Valoqui leverages on-device machine learning models:
*   **VAD (Voice Activity Detection):** Uses **Silero VAD** for accurate segment-based speech detection. It emits full Float32 audio segments only after silence is confirmed, ensuring zero-loss transcription.
*   **STT (Speech-to-Text):** Implements **Sherpa-ONNX (Moonshine model)**. To prevent UI jank and maintain 60FPS, STT decoding is entirely offloaded to a **background Dart Isolate**.
*   **TTS (Text-to-Speech):** Utilizes **VITS/Piper** with a natural Spanish voice (Lucia). Optimized for streaming and robust playback using a rotating file-cache strategy to prevent stale audio.

### 2. High-Performance LLM Orchestration
*   **Streaming LLM:** Integrates **Groq (LLaMA 3.3 70B)** for near-instantaneous response generation.
*   **Resilient Fallback:** Automatically switches to **Google Gemini 2.5 Flash** if the primary provider fails, ensuring conversation continuity.
*   **Sentence-Boundary TTS:** Intelligently triggers TTS playback on sentence boundaries during LLM streaming for a more natural cadence.

### 3. Secure Architecture (BYOK)
*   **Security First:** Implements a "Bring Your Own Key" (BYOK) model. API keys are stored securely using **Android Keystore / iOS Keychain** via `flutter_secure_storage`.
*   **Clean Network Layer:** Custom **Dio interceptors** dynamically inject secure keys into request headers, isolating security logic from business features.

---

## 🛠 Tech Stack

*   **Framework:** Flutter (Dart)
*   **Architecture:** Feature-First Modular Clean Architecture (Domain-Driven Design principles)
*   **State Management:** `flutter_bloc` + `freezed` (Unidirectional Data Flow)
*   **Dependency Injection:** `get_it` (Service Locator)
*   **Functional Programming:** `fpdart` (using `Either` for robust error handling)
*   **Networking:** `dio`
*   **Navigation:** `go_router`
*   **Backend:** Firebase (Authentication & Firestore)
*   **Models:** ONNX (via `sherpa_onnx`)

---

## 📂 Architecture Overview

The project follows a strict three-layer separation within each feature:
*   **Domain:** Pure Dart business logic, entities, and repository interfaces.
*   **Data:** API implementations, DTOs, mappers, and data sources (STT/TTS engines).
*   **Presentation:** UI Widgets and BLoCs for state orchestration.

---

## 🚧 MVP Status & Known Issues

This is a **Phase 1 MVP**. While functionally complete for conversation, the following areas are actively being refined:
*   **VAD/PTT Timing:** Currently tuning the silence threshold in Silero VAD to perfectly balance response speed and natural pauses.
*   **STT Sensitivity:** Exploring further optimizations for the Moonshine model to handle extreme background noise or very low-volume speech.
*   **UI Polish:** Transitional animations and accessibility features are in early development.

---

## 🔧 Getting Started

### Prerequisites
*   Flutter SDK (>=3.3.0)
*   Android/iOS development environment

### Installation
1.  Clone the repository.
2.  Run `flutter pub get`.
3.  Execute `dart run build_runner build --delete-conflicting-outputs` to generate Freezed/JSON models.
4.  Configure Firebase for your local environment.
5.  Launch via `flutter run`.

---

## 👨‍💻 Developer Note
Valoqui was built with a focus on **Software Craftsmanship**. Every design decision—from the use of background isolates for audio processing to the functional error-handling patterns—was made to ensure the system is scalable, testable, and highly performant.
