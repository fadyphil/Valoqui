// lib/features/speaking/widgets/speaking_waveform.dart
//
// Animated waveform bar strip shown in the bottom panel of the speaking screen.
// Always visible; animation style changes per conversation phase.
// Reacts to real microphone amplitude passed directly as a double from
// SpeakingActive.amplitude (pushed through the BLoC state via _AmplitudeChanged).

import "dart:math";
import "package:flutter/material.dart";
import "package:valoqui/core/theme/app_colors.dart";
import "package:valoqui/features/speaking/bloc/speaking_bloc.dart";

class SpeakingWaveform extends StatefulWidget {
  final ConversationPhase phase;

  /// Normalized 0.0–1.0 amplitude from the BLoC state.
  /// Defaults to 0 when the mic is inactive.
  final double amplitudeStream;

  const SpeakingWaveform({
    super.key,
    required this.phase,
    this.amplitudeStream = 0.0,
  });

  @override
  State<SpeakingWaveform> createState() => _SpeakingWaveformState();
}

class _SpeakingWaveformState extends State<SpeakingWaveform>
    with SingleTickerProviderStateMixin {
  // Single controller drives the time-base for all bars.
  // 1800 ms ≈ one full sine cycle — organic, not jittery.
  late final AnimationController _ticker;

  static const _barCount = 32;
  static const _maxH = 34.0;
  static const _minH = 3.0;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── Per-bar height ─────────────────────────────────────────────────────────

  double _barHeight(int i, double t) {
    final offset = (i / _barCount) * 2 * pi;
    final amplitude = widget.amplitudeStream.clamp(0.0, 1.0);

    switch (widget.phase) {
      case ConversationPhase.speaking:
        final w1 = sin(t * 2 * pi * 1.0 + offset);
        final w2 = sin(t * 2 * pi * 1.65 + offset * 1.3);
        final combined = (w1 * 0.65 + w2 * 0.35) * 0.5 + 0.5;
        return _minH + combined * (_maxH - _minH);

      case ConversationPhase.listening:
        if (amplitude < 0.03) {
          final idle = sin(t * 2 * pi * 0.55 + offset) * 0.5 + 0.5;
          return _minH + idle * 5.0;
        }
        final sine = sin(t * 2 * pi * 1.45 + offset);
        final amp = 0.2 + amplitude * 0.8;
        return _minH + (sine * 0.5 + 0.5) * (_maxH - _minH) * amp;

      case ConversationPhase.processing:
        final idle = sin(t * 2 * pi * 0.45 + offset) * 0.5 + 0.5;
        return _minH + idle * 3.5;
    }
  }

  // ── Dynamic colour ─────────────────────────────────────────────────────────

  Color get _barColor {
    final amplitude = widget.amplitudeStream.clamp(0.0, 1.0);
    switch (widget.phase) {
      case ConversationPhase.speaking:
        return AppColors.accentSecondary;

      case ConversationPhase.listening:
        if (amplitude > 0.25) {
          final t = ((amplitude - 0.25) / 0.75).clamp(0.0, 1.0);
          return Color.lerp(
            AppColors.accentSecondary,
            AppColors.accentPrimary,
            t,
          )!;
        }
        return AppColors.accentSecondary;

      case ConversationPhase.processing:
        return AppColors.textSecondary.withValues(alpha: 0.45);
    }
  }

  // ── Label ──────────────────────────────────────────────────────────────────

  String get _label {
    switch (widget.phase) {
      case ConversationPhase.speaking:
        return "SPEAKING";
      case ConversationPhase.listening:
        return "LISTENING";
      case ConversationPhase.processing:
        return "THINKING";
    }
  }

  Color get _labelColor {
    final amplitude = widget.amplitudeStream.clamp(0.0, 1.0);
    switch (widget.phase) {
      case ConversationPhase.speaking:
        return AppColors.accentSecondary;
      case ConversationPhase.listening:
        return amplitude > 0.1
            ? AppColors.textSecondary
            : AppColors.textSecondary.withValues(alpha: 0.55);
      case ConversationPhase.processing:
        return AppColors.textSecondary.withValues(alpha: 0.35);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: AppColors.bgSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontFamily: "DMSans",
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _labelColor,
              letterSpacing: 1.4,
            ),
            child: SizedBox(width: 58, child: Text(_label)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedBuilder(
              animation: _ticker,
              builder: (context, _) {
                final color = _barColor;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_barCount, (i) {
                    final h = _barHeight(i, _ticker.value);
                    return Container(
                      width: 3,
                      height: h,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
