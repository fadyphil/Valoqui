# ADR-003: TTS Engine — On-Device sherpa-onnx Piper (Interim) → F5-TTS ONNX (Target)

**Date:** 2026-03
**Status:** Partially superseded — Piper is interim placeholder, F5-TTS ONNX
is the locked target (pending Sprint 3 export and benchmarking)
**Sprint:** Sprint 2 (Piper) / Sprint 3 (F5-TTS)
**Decider:** Fady

---

## Context

TTS is Valoqui's primary structural latency advantage over competitors.
The PRD target: TTS first sentence begins playing before the full LLM
response has arrived (sentence-boundary trigger). This requires:

- First-sentence generation latency ≤ 50–100ms on a mid-range Android device.
- Natural-sounding Castilian Spanish — robotic quality is a product-level
  failure given the app's "warm, intelligent" brand personality.
- Zero cloud roundtrip — any cloud TTS call adds ~300ms and a network
  dependency that eliminates the latency advantage.
- On-device, open-source, no developer cost.

---

## Decision

**Sprint 2 (interim):** `sherpa-onnx` with Piper `es_ES-sharvard-medium`
VITS model. Functional, on-device, correct language. Voice quality is
acceptable but not the target quality level.

**Sprint 3 (locked target):** F5-TTS fine-tuned Spanish checkpoint
(`jpgallegoar/F5-TTS`) exported to ONNX via `DakeQQ/F5-TTS-ONNX`.
Integrated via a new `F5TtsRepository` implementing the existing
`TtsRepository` interface. Swap requires one new datasource file and one
line in `service_locator.dart`.

---

## Alternatives considered

### Option A — Android native Google TTS

**Why considered:** Zero bundle size, always available, no integration work.
**Why rejected:** Robotic voice quality creates a poor UX that contradicts
the product brand. Quality gap vs. competitors like Pingo is audible.

### Option B — ElevenLabs / cloud TTS

**Why considered:** Best-in-class voice quality.
**Why rejected:** Paid API (developer cost), adds ~300ms cloud roundtrip per
sentence. Eliminates Valoqui's core latency advantage permanently.

### Option C — Kokoro-82M (original PRD spec)

**Why considered:** Natural voice, ~50ms latency, open source.
**Why rejected in Sprint 2:** Flutter platform channel integration complexity
was not yet scoped. Deferred. Piper via sherpa-onnx achieved the same goal
with a supported Flutter package.

### Option D — Piper via sherpa-onnx (chosen Sprint 2 interim)

**Why selected:** Supported Flutter package (`sherpa_onnx`), correct language
model available (`es_ES-sharvard-medium`), on-device, ARM-native, ~50ms
latency on mid-range hardware. Sufficient for Sprint 2 pipeline validation.

### Option E — F5-TTS jpgallegoar Spanish checkpoint (locked Sprint 3 target)

**Why selected as target:** Best available open-source Spanish TTS quality.
The jpgallegoar fine-tuned checkpoint specifically targets conversational
Castilian Spanish — aligns with Lucia's voice requirements.

**Key unknowns before committing:**

- Published RTF benchmarks (~91x CPU) suggest the full model is unviable
  without float16/INT8 quantization.
- Physical device ARM benchmarking on target hardware is required —
  published benchmarks do not account for thermal throttling, NNAPI
  variance, or Android version differences.
- ONNX export process via `DakeQQ/F5-TTS-ONNX` is undocumented for custom
  checkpoints. Colab export + benchmarking is the required validation step.

### Option F — Supertonic TTS

**Why considered:** Official ONNX SDK, Flutter support.
**Status:** Evaluation candidate. Check `huggingface.co/Supertone/supertonic`
for Spanish voice availability before Sprint 3 commitment.

### Option G — Piper fine-tuned custom Lucia voice

**Why considered:** Fully open training pipeline, ~50ms ARM latency preserved,
custom Castilian conversational training data possible.
**Status:** Deferred pending F5-TTS evaluation. Preferred fallback if F5-TTS
ONNX latency is unacceptable on physical hardware.

---

## Consequences

### Positive

- `TtsRepository` interface means the swap from Piper to F5-TTS touches
  exactly one datasource file. SpeakingBloc is unchanged.
- On-device TTS eliminates the cloud TTS roundtrip permanently — ~300ms
  structural latency advantage over cloud-TTS competitors.

### Negative / tradeoffs

- Sprint 2 ships with Piper voice quality, which is noticeably below the
  target quality level. This is a known, accepted interim state.
- F5-TTS ONNX export is new/undocumented territory. Float16 vs. INT8 tradeoff
  requires physical device measurement, not just published benchmarks.
- APK size increases significantly (Piper model: ~76.7MB). F5-TTS ONNX
  estimated 300–600MB depending on quantization. This may require
  on-demand download rather than bundling.

### Constraints introduced

- TTS output filename must be rotated across sentences (e.g.,
  `lucia_speech_0.wav`, `lucia_speech_1.wav`). Reusing the same filename
  causes `just_audio` to serve cached audio instead of newly generated audio.
- `maxNumSentences` in sherpa-onnx config must be set to a high value (e.g.,
  100). Setting it to 1 causes truncation at internal punctuation.

---

## Links

- PRD v0.3 § ADL-003 (TTS provider)
- Sprint 2 Guide § 4 (TTS model setup), § 6.2 `sherpa_tts_datasource.dart`
- HuggingFace: `csukuangfj/vits-piper-es_ES-sharvard-medium`
- HuggingFace: `jpgallegoar/F5-TTS` (target checkpoint)
- GitHub: `DakeQQ/F5-TTS-ONNX` (export pipeline)
