// lib/features/speaking/widgets/speaking_waveform.dart
//
// Animated waveform strip shown while TTS is playing Lucia's response.
// Hidden during listening and processing phases.

import "dart:math";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:valoqui/core/theme/app_colors.dart";

class SpeakingWaveform extends StatelessWidget {
  final bool isVisible;

  const SpeakingWaveform({super.key, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(20, (i) => _WaveBar(index: i)),
      ),
    );
  }
}

class _WaveBar extends StatelessWidget {
  final int index;
  static final _rng = Random(42); // fixed seed for deterministic heights

  const _WaveBar({required this.index});

  @override
  Widget build(BuildContext context) {
    final baseHeight = 8.0 + _rng.nextDouble() * 24;
    final delay = (index * 60).ms;

    return Container(
          width: 3,
          height: baseHeight,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: AppColors.accentSecondary.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        )
        .animate(
          delay: delay,
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .scaleY(
          begin: 0.3,
          end: 1.0,
          duration: 600.ms,
          curve: Curves.easeInOut,
        );
  }
}
