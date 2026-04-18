# Valoqui - Product Requirements Document (PRD)

*Note: As Valoqui is an open-source personal project designed to showcase product and engineering skills, this document serves to outline the product vision, scope, and requirements. It provides a window into the product management side of the development lifecycle.*

---

## 1. Product Vision

**Valoqui (Lingua)** is a mobile app designed to provide immersive, real-time Spanish language practice. By leveraging ultra-fast AI models and on-device processing, it aims to eliminate the unnatural "wait times" that plague traditional AI tutors, creating a seamless, human-like conversation partner.

## 2. Target Audience

- Language learners looking to practice speaking without the anxiety of a real human tutor.
- Heritage speakers wanting to practice "code-switching" (mixing languages).
- Users who value privacy and prefer a "Bring Your Own Key" (BYOK) model to avoid subscription fees.

## 3. Core Features (MVP / Phase 1)

### 3.1 The Voice Pipeline

- **Continuous Conversation:** Users can speak naturally. The app detects when they stop speaking using Voice Activity Detection (VAD).
- **Ultra-Low Latency:** The system aims for <600ms latency from the moment the user stops speaking to the moment the AI starts replying.
- **Push-to-Talk Fallback:** A reliable fallback for noisy environments or unsupported hardware.

### 3.2 Bring Your Own Key (BYOK)

- Users input their own API keys (Groq for primary inference, Gemini for fallback).
- Keys are stored securely on the device (Android Keystore / iOS Keychain) and are never transmitted to a central backend.

### 3.3 Session Reports & DELE Grading

- After ending a session, the entire transcript is evaluated.
- The AI provides a report card grading grammar, vocabulary, and fluency based on the CEFR/DELE standards.
- Experience Points (XP) are calculated based on active speaking time and performance.

### 3.4 Firebase Integration

- Secure Google Sign-In.
- Cloud Firestore to store user profiles, CEFR levels, and session history metadata (excluding sensitive API keys).

## 4. Technical Constraints

- **Framework:** Flutter for cross-platform capability.
- **STT/TTS:** Must prioritize on-device (offline) execution to minimize latency and API costs.
- **LLM:** Must use a fast, streaming-capable endpoint (Groq LLaMA 3.3).

## 5. Success Metrics

- **Performance:** End-to-end response latency under 600ms (P95).
- **Stability:** Zero UI jank (maintaining 60FPS) during audio processing.
- **Engagement:** Users complete at least one 5-minute conversation session successfully.

---
*For technical implementation details of these requirements, refer to the [Architectural Decision Records (ADRs)](../decisions/README.md).*

> - **NOTE** : here is the heavy , full, professional [PRD](lingua-prd-v0.3.md)

---
