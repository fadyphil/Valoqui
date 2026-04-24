# On-Device STT: Market Report & Future Alternatives (April 2026)

## 1. Executive Summary

To achieve near-instantaneous Speech-to-Text on mid-range hardware (Snapdragon 680), we must pivot from "Batch/Offline" models to "Streaming/Online" architectures. This report compares the bleeding-edge STT technologies available for mobile deployment as of today.

## 2. Comparison Matrix (Performance Targets on Snapdragon 680)

| Model | Type | Size | Params | RTF (Est) | UX Latency |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Moonshine Base** | Offline | 61MB | 61M | 1.50 | High |
| **Moonshine Tiny** | Offline | 27MB | 27M | 0.60 | Medium |
| **SenseVoice Small** | Offline | 240MB | 234M | 0.40 | Low |
| **Streaming Zipformer** | **Online** | 80MB | 60M | < 0.10 | **Instant** |
| **Whisper.cpp (Tiny)** | Offline | 75MB | 39M | 50.0+ | Unusable |

---

## 3. Deep Dives into Alternatives

### 3.1 Streaming Zipformer (The "Zero-Gap" Solution)

* **Architecture:** Online/Streaming. Processed in 100ms chunks with internal state memory.
* **Why it's faster:** It doesn't wait for silence. By the time the user finishes their sentence, the transcription is already 99% done.
* **Pros:** Truly instant UX; very robust to background noise.
* **Cons:** Requires managed state (Hidden State/Cell State) between chunks.

### 3.2 SenseVoice Small (The "Speed King")

* **Architecture:** Non-autoregressive Transformer.
* **Why it's faster:** Unlike Whisper or Moonshine, which predict tokens one-by-one (slow), SenseVoice predicts the entire sequence in a few parallel passes.
* **Pros:** Insanely fast for offline; includes emotion and event detection (e.g., "[laughter]", "[music]").
* **Cons:** Larger binary size (~240MB).

### 3.3 Moonshine Tiny (The "Surgical" Upgrade)

* **Architecture:** Same as current, but 2.5x fewer parameters.
* **Pros:** Drop-in replacement for current logic.
* **Cons:** Still "Offline"—long sentences will still have a 2-3 second delay.

### 3.4 Why NOT Whisper.cpp?

* **Benchmark:** On Android, `sherpa-onnx` (via XNNPACK) is documented as being **51x faster** than `whisper.cpp`.
* **Conclusion:** GGML/Llama.cpp based inference is not yet optimized for Android NPU/DSP paths compared to ONNX Runtime.

---

## 4. Final Recommendations

### Recommendation A: The UX Pivot (Highest Priority)

**Switch to Streaming Zipformer.**
This is the only path that provides a "Magic" feeling where Lucia responds immediately. The Snapdragon 680 can easily handle 100ms chunks of a 60M parameter Zipformer in real-time.

### Recommendation B: The Fast-Offline Path

**Switch to SenseVoice Small (int8).**
If we must stay with an offline "wait-for-silence" flow, SenseVoice provides the best accuracy-to-speed ratio in the industry as of early 2026.

---

## 5. Next Steps

1. Download `sherpa-onnx-streaming-zipformer-en-2023-06-26` (or Spanish variant).
2. Refactor `SherpaSttDatasource` to use `OnlineRecognizer`.
3. Implement state-passing for continuous audio stream processing.
