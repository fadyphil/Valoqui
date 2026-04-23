# STT Performance Analysis Report (Snapshot: April 2026)

## 1. Introduction

This report provides a mathematical breakdown of the Speech-to-Text (STT) pipeline performance on mid-range mobile hardware (Snapdragon 680 / Xiaomi Note 11). It isolates native inference latency from architectural overhead to determine the physical bottlenecks of the current implementation.

## 2. Mathematical Breakdown (Current State)

### 2.1 Metrics Definitions

* **Audio Duration ($T_{audio}$):** The length of the user's speech in seconds.
* **Decode Time ($T_{decode}$):** The time taken by the native C++ engine to perform neural network inference.
* **Real-Time Factor (RTF):** The primary metric for STT efficiency. $RTF = \frac{T_{decode}}{T_{audio}}$.
  * $RTF < 1.0$: Faster than real-time (Ideal).
  * $RTF = 1.0$: Real-time.
  * $RTF > 1.0$: Slower than real-time (Lag is perceived).
* **Pipeline Overhead ($T_{overhead}$):** Latency introduced by Dart Isolate message passing and BLoC state transitions.
* **Total Perceived Latency ($T_{total}$):** $T_{decode} + T_{overhead}$.

### 2.2 Empirical Data (Snapdragon 680)

Based on telemetry logs from the current Moonshine implementation:

| Sample | $T_{audio}$ | $T_{decode}$ | RTF | $T_{total}$ | $T_{overhead}$ |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Short** | 1.59s | 2.87s | **1.806** | 2.88s | 1ms |
| **Mid** | 2.62s | 3.78s | **1.444** | 3.98s | 200ms |
| **Long** | 3.51s | 5.93s | **1.688** | 5.93s | 0ms |

### 2.3 Analysis of the "Culprit"

The data shows that $T_{overhead}$ is negligible (~1ms to 200ms). The **95% contributor to latency is the RTF being > 1.0**.

On the Snapdragon 680, the CPU/DSP physically cannot execute the 61M parameters of the Moonshine Base model fast enough. For every second the user speaks, the device requires ~1.5 seconds of "thinking" time *after* the speech ends.

---

## 3. Physical Limitation vs. Implementation

* **Implementation:** Current use of XNNPACK and NNAPI has been exhausted. Threading is optimized to 2-4 performance cores.
* **Physical Constraint:** The Moonshine model architecture (Transformer-based) requires a fixed amount of Floating Point Operations (FLOPs). The Snapdragon 680's peak GFLOPS is lower than the model's demand for real-time offline processing.

## 4. Conclusion

The current "Offline" architecture creates a "wall of silence" where the user finishes speaking and must wait for $T_{audio} \times (RTF - 1)$ seconds. To achieve a responsive experience on mid-range hardware, we must either **reduce the model parameter count** (lower RTF) or **change the architecture to Online/Streaming** (hide RTF).
