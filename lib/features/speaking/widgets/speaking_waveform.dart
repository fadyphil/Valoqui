// lib/features/speaking/widgets/speaking_waveform.dart
//
// Animated waveform bar strip shown in the bottom panel of the speaking screen.
// Always visible; animation style changes per conversation phase.
// Reacts to real microphone amplitude when an amplitudeStream is provided.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:valoqui/core/theme/app_colors.dart';
import 'package:valoqui/features/speaking/bloc/speaking_bloc.dart';

class SpeakingWaveform extends StatefulWidget {
  final ConversationPhase phase;

  /// Normalized 0.0–1.0 amplitude from mic input (from SttRepository).
  /// When null or 0 the waveform uses auto-animation only.
  final Stream<double>? amplitudeStream;

  const SpeakingWaveform({
    super.key,
    required this.phase,
    this.amplitudeStream,
  });

  @override
  State<SpeakingWaveform> createState() => _SpeakingWaveformState();
}

class _SpeakingWaveformState extends State<SpeakingWaveform>
    with SingleTickerProviderStateMixin {
  // Single controller drives the time-base for all bars.
  // 1800 ms ≈ one full sine cycle feels organic — not too fast, not sluggish.
  late final AnimationController _ticker;

  StreamSubscription<double>? _ampSub;
  double _amplitude = 0.0;

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
    _subscribeAmplitude();
  }

  void _subscribeAmplitude() {
    _ampSub = widget.amplitudeStream?.listen((v) {
      if (mounted) setState(() => _amplitude = v.clamp(0.0, 1.0));
    });
  }

  @override
  void didUpdateWidget(covariant SpeakingWaveform old) {
    super.didUpdateWidget(old);

    // Re-subscribe if a new stream is provided
    if (old.amplitudeStream != widget.amplitudeStream) {
      _ampSub?.cancel();
      _subscribeAmplitude();
    }

    // Decay amplitude instantly when we leave the listening phase
    if (old.phase != widget.phase &&
        widget.phase != ConversationPhase.listening) {
      setState(() => _amplitude = 0.0);
    }
  }

  @override
  void dispose() {
    _ampSub?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  // ── Per-bar height calculation ─────────────────────────────────────────────

  double _barHeight(int i, double t) {
    // Per-bar phase offset creates independent wave character for each bar
    final offset = (i / _barCount) * 2 * pi;

    switch (widget.phase) {
      case ConversationPhase.speaking:
        // Rich dual-frequency animation while TTS plays — looks like real speech
        final w1 = sin(t * 2 * pi * 1.0 + offset);
        final w2 = sin(t * 2 * pi * 1.65 + offset * 1.3);
        final combined = (w1 * 0.65 + w2 * 0.35) * 0.5 + 0.5;
        return _minH + combined * (_maxH - _minH);

      case ConversationPhase.listening:
        if (_amplitude < 0.03) {
          // Near-silence: very gentle idle ripple so bars don't look frozen
          final idle = sin(t * 2 * pi * 0.55 + offset) * 0.5 + 0.5;
          return _minH + idle * 5.0;
        }
        // Active speech: amplitude sets the ceiling, wave adds organic variation
        final sine = sin(t * 2 * pi * 1.45 + offset);
        final amp =
            0.2 + _amplitude * 0.8; // floor at 20% so bars never flatten
        return _minH + (sine * 0.5 + 0.5) * (_maxH - _minH) * amp;

      case ConversationPhase.processing:
        // Very subtle low-energy pulse — "thinking" should feel calm
        final idle = sin(t * 2 * pi * 0.45 + offset) * 0.5 + 0.5;
        return _minH + idle * 3.5;
    }
  }

  // ── Dynamic colour ─────────────────────────────────────────────────────────

  Color get _barColor {
    switch (widget.phase) {
      case ConversationPhase.speaking:
        return AppColors.accentSecondary;

      case ConversationPhase.listening:
        // Smoothly blend toward amber as the user's voice gets louder
        if (_amplitude > 0.25) {
          final t = ((_amplitude - 0.25) / 0.75).clamp(0.0, 1.0);
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

  // ── Label copy & colour ────────────────────────────────────────────────────

  String get _label {
    switch (widget.phase) {
      case ConversationPhase.speaking:
        return 'SPEAKING';
      case ConversationPhase.listening:
        return 'LISTENING';
      case ConversationPhase.processing:
        return 'THINKING';
    }
  }

  Color get _labelColor {
    switch (widget.phase) {
      case ConversationPhase.speaking:
        return AppColors.accentSecondary;
      case ConversationPhase.listening:
        return _amplitude > 0.1
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
          // Left label — fixed width so bars always start at the same x position
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _labelColor,
              letterSpacing: 1.4,
            ),
            child: SizedBox(width: 58, child: Text(_label)),
          ),
          const SizedBox(width: 10),

          // Waveform bars
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
