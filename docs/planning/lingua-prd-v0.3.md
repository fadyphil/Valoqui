# Lingua — Product Requirements Document (PRD)

**Version:** 0.3 — Architecture Finalized  
**Status:** Locked for MVP Build  
**Last Updated:** March 2026  
**Platform:** Flutter — Android (Phase 1)  
**Target Language (Phase 1):** Spanish  
**Curriculum Authority:** Instituto Cervantes — DELE Framework (A1–C2)

## Version History

> - v0.1 — Initial PRD, OpenAI Realtime API architecture
> - v0.2 — Switched to BYOK hybrid, on-device Whisper STT
> - v0.3 — Final architecture: Groq Whisper API (cloud STT for code-switching), Kokoro-82M on-device TTS, WebRTC VAD, Opus compression, Gemini fallback, dual-key BYOK, streaming sentence-boundary TTS trick, quota math confirmed

---

## Table of Contents

1. [Document Purpose & Terminology Guide](#1-document-purpose--terminology-guide)
2. [Product Vision & Problem Statement](#2-product-vision--problem-statement)
3. [Target Users (Personas)](#3-target-users-personas)
4. [North Star Metric & KPIs](#4-north-star-metric--kpis)
5. [Product Architecture Overview](#5-product-architecture-overview)
6. [Architectural Decision Log](#6-architectural-decision-log)
7. [MVP Scope Definition](#7-mvp-scope-definition)
8. [Feature: Authentication & BYOK Onboarding](#8-feature-authentication--byok-onboarding)
9. [Feature: Speaking Pillar — Real-Time Conversation](#9-feature-speaking-pillar--real-time-conversation)
10. [Feature: Session Report Card](#10-feature-session-report-card)
11. [XP System Design](#11-xp-system-design)
12. [CEFR Level Mapping (A1–C2)](#12-cefr-level-mapping-a1c2)
13. [Design System](#13-design-system)
14. [Technical Architecture Spec](#14-technical-architecture-spec)
15. [User Flows](#15-user-flows)
16. [Acceptance Criteria](#16-acceptance-criteria)
17. [Risks & Mitigations](#17-risks--mitigations)
18. [Milestone Plan](#18-milestone-plan)
19. [Future Roadmap (Post-MVP)](#19-future-roadmap-post-mvp)

---

## 1. Document Purpose & Terminology Guide

### What This Document Is

A PRD (Product Requirements Document) is the single source of truth for what is being built, why, for whom, and how success is measured. It bridges the gap between vision and execution. Every feature, screen, and edge case traces back to this document.

### Terminology Reference

| Term | Definition |
| --- | --- |
| **PRD** | Product Requirements Document. The master "what and why" doc. |
| **Technical Spec** | The "how" doc — how engineers will implement what the PRD describes. |
| **ADL** | Architectural Decision Log. A record of every major technical decision and why it was made. |
| **Epic** | A large body of work representing a major feature area (e.g., "Speaking Pillar"). |
| **User Story** | A requirement written from the user's perspective: *"As a [user], I want to [action] so that [benefit]."* |
| **Acceptance Criteria (AC)** | Specific, testable conditions that must be true for a feature to be "done." |
| **MVP** | Minimum Viable Product. The smallest version that can be shipped and tested with real users. |
| **North Star Metric** | The single number that best represents your product delivering real value. |
| **KPI** | Key Performance Indicator. Measurable targets showing progress toward goals. |
| **User Flow** | The exact path a user takes through the app to complete a task. |
| **Information Architecture (IA)** | How screens and content are organized and navigated. |
| **Design System** | The reusable visual language: colors, fonts, spacing rules, and components. |
| **Component** | A reusable UI building block (button, card, modal, etc.). |
| **Edge Case** | An unusual scenario the product must handle gracefully. |
| **Latency** | Delay between an action and a response. The most critical metric for voice UX. |
| **P50 / P95** | Percentile measurements. P50 = median latency. P95 = worst-case for 95% of users. |
| **STT** | Speech-to-Text. Converts spoken audio to transcribed text. |
| **TTS** | Text-to-Speech. Converts text to spoken audio. |
| **VAD** | Voice Activity Detection. Detects when a person starts and stops speaking. |
| **BYOK** | Bring Your Own Key. Users supply their own API credentials, eliminating developer costs. |
| **Streaming** | Receiving AI response tokens one at a time as they generate, instead of waiting for the full reply. |
| **Sentence-boundary TTS** | Triggering text-to-speech on the first complete sentence in a stream, before the full reply arrives. |
| **Code-switching** | Mixing two or more languages within a single sentence or utterance. |
| **CEFR** | Common European Framework of Reference. International standard for language levels (A1→C2). |
| **DELE** | Diplomas de Español como Lengua Extranjera. Instituto Cervantes' official Spanish certification. |
| **OAuth** | Open Authorization. Standard for third-party login (Google) without passwords. |
| **Firestore** | Firebase's cloud NoSQL database. Used for user profiles, XP, session history. |
| **Rolling window** | Keeping only the last N turns of conversation history to control payload size and latency. |

---

## 2. Product Vision & Problem Statement

### Vision Statement

**Lingua** is a real-time AI conversation partner that gives every learner an always-available, infinitely patient speaking tutor — one that understands how people actually learn: imperfectly, code-switching between languages, making mistakes, and improving through honest, structured feedback tied to real certification standards.

### The Problem

Language learning apps fall into two failure modes:

- **Gamified drilling apps** (Duolingo, Babbel) — great for vocabulary, terrible for speaking. Zero real conversation practice. Users can read but cannot speak.
- **Human tutors** (iTalki, Preply) — excellent but $15–$60/hr, requires scheduling, and learners are embarrassed to make mistakes with a real person.

The result: **speaking is the most neglected skill in language education.** It is also the skill that matters most in the real world.

### The Competitive Landscape

**Pingo AI** is the closest existing product — a YC-backed startup building AI voice conversation for language learning. However:

- Their speech recognition is documented as "too lenient" — mistakes are not caught
- Their feedback is shallow compared to a structured curriculum framework
- They charge $14.99/month
- They use cloud TTS, adding a full network roundtrip to every AI response

**Lingua's structural advantages:**

- On-device TTS (Kokoro-82M) eliminates the cloud TTS roundtrip entirely — faster than Pingo
- Groq Whisper large-v3-turbo handles code-switching (Arabic + English + Spanish in one sentence) — Pingo does not
- Feedback graded against the official Instituto Cervantes DELE rubric — not generic encouragement
- Free forever for users via BYOK

### The Opportunity

The combination of Groq's LPU inference speed, on-device TTS, and on-device VAD makes it possible for the first time to build a voice conversation app that is faster than cloud-only competitors, free to operate, and smarter in its feedback.

### Product Positioning

> *"Practice Spanish any time, in any language you know. Lingua always speaks back in Spanish — and tells you exactly how to improve."*

---

## 3. Target Users (Personas)

### Persona 1 — "The Embarrassed Beginner" (Primary)

- **Name:** Omar, 24, university student
- **Background:** Studied Spanish 2 years. Can read okay, cannot hold a conversation.
- **Pain point:** Too embarrassed to practice with native speakers. Afraid of mistakes.
- **Goal:** Build enough speaking confidence to travel to Spain.
- **Device:** Android, mid-range phone, 4G connection.
- **Quote:** *"I know the words but they don't come out when I need them."*

### Persona 2 — "The Self-Study Hustler" (Secondary)

- **Name:** Sara, 31, working professional
- **Background:** Learning Spanish independently. Duolingo feels insufficient.
- **Pain point:** Can't afford a tutor. Has 20 minutes a day maximum.
- **Goal:** Reach B1 within a year for a job qualification.
- **Device:** Android, commutes by metro.
- **Quote:** *"I need something that tracks real progress, not just streaks."*

### Persona 3 — "The Heritage Speaker" (Tertiary)

- **Name:** Layla, 19, grew up hearing Arabic and some Spanish
- **Background:** Understands Spanish but never formally learned it. Mixes Arabic and English mid-sentence constantly.
- **Pain point:** Every app assumes she's starting from zero.
- **Goal:** Speak Spanish cleanly enough for professional situations.
- **Device:** Android.
- **Quote:** *"I know what I want to say, I just can't always say it in Spanish."*

---

## 4. North Star Metric & KPIs

### North Star Metric

**Weekly Active Speaking Minutes per User**
*If a user is speaking, the product is working. Every other metric — XP, retention, level progression — is downstream of this number.*

### MVP Launch KPIs (First 90 Days)

| KPI | Target | Rationale |
| --- | --- | --- |
| Average session duration | ≥ 5 minutes | Minimum meaningful practice time |
| Session completion rate | ≥ 70% | User reaches report card screen |
| D7 retention | ≥ 30% | Industry standard for language apps |
| Voice latency P50 | ≤ 350ms | Feels like a real conversation |
| Voice latency P95 | ≤ 600ms | Worst-case still acceptable |
| BYOK completion rate | ≥ 65% | Users who start onboarding finish key setup |
| App crash rate | ≤ 1% of sessions | Stability baseline |
| Auth → First session | ≥ 70% | Onboarding doesn't kill momentum |

---

## 5. Product Architecture Overview

### Core Design Philosophy

**Audio never leaves the phone. Only text crosses the network.**

This is the single architectural decision that makes everything else possible. Cloud STT + cloud LLM + cloud TTS pipelines (like Pingo's likely architecture) require three network roundtrips per exchange. By handling VAD and TTS on-device, Lingua requires only one network roundtrip — to Groq for STT + LLM — per exchange.

STT is the exception: it uses Groq's cloud Whisper API rather than on-device Whisper, because on-device Whisper tiny/base models fail at code-switching (mixing Arabic + English + Spanish in one utterance). Groq Whisper large-v3-turbo handles this accurately and uses the same API key already needed for the LLM — no extra credential or cost.

### The Full Pipeline

``` markdown
┌─────────────────────────────────────────────────────────────┐
│                        USER'S PHONE                         │
│                                                             │
│  USER SPEAKS                                                │
│      │                                                      │
│      ▼                                                      │
│  [WebRTC VAD — on-device, microseconds]                     │
│  Detects end of speech after ~500ms silence                 │
│      │                                                      │
│      ▼                                                      │
│  [Opus encoder — on-device]                                 │
│  Compresses audio ~80% (WAV → Opus)                         │
│      │                                                      │
│      │         ┌─── NETWORK (text + compressed audio) ──┐   │
│      ▼         ▼                                        │   │
│  ┌─────────────────────────────────────────────────┐    │   |
│  │              GROQ API (user's own key)          │    │   |
│  │                                                 │    │   |
│  │  Step 1: Whisper large-v3-turbo (STT)           │    │   |
│  │  Handles Arabic + English + Spanish mixing      │    │   │
│  │  → transcribed text (~150–200ms)                │    │   │
│  │                                                 │    │   │
│  │  Step 2: LLaMA 3.3 70B (LLM, streaming)         │    │   │
│  │  System prompt + rolling 8-turn history         │    │   │
│  │  → streams tokens (~100–200ms to first token)   │    │   │
│  └─────────────────────────────────────────────────┘    │   │
│                         │                               │   │
│          ┌──────────────┘                               │   │
│          ▼                                              │   │
│  First sentence boundary detected (. ? !)               │   │
│          │                                              │   │
│          ▼                                              │   │
│  [Kokoro-82M TTS — on-device]                           │   │
│  Speaks first sentence immediately (~50ms)              │   │
│  Meanwhile Groq streams next sentences                  │   │
│          │                                              │   │
│          ▼                                              │   │
│  Transcript UI updates token by token                   │   │
│                                                         │   │
│          └─────── NETWORK ──────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────┐       │
│  │  FALLBACK: If Groq returns 429 (rate limit)      │       │
│  │  → Silently retry via Google Gemini 2.5 Flash    │       │
│  │  → User notices nothing                          │       │
│  └──────────────────────────────────────────────────┘       │
│                                                             │
│  ┌──────────────────────────────────────────────────┐       │
│  │  POST-SESSION: Report Card Generation            │       │
│  │  Full transcript → Groq (1 API call) → JSON      │       │
│  │  XP calculated → saved to Firestore              │       │
│  └──────────────────────────────────────────────────┘       │
│                                                             │
│  ┌──────────────┐   ┌────────────────────────────────┐      │
│  │ Firebase     │   │ flutter_secure_storage         │      │
│  │ Auth +       │   │ Groq key (encrypted, Keystore) │      │
│  │ Firestore    │   │ Gemini key (encrypted, backup) │      │
│  └──────────────┘   └────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### End-to-End Latency (Confirmed)

| Step | Technology | Latency | On/Off Device |
| --- | --- | --- | --- |
| VAD: detect end of speech | WebRTC VAD | ~0ms (continuous) | On-device |
| Encode audio to Opus | Opus encoder | ~10ms | On-device |
| STT: audio → text | Groq Whisper large-v3-turbo | ~150–200ms | Cloud (Groq) |
| LLM: text → text (first token) | Groq LLaMA 3.3 70B | ~100–200ms | Cloud (Groq) |
| TTS: first sentence → audio | Kokoro-82M | ~50ms | On-device |
| **Total perceived latency** | | **~310–460ms** | |

*Note: STT and LLM run sequentially via the same Groq API key. Total network time is STT + LLM time only. No separate TTS network call.*

### Competitive Latency Comparison

| App | STT | LLM | TTS | Est. Total |
| --- | --- | --- | --- | --- |
| **Pingo AI (estimated)** | Cloud ~200ms | Cloud ~200ms | Cloud TTS ~300ms | ~700–900ms |
| **Lingua** | Groq ~175ms | Groq ~150ms | On-device ~50ms | ~375–475ms |

Lingua's structural advantage is the elimination of the cloud TTS roundtrip. This is a permanent architectural win, not a temporary optimization.

### BYOK: Why It Works at Scale

Cloud API free tiers are scoped to the account, not the user. A single developer key shared across users would be rate-limited immediately. BYOK routes each user through their own free account:

| Provider | Free Tier | Sufficient For |
| --- | --- | --- |
| Groq (primary) | ~500,000 tokens/day + ~7,200 sec audio/day | 1+ hours of speaking per day |
| Gemini 2.5 Flash (fallback) | ~1,000,000 tokens/day | Additional 2–3 hours if needed |

**Quota math for a 1-hour session (Groq):**

- ~180 exchanges × ~1,430 tokens/exchange = ~257,400 tokens
- 1 hour = ~51% of daily Groq token quota ✅
- 1 hour = 3,600 sec audio = 50% of daily Groq audio quota ✅
- A typical user practicing 20–30 min/day uses ~25% of their daily quota

**With both Groq + Gemini keys:**

- Combined daily token budget: ~1,500,000 tokens
- Effective daily speaking time: ~5–6 hours before hitting any limit
- The app silently switches to Gemini on any Groq 429 error — user never notices

---

## 6. Architectural Decision Log

Every major technical decision is recorded here with its rationale and the alternatives that were considered and rejected. This exists so that when someone asks "why did you do it this way?" there is a written answer.

---

### ADL-001: STT Provider

**Decision:** Groq Whisper large-v3-turbo (cloud, user's own key)
**Rejected:** On-device Whisper tiny/base

**Reason:** On-device Whisper tiny/base models have documented failure on code-switching — mixing languages within a single sentence. Since a core product requirement is that users can speak Arabic + English + Spanish in one utterance and be understood, the on-device small models are insufficient. Groq Whisper large-v3-turbo handles this accurately.

**Secondary benefit:** No large model file bundled in app (saves ~74–244MB download). Same API key used for LLM — one key, one provider, one BYOK setup.

**Trade-off accepted:** One additional network request per exchange for STT. Groq STT latency (~175ms) is acceptable within total pipeline budget.

---

### ADL-002: LLM Provider

**Decision:** Groq LLaMA 3.3 70B Versatile, streaming enabled
**Rejected:** OpenAI GPT-4o (paid), on-device small models (insufficient intelligence for Cervantes curriculum evaluation)

**Reason:** LLaMA 3.3 70B on Groq's LPU hardware generates ~280 tokens/second — fast enough for streaming sentence-by-sentence TTS. The model is sufficiently intelligent to evaluate Spanish grammar against formal Cervantes rubrics. Free on the user's own account.

**Fallback model:** `llama-3.1-8b-instant` (~750 tokens/sec) — used automatically if the 70B model hits rate limits mid-session.

---

### ADL-003: TTS Provider

**Decision:** Kokoro-82M on-device
**Rejected:** Android native Google TTS (robotic quality), ElevenLabs/cloud TTS (paid, adds network roundtrip)

**Reason:** Android's built-in TTS sounds robotic and creates a poor UX that will feel noticeably worse than competitors. ElevenLabs sounds excellent but costs money and adds ~300ms network latency. Kokoro-82M is a state-of-the-art 82 million parameter open-source model that runs locally, sounds natural, and generates speech in ~50ms. It adds ~82MB to app bundle size, which is the accepted trade-off.

**Impact:** On-device TTS is Lingua's primary structural latency advantage over Pingo and similar apps.

---

### ADL-004: Voice Activity Detection (VAD)

**Decision:** WebRTC VAD on-device
**Rejected:** Manual push-to-talk only, server-side VAD

**Reason:** In always-on mode (the primary UX), the app must know when the user has finished speaking before it can trigger the STT pipeline. WebRTC VAD is the industry standard — used in Google Meet, Signal, Discord. It runs in microseconds on-device, processing 10ms audio frames. Configured with ~500ms silence threshold to avoid cutting users off mid-sentence.

**Implementation note:** Push-to-talk bypasses VAD entirely — mic recording ends on button release. Both modes coexist in the same architecture.

---

### ADL-005: Audio Compression

**Decision:** Opus encoding before upload to Groq STT
**Rejected:** Raw WAV/PCM upload

**Reason:** Opus is the compression standard used by WhatsApp and Discord for voice. It achieves ~80% size reduction with no perceptible quality loss for speech. A typical 3-second voice clip: ~150KB WAV → ~30KB Opus. On a 4G connection this saves ~60–80ms of upload time per exchange. Over a 30-minute session this is meaningful.

---

### ADL-006: Conversation History Strategy

**Decision:** Rolling window of last 8 turns + one-line session summary
**Rejected:** Full conversation history per request

**Reason:** Sending full conversation history means each request gets larger as the session progresses. By turn 20, you might send 3,000 tokens of context to get a 100-token reply — slower and wasteful. A rolling 8-turn window keeps every request the same size regardless of session length. A one-line system-generated summary of the overall conversation is prepended to maintain continuity.

**Quota impact:** Consistent ~1,430 tokens per exchange throughout the entire session.

---

### ADL-007: Fallback Provider

**Decision:** Google Gemini 2.5 Flash as secondary LLM provider
**Rejected:** No fallback (single point of failure), paid fallback providers

**Reason:** Groq is the single point of failure in the architecture. If Groq has downtime, returns 429s, or changes their free tier, the entire app stops working. Gemini 2.5 Flash offers a free tier with 1,000,000 tokens/day and is an independent cloud provider. The app stores both keys at onboarding (Groq required, Gemini optional but strongly encouraged). On any Groq 429, the app retries via Gemini transparently.

**User experience:** The user never sees an error unless both providers fail simultaneously.

---

### ADL-008: API Key Storage

**Decision:** flutter_secure_storage (Android Keystore)
**Rejected:** SharedPreferences, Hive, plain file storage

**Reason:** Groq and Gemini API keys are sensitive credentials. Storing them in plain text (SharedPreferences, Hive) exposes them to any app with file system access on rooted devices. flutter_secure_storage uses the Android Keystore system — the same encrypted storage used by banking apps. Keys are encrypted at the OS level and cannot be extracted without the device's lock screen credentials.

---

### ADL-009: Network Awareness

**Decision:** Measure RTT on session start, adapt behavior
**Rejected:** No network detection

**Reason:** On a slow or congested network (2G, weak 4G), the 175ms STT estimate can balloon to 500ms+, breaking the latency budget. The app measures a lightweight ping to Groq before starting the session. If RTT > 400ms: reduce max_tokens to 80 (shorter AI replies arrive faster), warn the user, and disable always-on mode in favor of push-to-talk (to avoid VAD misfires under lag).

---

### ADL-010: Report Card Generation

**Decision:** Single Groq API call post-session, structured JSON response
**Rejected:** Real-time grading during session (too distracting), no post-session feedback

**Reason:** Post-session grading is less cognitively intrusive — the user focuses on the conversation, not the grade. One API call with the full transcript is cheaper and simpler than per-turn analysis. The prompt instructs the model to return only valid JSON, which the app parses directly into the report card UI. Retry logic handles malformed JSON (up to 3 attempts, fallback to a basic completion screen).

---

## 7. MVP Scope Definition

### ✅ In Scope — MVP

- Google OAuth sign-in and registration (Firebase Auth)
- BYOK onboarding: Groq API key (required) + Gemini API key (optional backup)
- Encrypted API key storage (Android Keystore via flutter_secure_storage)
- Self-reported level selection (A1 → C2, "I don't know" option)
- Target language selection (Spanish only, others visible but locked)
- Home screen: single "Let's Speak" CTA, XP progress bar, level badge
- Real-time voice conversation: always-on mic (default) + push-to-talk toggle
- Multilingual input: user speaks any language, AI replies only in Spanish
- Code-switching support: Arabic + English + Spanish in one utterance
- In-session UI: real-time transcript, session timer, end session button
- Session Report Card: overall grade, fluency/grammar/vocabulary scores, XP breakdown, mistakes + corrections, tutor notes
- Basic XP system: earned per session, stored in Firestore, displayed on home screen

### ❌ Out of Scope — MVP

| Feature | Why Deferred |
| --- | --- |
| Reading pillar | Requires curriculum content system |
| Writing pillar | Requires writing evaluation pipeline |
| Listening pillar | Requires audio content library |
| Curriculum-aligned topic progression | Requires Cervantes doc parsing + topic mapping |
| Push notifications (streaks, reminders) | Post-MVP engagement feature |
| Leaderboards / social | Requires social graph |
| XP deductions for poor sessions | Too punishing for MVP, validate engagement first |
| Multiple target languages | Content and prompting work per language |
| iOS support | Android-first, expand after validation |
| Subscription / paywall | Validate product first |
| Custom AI voice selection | Kokoro-82M is sufficient for MVP |
| Offline mode | Complex, deprioritized |

---

## 8. Feature: Authentication & BYOK Onboarding

### Epic: AUTH + SETUP

#### User Stories

- **AUTH-01:** As a new user, I want to sign up with my Google account so I don't need a new password.
- **AUTH-02:** As a returning user, I want to be automatically signed in when I open the app.
- **AUTH-03:** As a user, I want to sign out from my profile screen.
- **SETUP-01:** As a new user, I want to be guided through getting my free Groq API key so the app can work.
- **SETUP-02:** As a user, I want my API key stored securely so I don't have to enter it again.
- **SETUP-03:** As a user, I want to optionally add a Gemini backup key so the app never stops working.

#### First-Time Onboarding Sequence

``` markdown
Step 1: Google Sign-In
Step 2: BYOK Setup — Groq Key (required)
Step 3: BYOK Setup — Gemini Key (optional, "Supercharge your app")
Step 4: Level Selection ("What's your current Spanish level?")
Step 5: Language Confirmation (Spanish — locked for MVP)
Step 6: Home Screen
```

#### BYOK Setup Screen (Groq — Step 2)

**Framing:** Do not say "API key." Say "your free connection" or "your personal AI key." Technical users will understand; non-technical users will follow the visual guide without needing to understand what it is.

``` markdown
┌─────────────────────────────────────────────┐
│                                             │
│  🔑  Set up your free AI connection         │
│                                             │
│  Lingua uses a free AI service to power     │
│  your conversations. You'll need your own   │
│  personal key — it takes 30 seconds.        │
│                                             │
│  ① Open the link below                     |
│  ② Create a free account                   │
│  ③ Click "Create API Key"                  │
│  ④ Copy and paste it here                  |
│                                             │
│  [Open Groq Console →]   (opens browser)    │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │  Paste your key here...             │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  🔒 Stored privately on your device only    │
│                                             │
│  [Continue]                                 │
│                                             │
└─────────────────────────────────────────────┘
```

**Validation:** On paste, the app makes a lightweight test call to Groq (single token, minimal cost) to verify the key is valid before proceeding. Invalid key shows inline error: "This key doesn't seem to work — try copying it again."

#### Key Security

- Keys stored via `flutter_secure_storage` in Android Keystore
- Keys are never logged, never sent to Firebase, never sent anywhere except directly to Groq/Gemini
- Keys are encrypted at the OS level — the same standard as banking apps
- On sign-out: user is asked if they want to clear stored keys

---

## 9. Feature: Speaking Pillar — Real-Time Conversation

### Epic: SPEAK

#### User Stories

- **SPEAK-01:** As a user, I want to tap "Let's Speak" and immediately start a Spanish conversation.
- **SPEAK-02:** As a user, I want the AI to always reply in Spanish even if I speak in English or Arabic.
- **SPEAK-03:** As a user, I want the AI to understand mixed-language sentences (code-switching) so I'm not blocked when I forget a Spanish word.
- **SPEAK-04:** As a user, I want to see a real-time transcript of both sides so I can read what's being said.
- **SPEAK-05:** As a user, I want always-on mic as the default so I can speak naturally without holding a button.
- **SPEAK-06:** As a user, I want to switch to push-to-talk if I'm in a noisy environment.
- **SPEAK-07:** As a user, I want to see a live session timer so I know how long I've been practicing.
- **SPEAK-08:** As a user, I want to end the session at any time and go to my report card.

#### AI Tutor System Prompt (Lucia)

This prompt is sent with every request. It defines Lucia's entire behavior.

``` Markdown
You are Lucia, a warm, encouraging Spanish language tutor. 
Your role is to have natural, flowing conversations with 
learners who are practicing their Spanish.

═══ ABSOLUTE RULES ═══
1. You ALWAYS reply ONLY in Spanish, no exceptions.
2. You understand input in ANY language or ANY mix of 
   languages (English, Arabic, French, Tagalog, etc.)
   within a single message.
3. Keep replies to 2–3 sentences maximum. This is 
   spoken conversation, not a lecture.
4. Stream your response — generate it naturally.

═══ LANGUAGE HANDLING ═══
- If the user says a word in another language because 
  they don't know it in Spanish, naturally weave the 
  Spanish equivalent into your reply. Do not make it 
  feel like a correction — make it feel like conversation.
- Example: User says "I feel very... كيف أقول tired?"
  Lucia: "¡Ah, estás cansado! Yo también me siento 
  cansada a veces. ¿Dormiste bien anoche?"
  (Note: Lucia used "cansado" naturally without calling 
  it a correction.)

═══ PEDAGOGICAL BEHAVIOR ═══
- Adapt vocabulary complexity to the user's apparent level.
  Simpler Spanish for beginners, richer vocabulary for 
  advanced speakers.
- For grammar mistakes: model the correct form naturally 
  in your reply WITHOUT explicitly pointing it out 
  (implicit correction). Only explicitly correct when 
  the mistake would cause genuine miscommunication.
- Ask follow-up questions to keep the conversation moving.
- Vary topics naturally. Don't stay on one topic too long.
- Be warm, patient, and never condescending.

═══ CONVERSATION DYNAMICS ═══
- Start by greeting the user warmly and asking a simple, 
  open question about their day or interests.
- Never refuse to engage because the user spoke in 
  another language. Always respond, always in Spanish.
- If the user seems to be struggling, slow down and use 
  shorter, simpler sentences.

CURRENT USER LEVEL: {user_cefr_level}
TARGET LANGUAGE: Spanish (Castilian)
```

#### In-Session UI Specification

``` Markdown
┌────────────────────────────────────────┐
│  ✕ End Session              00:07:14   │  ← tap X to end, timer always visible
├────────────────────────────────────────┤
│                                        │
│   ╭─────────────────────────╮          │
│   │ Lucia                   │          │  ← AI bubble, left-aligned
│   │ ¡Hola! ¿Cómo estás      │          │
│   │ hoy? ¿Tienes planes     │          │
│   │ para el fin de semana?  │          │
│   ╰─────────────────────────╯          │
│                                        │
│          ╭─────────────────────────╮   │
│          │                    You  │   │  ← User bubble, right-aligned
│          │ I'm good... como se     │   │
│          │ dice "excited"?         │   │
│          ╰─────────────────────────╯   │
│                                        │
│   ╭─────────────────────────╮          │
│   │ Lucia                   │          │
│   │ ¡Estás emocionado!      │          │
│   │ ¿Por qué estás          │          │
│   │ emocionado hoy?         │          │
│   ╰─────────────────────────╯          │
│                                        │
│   ● ● ●  (typing indicator)            │  ← shown while Groq generates
│                                        │
├────────────────────────────────────────┤
│  ≋≋≋≋≋≋≋ SPEAKING ≋≋≋≋≋≋≋              │  ← waveform while AI speaks
├────────────────────────────────────────┤
│                                        │
│            ⬤  (96px mic button)       │  ← pulsing amber when listening
│                                        │
│   [  Push to talk  ]  [ Always on ⬤ ] │  ← toggle, always-on is default
│                                        │
└────────────────────────────────────────┘
```

#### Mic & Audio States

| State | Visual | Audio |
| --- | --- | --- |
| **Always-on, listening** | Mic button pulsing amber ring | WebRTC VAD active |
| **AI generating** | Typing indicator (3 dots) | No mic input |
| **AI speaking** | Waveform animation | Kokoro TTS playing |
| **Push-to-talk held** | Mic button bright, scale up | Recording |
| **Push-to-talk released** | Brief processing flash | Opus → Groq STT |
| **Error / reconnecting** | Mic button red, "Reconnecting..." | Paused |

#### Always-On Mode Technical Behavior

1. WebRTC VAD monitors mic continuously in a background isolate
2. On speech detected: begin buffering audio frames
3. On silence detected (~500ms): flush buffer, Opus-encode, send to Groq STT
4. Groq STT returns transcript → appended to conversation history
5. LLM call fires immediately → streams response → Kokoro TTS on first sentence
6. Repeat

#### Push-to-Talk Mode Technical Behavior

1. User presses and holds button
2. Mic recording starts, audio buffered
3. User releases button
4. Buffer Opus-encoded and sent to Groq STT
5. Same pipeline from Step 4 above

---

## 10. Feature: Session Report Card

### Epic: REPORT

#### User Stories

- **REPORT-01:** As a user, after ending a session I want a clear summary of how I performed.
- **REPORT-02:** As a user, I want to see specific mistakes and corrections so I can learn from them.
- **REPORT-03:** As a user, I want to see XP earned broken down by category so it feels earned.
- **REPORT-04:** As a user, I want qualitative notes on fluency, grammar, and vocabulary.
- **REPORT-05:** As a user, I want an overall grade so I have a single number to anchor progress.

#### Report Generation Process

After the user taps "End Session":

1. Session transcript (both sides, full text) is captured from local state
2. Single POST request to Groq Chat API with transcript + grading prompt
3. Groq returns structured JSON
4. App parses JSON → renders Report Card UI
5. XP total extracted from JSON → added to Firestore user document
6. If JSON parse fails → retry up to 3 times → fallback to basic completion screen

**Report Generation Prompt:**

``` Markdown
You are a certified Spanish language examiner trained on the 
Instituto Cervantes DELE framework.

Analyze the conversation transcript below. The learner's 
stated level is {user_cefr_level}.

Return ONLY a valid JSON object. No preamble, no markdown 
fences, no explanation. Just the raw JSON object.

{
  "overall_grade": "B+",
  "fluency_score": 72,
  "grammar_score": 65,
  "vocabulary_score": 80,
  "session_duration_seconds": 430,
  "active_speaking_seconds": 247,
  "spanish_word_count": 143,
  "topics_covered": ["greetings", "daily routine", "hobbies"],
  "mistakes": [
    {
      "what_user_said": "Yo soy muy cansado",
      "correction": "Yo estoy muy cansado",
      "explanation": "Use 'estar' for temporary states like tiredness. 'Ser' is for permanent characteristics.",
      "category": "grammar",
      "severity": "minor"
    }
  ],
  "vocabulary_highlights": [
    {
      "word": "emocionado",
      "english": "excited",
      "context": "User learned this word mid-conversation",
      "used_correctly": true
    }
  ],
  "fluency_note": "Good sentence flow with natural rhythm. Hesitation on verb conjugations but recovers quickly.",
  "grammar_note": "Consistent ser/estar confusion. This is the highest-priority item to study next.",
  "vocabulary_note": "Strong range of everyday vocabulary. Begin incorporating connectors: sin embargo, por lo tanto, aunque.",
  "encouragement": "You held a 7-minute conversation entirely in Spanish and learned two new words mid-session. That is real progress.",
  "xp_breakdown": {
    "time_speaking_xp": 33,
    "spanish_words_xp": 28,
    "grammar_bonus_xp": 8,
    "vocabulary_bonus_xp": 15,
    "session_completion_xp": 25,
    "first_session_today_xp": 10,
    "total_xp": 119
  }
}

TRANSCRIPT:
{full_session_transcript}
```

#### Report Card Screen Layout

```Markdown
┌──────────────────────────────────────────┐
│  ✨ Session Complete                     │
│  7 min 10 sec  •  4 min 7 sec speaking   │
├──────────────────────────────────────────┤
│                                          │
│         ┌──────┐                         │
│         │  B+  │  Overall Grade          │
│         └──────┘                         │
│                                          │
│  Fluency      ████████░░  72             │
│  Grammar      ██████░░░░  65             │
│  Vocabulary   █████████░  80             │
│                                          │
├──────────────────────────────────────────┤
│  XP EARNED                               │
│                                          │
│  ⏱  Time Speaking        +30 XP          │
│  🗣  Spanish Words        +29 XP         │
│  📐  Grammar Bonus        +8 XP          │
│  📚  Vocabulary Range     +15 XP         │
│  ✅  Session Complete     +25 XP         │
│  🌅  First Session Today  +10 XP         │
│  ─────────────────────────────           │
│  🏆  TOTAL                +119 XP        │
│                                          │
│  [████████████░░░░░░░] 1,359 → 1,478 XP  │
│                         Level: A2        │
├──────────────────────────────────────────┤
│  TOPICS COVERED                          │
│  Greetings  •  Daily Routine  •  Hobbies │
│                                          │
├──────────────────────────────────────────┤
│  MISTAKES & CORRECTIONS  (1)             │
│                                          │
│  ❌  "Yo soy muy cansado"                │
│  ✅  "Yo estoy muy cansado"              │
│  📌  Use estar for temporary states      │
│      like tiredness, not ser.            │
│                                          │
├──────────────────────────────────────────┤
│  NEW VOCABULARY  (1)                     │
│  emocionado — excited ✓                  │
│                                          │
├──────────────────────────────────────────┤
│  TUTOR NOTES                             │
│  Fluency: Good rhythm, some hesitation   │
│  on conjugations but recovers quickly.   │
│                                          │
│  Grammar: Ser/estar is your #1 item.     │
│                                          │
│  Vocabulary: Strong base. Try adding     │
│  connectors in your next session.        │
├──────────────────────────────────────────┤
│  You held a 7-minute Spanish             │
│  conversation and learned two words      │
│  mid-session. That is real progress.     │
├──────────────────────────────────────────┤
│  [↗ Share]         [🎙 Speak Again]       │
└──────────────────────────────────────────┘
```

---

## 11. XP System Design

### Philosophy

XP in Lingua is calibrated to Instituto Cervantes DELE levels. Every XP point represents demonstrable language ability. The system rewards output quantity (time, words), output quality (grammar, vocabulary), and consistency (daily streaks). It never rewards passive behavior.

### XP Earning Categories (MVP — Speaking Only)

| Category | Formula | Cap per Session | Notes |
| --- | --- | --- | --- |
| **Time Speaking** | 8 XP per mic-active minute | None | Counts VAD-detected speech only, not session duration |
| **Spanish Words Used** | 0.2 XP per Spanish word | 40 XP | Encourages target language use |
| **Grammar Bonus** | grammar_score × 0.2 | 20 XP | Scaled to report card grammar score |
| **Vocabulary Bonus** | vocab_score × 0.2 | 20 XP | Scaled to report card vocabulary score |
| **Session Completion** | 25 XP flat | 25 XP | Just for finishing and viewing the report card |
| **First Session of Day** | 10 XP flat | 10 XP | Encourages daily habit |
| **Fluency Streak Bonus** | +5 XP per 5-min block of continuous speaking | 15 XP | Rewards sustained conversation |

### XP Deductions (Post-MVP — Not in MVP)

| Trigger | Deduction |
| --- | --- |
| Session abandoned under 1 minute | −5 XP |
| Zero Spanish words spoken | −10 XP |

*No deductions in MVP. Only positive XP. Validate engagement before introducing penalties.*

### XP Persistence

- Calculated server-side in the report generation prompt (LLM does the math based on session data)
- Verified client-side (app re-calculates and cross-checks)
- Written to Firestore user document after report card is displayed
- Cached locally so XP bar displays instantly even offline

---

## 12. CEFR Level Mapping (A1–C2)

### Level Thresholds

XP thresholds are calibrated to Instituto Cervantes curriculum documents and aligned with published research on hours required to reach each CEFR level. Each level reflects genuine communicative ability — not just app usage time.

| Level | Description | XP Range | Est. Speaking Hours | Key Capabilities |
| --- | --- | --- | --- | --- |
| **A1** | Complete beginner | 0 – 500 | 0–15h | Greetings, numbers, colors, basic present tense |
| **A2** | Basic communication | 500 – 1,500 | 15–40h | Past tense, opinions, shopping, daily life |
| **B1** | Intermediate | 1,500 – 3,500 | 40–100h | Travel, hypotheticals, narrating events, work |
| **B2** | Upper intermediate | 3,500 – 7,000 | 100–200h | Fluent with native speakers, abstract topics |
| **C1** | Advanced | 7,000 – 13,000 | 200–350h | Professional/academic discourse, spontaneous expression |
| **C2** | Mastery | 13,000 – 20,000 | 350–500h | Near-native range, idiomatic, rhetorical |

### Level-Up Event

When a user crosses a threshold:

- Full-screen celebration animation (particle burst, 2 seconds)
- New level badge revealed with animation
- Profile and home screen update immediately
- Lucia's system prompt updates: `CURRENT USER LEVEL: {new_level}` — AI difficulty adjusts automatically next session

### Curriculum Integration (Post-MVP)

Instituto Cervantes documents define topic coverage per level. In post-MVP, the system prompt will include the current level's topic list so conversations are curriculum-aligned — not just free conversation but structured practice of A2 vocabulary before advancing to B1, etc.

---

## 13. Design System

### Brand Personality

**Warm. Intelligent. Alive.** Not clinical like a textbook. Not childish like Duolingo. The feeling of the best language exchange partner you've ever had — the one who's patient, smart, and genuinely happy when you improve.

### Visual Direction

**Refined dark theme with organic warmth.** Deep midnight navy backgrounds. Warm amber as the primary action color. Clean white type. The speaking screen should feel like an intimate late-night conversation — private, focused, safe to make mistakes.

### Color System

| Token | Value | Usage |
| --- | --- | --- |
| `--bg-primary` | `#0D0F1A` | Main app background |
| `--bg-surface` | `#161928` | Cards, bottom sheets |
| `--bg-elevated` | `#1E2235` | Transcript bubbles, input fields |
| `--accent-primary` | `#F5A623` | Mic button, XP bar, CTAs, level badges |
| `--accent-secondary` | `#4A90E2` | AI (Lucia) transcript bubbles, links |
| `--success` | `#52C97D` | Correct items, XP gains, completion |
| `--error` | `#E05C5C` | Mistakes, corrections |
| `--text-primary` | `#F0F2FF` | All main readable text |
| `--text-secondary` | `#8B93B4` | Labels, timestamps, secondary info |
| `--border` | `#2A2F4A` | Card borders, dividers |
| `--mic-active-glow` | `rgba(245,166,35,0.35)` | Mic button shadow when listening |

### Typography System

| Role | Font | Weight | Size Range |
| --- | --- | --- | --- |
| **Display / Hero** | Fraunces (variable serif) | 700 | 32–48sp |
| **Headings** | Fraunces | 600 | 20–28sp |
| **Body / UI Text** | DM Sans | 400 | 14–16sp |
| **UI Emphasis** | DM Sans | 600 | 14–16sp |
| **Transcript Text** | JetBrains Mono | 400 | 13–15sp |
| **Labels / Caps** | DM Sans | 500 | 11–12sp + letter-spacing |

*Fraunces: a variable serif with an optical size axis — feels editorial, warm, and distinct from every generic language app.*
*DM Sans: clean geometric sans, excellent readability at small UI sizes.*
*JetBrains Mono: for transcript text — monospace creates a clear visual separation between conversation and UI.*

### Spacing System (8pt grid)

`4 / 8 / 12 / 16 / 24 / 32 / 48 / 64` — all padding, margin, and gap values use these multiples.

### Border Radius

| Context | Value |
| --- | --- |
| Chips, tags, small elements | 8dp |
| Buttons, input fields, cards | 16dp |
| Bottom sheets, modals | 24dp (top corners only) |
| Mic button, avatars, level badges | 9999dp (full circle) |

### Key Component Specs

#### The Mic Button (Hero Component)

- **Size:** 96dp diameter
- **Shape:** Full circle
- **Fill (listening):** Radial gradient, `#F5A623` → `#E8940A`
- **Drop shadow (listening):** `0 8dp 32dp rgba(245,166,35,0.4)`
- **Pulse animation:** Expanding ring, opacity 1→0, scale 1→1.5, 1.5s loop, sine ease — organic, never jarring
- **Push-to-talk active:** scale(0.95), brightness +10%, instant
- **Icon:** Microphone, white, 36dp, centered

#### Lucia Transcript Bubble

- **Background:** Linear gradient `#1B3A5C` → `#1E2B4A`
- **Left accent:** 3dp solid `#4A90E2`
- **Border radius:** `16 16 16 4` dp (flat bottom-left corner, pointing left)
- **Max width:** 78% of screen width
- **Alignment:** Left

#### User Transcript Bubble

- **Background:** `#2A2F4A`
- **Border radius:** `16 16 4 16` dp (flat bottom-right corner, pointing right)
- **Max width:** 72% of screen width
- **Alignment:** Right

#### XP Progress Bar

- **Height:** 8dp
- **Background:** `#2A2F4A`
- **Fill:** Gradient `#F5A623` → `#52C97D` (warm → cool — visually communicates growth)
- **Animation on XP gain:** Width interpolates from old → new value, 800ms ease-out cubic

### Motion Principles

| Animation | Duration | Easing | Notes |
| --- | --- | --- | --- |
| Transcript bubble appear | 200ms | ease-out | Fade + translate-y 8dp → 0 |
| Mic pulse ring | 1500ms loop | sine | Never jarring — organic heartbeat |
| Report card section reveal | 120ms stagger | ease-out | Each section fades in sequentially |
| XP counter count-up | 800ms | ease-out cubic | Count from old value to new |
| Level-up burst | 2000ms | spring | Full screen, then auto-dismiss |
| Screen transitions | 300ms | ease-in-out | Slide for forward, fade for back |

---

## 14. Technical Architecture Spec

### Stack Summary

| Layer | Technology | Purpose |
| --- | --- | --- |
| **Framework** | Flutter (Dart) | Cross-platform, Android-first |
| **Auth** | Firebase Authentication | Google OAuth, session persistence |
| **Database** | Firebase Firestore | User profiles, XP, session history |
| **STT** | Groq Whisper large-v3-turbo | Code-switching STT, user's own key |
| **LLM** | Groq LLaMA 3.3 70B (streaming) | AI conversation + report generation |
| **LLM Fallback** | Google Gemini 2.5 Flash | Backup on Groq 429 or downtime |
| **TTS** | Kokoro-82M (on-device) | Natural voice output, zero network cost |
| **VAD** | WebRTC VAD (on-device) | Turn detection in always-on mode |
| **Audio Compression** | Opus encoder | 80% audio size reduction before upload |
| **Key Storage** | flutter_secure_storage | Android Keystore encryption |

### The Conversational Loop (Detailed)

```dart
// Pseudocode — actual implementation will differ

// 1. VAD detects end of speech
onSpeechEnd(audioBuffer) {

  // 2. Encode to Opus (~10ms)
  final opus = opusEncoder.encode(audioBuffer);

  // 3. Upload to Groq Whisper
  final transcript = await groqWhisper.transcribe(
    audio: opus,
    model: 'whisper-large-v3-turbo',
    language: null,  // null = auto-detect, handles code-switching
  );

  // 4. Append to rolling history
  conversationHistory.add({role: 'user', content: transcript});
  if (conversationHistory.length > 8) {
    conversationHistory.removeAt(0);
  }

  // 5. Stream LLM response
  final stream = groqLLM.streamChat(
    model: 'llama-3.3-70b-versatile',
    messages: [systemPrompt, ...conversationHistory],
    maxTokens: 120,
  );

  String buffer = '';
  await for (final token in stream) {
    buffer += token;
    transcriptUI.appendToken(token);  // update UI in real time

    // 6. Sentence-boundary TTS trigger
    if (buffer.endsWith('.') || buffer.endsWith('?') || buffer.endsWith('!')) {
      kokoroTTS.speak(buffer);  // speak immediately, don't wait for full response
      buffer = '';
    }
  }

  // 7. Append full response to history
  conversationHistory.add({role: 'assistant', content: fullResponse});
}
```

### Groq API Call Structure

**STT Request:**

```json
POST https://api.groq.com/openai/v1/audio/transcriptions
Authorization: Bearer {user_groq_key}
Content-Type: multipart/form-data

{
  "file": "<opus audio>",
  "model": "whisper-large-v3-turbo",
  "response_format": "json",
  "language": null
}
```

**LLM Request (streaming):**

```json
POST https://api.groq.com/openai/v1/chat/completions
Authorization: Bearer {user_groq_key}

{
  "model": "llama-3.3-70b-versatile",
  "messages": [
    {"role": "system", "content": "<lucia system prompt>"},
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "..."},
    ... (rolling 8-turn window)
  ],
  "stream": true,
  "max_tokens": 120,
  "temperature": 0.8
}
```

### Fallback Logic

```dart
Future<String> callLLM(List messages) async {
  try {
    return await groqAPI.chat(messages, key: userGroqKey);
  } on RateLimitException {
    if (userGeminiKey != null) {
      return await geminiAPI.chat(messages, key: userGeminiKey);
    }
    throw NoFallbackAvailableException();
  }
}
```

### Network Awareness on Session Start

```dart
Future<SessionConfig> checkNetworkBeforeSession() async {
  final rtt = await measurePing('https://api.groq.com');
  
  if (rtt > 400) {
    return SessionConfig(
      maxTokens: 80,           // shorter responses, faster
      micMode: PushToTalk,     // avoid VAD misfires under lag
      showSlowConnectionWarning: true,
    );
  }
  return SessionConfig.defaults();
}
```

### Firestore Data Model

```json
users/
  {uid}/
    displayName:          String
    email:                String
    targetLanguage:       "es"
    selfReportedLevel:    "beginner" | "a1" | "a2" | ... | "c2"
    currentCefrLevel:     "A1" | "A2" | ... | "C2"
    currentXP:            Number
    groqKeyConfigured:    Boolean   // true/false only — key never stored here
    geminiKeyConfigured:  Boolean   // true/false only
    streakDays:           Number
    lastSessionDate:      Timestamp
    totalSessionCount:    Number
    totalSpeakingSeconds: Number
    createdAt:            Timestamp

    sessions/
      {sessionId}/
        startedAt:              Timestamp
        endedAt:                Timestamp
        durationSeconds:        Number
        activeSpeakingSeconds:  Number
        spanishWordCount:       Number
        turnCount:              Number
        transcript:             Array<{role, text, timestamp}>
        report:                 {
          overallGrade:         String
          fluencyScore:         Number
          grammarScore:         Number
          vocabularyScore:      Number
          topicsCovered:        Array<String>
          mistakes:             Array<{said, correction, explanation, category, severity}>
          vocabularyHighlights: Array<{word, english, context, usedCorrectly}>
          fluencyNote:          String
          grammarNote:          String
          vocabularyNote:       String
          encouragement:        String
          xpBreakdown:          Object
          totalXP:              Number
        }
```

### Flutter Package List

```yaml
dependencies:
  # Firebase
  firebase_core:             ^3.0.0
  firebase_auth:             ^5.0.0
  cloud_firestore:           ^5.0.0
  google_sign_in:            ^6.0.0

  # STT — Groq Whisper via HTTP (multipart upload)
  http:                      ^1.2.0
  http_parser:               ^4.0.0

  # VAD — WebRTC Voice Activity Detection
  flutter_webrtc:            ^0.10.0

  # Audio Capture
  record:                    ^5.0.0

  # Audio Compression
  flutter_opus:              ^0.1.0      # Opus encoding

  # TTS — Kokoro-82M on-device
  # (direct integration via flutter FFI or platform channel — package TBD)
  # Fallback during development: flutter_tts for testing

  # Secure Key Storage
  flutter_secure_storage:    ^9.0.0

  # State Management
  flutter_riverpod:          ^2.5.0

  # Navigation
  go_router:                 ^14.0.0

  # Animations
  flutter_animate:           ^4.5.0

  # Utilities
  url_launcher:              ^6.2.0      # Open Groq console in browser
  intl:                      ^0.19.0     # Date/time formatting
  connectivity_plus:         ^6.0.0      # Network awareness
```

### Cost Analysis (Confirmed)

| Component | Developer Cost | User Cost | Notes |
| --- | --- | --- | --- |
| Firebase Auth | $0 | $0 | Free up to 10k MAU |
| Firestore | $0 | $0 | Free up to 1GB, 50k reads/day |
| Groq STT | $0 | $0 | User's own free account |
| Groq LLM | $0 | $0 | User's own free account |
| Gemini LLM | $0 | $0 | User's own free Google account |
| Kokoro TTS | $0 | $0 | On-device, open source |
| WebRTC VAD | $0 | $0 | On-device, open source |
| **Total** | **$0** | **$0** | |

### Quota Validation (Confirmed Math)

**1-hour session on Groq free tier:**

| Resource | Used | Daily Limit | % Used |
| --- | --- | --- | --- |
| LLM Tokens | ~257,400 | ~500,000 | 51% ✅ |
| Whisper Audio | ~3,600 sec | ~7,200 sec | 50% ✅ |

**Typical user (30 min/day):**

- LLM: ~128,700 tokens = 26% of daily limit ✅
- Audio: ~1,800 sec = 25% of daily limit ✅

**With Gemini fallback added:**

- Combined token budget: ~1,500,000/day
- Effective maximum daily practice: ~5–6 hours before any limit hit

---

## 15. User Flows

### Flow 1: First-Time User (Complete)

```Markdown
Open App
    │
    ▼
Sign In Screen
    |
    │ Tap "Continue with Google"
    ▼
Google OAuth (system sheet)
    |
    │ Authenticated
    ▼
Firestore: create user document (XP=0, level=A1)
    │
    ▼
BYOK Step 1: Groq Key Setup
    │
    | User opens Groq console, creates key, pastes it
    │ App validates key (test call)
    ▼
BYOK Step 2: Gemini Key (optional)
    │
    | "Add a backup key for uninterrupted practice"
    │ Skip or paste key
    ▼
Level Selection
    │
    | User picks their current level
    ▼
Language Confirmation (Spanish — pre-selected)
    │
    | Tap "Let's Start"
    ▼
Home Screen (first time: brief tooltip on the Speak button)
```

### Flow 2: Speaking Session (Complete)

```Markdown
Home Screen
    |
    │ Tap "Let's Speak"
    ▼
Network check (ping Groq, ~100ms)
    │
    | OK: proceed  |  Slow: show warning, adjust config
    ▼
Mic Permission (if not previously granted)
    │
    | Granted: proceed  |  Denied: show explanation screen
    ▼
Speaking Screen
    │
    | Kokoro TTS: Lucia greets user in Spanish (pre-loaded greeting,
    │ no API call — instant start)
    │
    │ === SESSION LOOP ===
    │ VAD detects user speech → buffer audio
    │ VAD detects end → Opus encode → Groq Whisper STT
    │ Transcript → update user bubble
    │ Groq LLM stream → update Lucia bubble token by token
    │ First sentence complete → Kokoro TTS speaks
    │ Continue streaming + speaking
    │ === END LOOP ===
    │
    │ User taps "End Session" (X button)
    ▼
Report Generation Screen
    │
    | "Generating your report..." 
    │ Spinner animation (3–10 sec)
    │ Full transcript → Groq → JSON report
    ▼
Report Card Screen
    │
    | User scrolls through report
    │ XP written to Firestore
    ▼
[ Speak Again ] → Speaking Screen
[ Home ]        → Home Screen (XP updated)
```

### Flow 3: Returning User

```Markdown
Open App → Auto-authenticated (Firebase persisted token)
         → Home Screen directly (no re-login, no onboarding)
```

### Flow 4: Groq Rate Limit During Session

```Markdown
User speaks
    │
    ▼
Groq returns 429 (rate limit)
    │
    ├── Gemini key available?
    │       │ Yes → retry via Gemini transparently → session continues
    │       │ No  → show brief toast: "Switching AI..." → retry with smaller model
    ▼
Session continues. User does not see an error.
```

### Flow 5: Network Drops During Session

```Markdown
Network drops mid-session
    │
    ▼
App detects (connectivity_plus)
    │
    ▼
Lucia bubble: "Reconnectando..." (in Spanish)
Transcript buffered locally (every 30 sec auto-save to Firestore)
Mic paused
    │
    ▼
Network restored
    │
    ▼
Session resumes automatically. Transcript preserved.
```

---

## 16. Acceptance Criteria

### AUTH + BYOK SETUP

- [ ] User can sign in with Google in under 3 taps
- [ ] Groq key validation provides inline feedback within 3 seconds
- [ ] Invalid Groq key shows clear error with instructions to try again
- [ ] Keys are stored in Android Keystore (not SharedPreferences)
- [ ] Gemini key step can be skipped without blocking access
- [ ] Onboarding sequence is shown only on first login
- [ ] Returning users go directly to Home Screen

### SPEAKING SESSION

- [ ] First Lucia greeting plays within 500ms of session screen appearing (pre-loaded)
- [ ] VAD correctly detects end of user speech within ~500ms of silence
- [ ] STT transcription appears in user bubble within 400ms of speech end
- [ ] AI first response starts within 600ms of transcript being ready (P95)
- [ ] AI always replies in Spanish regardless of user input language
- [ ] Code-switching input (Arabic + English + Spanish mixed) is transcribed correctly
- [ ] TTS begins speaking first sentence before full response is complete
- [ ] Transcript updates in real-time token-by-token
- [ ] Push-to-talk mode records on hold, processes on release
- [ ] Always-on mode can be toggled to push-to-talk mid-session
- [ ] Session timer is accurate and always visible
- [ ] Session ends cleanly on X button tap at any point
- [ ] On Groq 429: automatic Gemini fallback, no error shown to user
- [ ] Transcript auto-saves to Firestore every 30 seconds

### REPORT CARD

- [ ] Report card appears within 10 seconds of session end (P95)
- [ ] Report includes: grade, 3 scores, XP breakdown, at least 1 mistake if applicable, 3 tutor notes, encouragement
- [ ] XP total added to Firestore user document correctly
- [ ] XP progress bar on home screen reflects new total after session
- [ ] "Speak Again" button returns to speaking screen within 500ms
- [ ] If report JSON fails: retry up to 3 times, then show basic completion screen
- [ ] Report card is fully scrollable with no clipped content

---

## 17. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Groq changes free tier limits | Medium | High | Gemini fallback. BYOK means user has their own account — any limit changes affect them directly, not us. App remains functional if user upgrades to paid Groq tier. |
| Kokoro-82M Flutter integration complexity | Medium | Medium | Flutter TTS as temporary fallback during development. Kokoro integration via platform channel (Android native). Budget extra 1 week in milestone plan. |
| WebRTC VAD false triggers in noisy environments | Medium | Medium | Configurable silence threshold (default 500ms, user can increase). Push-to-talk always available as fallback. |
| Groq STT code-switching accuracy below expectations | Low | High | Test with real mixed-language samples early. Fallback: Groq allows `language` parameter — if accuracy suffers, detect dominant language and set explicitly. |
| Opus encoding adds unexpected latency on low-end Android | Low | Medium | Benchmark on Android 10 mid-range device. Fallback to raw audio if encoding exceeds 50ms. |
| User drops off during BYOK setup (key creation friction) | High | High | UX mitigation: visual guide, friendly copy, validation feedback. Track BYOK completion rate as a KPI. If < 50%, simplify the flow. |
| Groq + Gemini both down simultaneously | Very Low | High | Session cannot proceed. Show clear friendly error: "Your AI connection is temporarily unavailable. Try again in a few minutes." |
| Report card JSON returns malformed | Medium | Low | Retry 3x. Robust JSON extraction (strip markdown fences). Fallback to basic "session complete" screen with only XP total. |
| Firebase Firestore write fails after session | Low | Medium | Local XP cache. Retry writes with exponential backoff for up to 24 hours. |

---

## 18. Milestone Plan

### Milestone 1 — Foundation (Week 1–2)

- [ ] Flutter project initialized with Firebase (Auth + Firestore)
- [ ] Google OAuth working end-to-end
- [ ] Firestore user document created on first login
- [ ] flutter_secure_storage integrated and tested
- [ ] Basic navigation skeleton (Sign In → Onboarding → Home → Speak → Report)
- [ ] Design system implemented as Flutter ThemeData (colors, fonts, spacing)
- [ ] Fraunces + DM Sans + JetBrains Mono fonts loaded
- [ ] BYOK onboarding screens (UI only, no validation yet)

### Milestone 2 — Voice Core (Week 3–6)

- [ ] Groq API client (STT + LLM streaming) implemented
- [ ] Gemini API client implemented (fallback logic)
- [ ] WebRTC VAD integrated — always-on turn detection working
- [ ] Opus audio encoding before upload
- [ ] Full conversation loop working end-to-end (speak → transcribe → reply → speak)
- [ ] Sentence-boundary TTS trigger implemented
- [ ] Kokoro-82M TTS integrated (or flutter_tts as temporary placeholder)
- [ ] Push-to-talk mode working
- [ ] Real-time transcript display (token streaming → UI)
- [ ] Session timer accurate
- [ ] Network awareness check on session start
- [ ] Rolling 8-turn history management
- [ ] BYOK key validation (test Groq call on setup)
- [ ] Groq → Gemini fallback logic tested

### Milestone 3 — Report Card (Week 7–8)

- [ ] Session transcript capture (full session, both sides)
- [ ] Report generation via Groq (single call, JSON prompt)
- [ ] JSON parsing + error handling + retry logic
- [ ] Report Card UI complete (all sections per spec)
- [ ] XP calculation verified (cross-check LLM vs client-side)
- [ ] XP written to Firestore after session
- [ ] XP progress bar + level badge on home screen
- [ ] "Speak Again" flow

### Milestone 4 — Polish & QA (Week 9–10)

- [ ] All animations implemented (mic pulse, transcript fade, XP count-up, level-up burst)
- [ ] All error states handled (no network, key invalid, both providers down, permission denied)
- [ ] Latency benchmarking: measure P50/P95 on 3 Android devices across 4G + WiFi
- [ ] Transcript auto-save every 30 seconds
- [ ] Session recovery on network drop
- [ ] Tested on Android 10, 12, 14 (3 API levels minimum)
- [ ] BYOK completion funnel tracked in Firebase Analytics

### Milestone 5 — MVP Launch

- [ ] Firebase Analytics events for all key actions
- [ ] North Star Metric (Weekly Active Speaking Minutes) tracked
- [ ] APK signed and installable
- [ ] Play Store internal testing track published
- [ ] Beta group of 5–10 real users onboarded

---

## 19. Future Roadmap (Post-MVP)

### Phase 2 — Full Gamification

- XP deductions for poor sessions (penalties balanced with encouragement)
- Level-up curriculum gate: must demonstrate A1 topics before unlocking A2 content
- Daily streak tracking with streak recovery mechanic
- Weekly XP summary notification

### Phase 3 — Curriculum Integration

- Instituto Cervantes DELE documents parsed into topic/vocabulary/grammar databases
- AI tutor follows structured curriculum per level (not just free conversation)
- "Today's Topic" suggested based on current CEFR level gaps
- Progress map showing coverage of curriculum at current level

### Phase 4 — Listening Pillar

- Curated Spanish audio clips (authentic dialogues, podcasts, news)
- Comprehension questions after each clip
- Transcript with word-click definitions
- Listening XP tied to comprehension score

### Phase 5 — Reading Pillar

- Leveled reading texts (A1 → C2)
- Word-click inline dictionary (translation + example sentence)
- Reading speed tracking
- Reading XP tied to time and comprehension

### Phase 6 — Writing Pillar

- Writing prompts aligned to current CEFR level
- AI grammar correction with line-by-line explanations
- Writing score → XP
- Comparative improvement tracking across sessions

### Phase 7 — Social Features

- Global XP leaderboard
- Friends leaderboard (invite by code)
- Streak challenges (compete on consecutive days)
- Share report card to social media

### Phase 8 — Multi-Language Expansion

- French (DELF framework)
- German (Goethe Institut framework)
- Arabic (modern standard)
- Italian
- Each language: dedicated persona, curriculum documents, voice model

### Phase 9 — Platform Expansion

- iOS support
- Tablet-optimized layout
- Apple Watch companion (speaking streak notifications)

---

*End of PRD v0.3 — Lingua MVP*
*Architecture: Locked.*
*Next document: Sprint 1 Implementation Guide — Flutter Project Setup + Firebase + BYOK Onboarding*
