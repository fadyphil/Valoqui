// lib/features/speaking/widgets/mic_button.dart
//
// Fix: converted to StatefulWidget with _isPressed state.
// Previously in always-on mode the button had zero gesture handlers
// (onTap was null, onTapDown/Up were gated to PTT only) so touching
// it did nothing. Now press feedback works in every mode.

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:valoqui/core/theme/app_colors.dart";
import "package:valoqui/core/theme/app_spacing.dart";
import "package:valoqui/core/theme/app_typography.dart";
import "package:valoqui/features/speaking/bloc/speaking_bloc.dart";

class MicButton extends StatefulWidget {
  final ConversationPhase phase;
  final MicMode micMode;
  final double bufferFillPercentage;
  final VoidCallback? onPressDown;
  final VoidCallback? onPressUp;

  const MicButton({
    super.key,
    required this.phase,
    required this.micMode,
    this.bufferFillPercentage = 0.0,
    this.onPressDown,
    this.onPressUp,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> {
  bool _isPressed = false;

  void _handleDown() {
    setState(() => _isPressed = true);
    if (widget.micMode == MicMode.pushToTalk) {
      widget.onPressDown?.call();
    }
  }

  void _handleUp() {
    setState(() => _isPressed = false);
    if (widget.micMode == MicMode.pushToTalk) {
      widget.onPressUp?.call();
    }
  }

  void _handleCancel() {
    setState(() => _isPressed = false);
    if (widget.micMode == MicMode.pushToTalk) {
      widget.onPressUp?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.phase == ConversationPhase.listening;
    final isSpeaking = widget.phase == ConversationPhase.speaking;

    return GestureDetector(
      onTapDown: (_) => _handleDown(),
      onTapUp: (_) => _handleUp(),
      onTapCancel: _handleCancel,
      child: SizedBox(
        width: 196,
        height: 196,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Pulsing outer ring (listening only) ──────
            if (isListening) const _PulseRing(),

            // ── Halo border ──────────────────────────────
            Container(
              width: 188,
              height: 188,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentPrimary.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
            ),

            // ── Main button circle ────────────────────────
            AnimatedScale(
              scale: _isPressed ? 0.93 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Buffer Limit Indicator (PTT only) ─────────
                  if (widget.micMode == MicMode.pushToTalk &&
                      widget.bufferFillPercentage > 0.1)
                    SizedBox(
                      width: 108,
                      height: 108,
                      child: CircularProgressIndicator(
                        value: widget.bufferFillPercentage,
                        strokeWidth: 3,
                        backgroundColor: Colors.transparent,
                        color: Color.lerp(
                          AppColors.accentPrimary,
                          AppColors.error,
                          widget.bufferFillPercentage,
                        ),
                      ),
                    ).animate().fadeIn(),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSpeaking ? null : AppColors.micButtonGradient,
                      color: isSpeaking ? AppColors.bgElevated : null,
                      boxShadow: isListening
                          ? [
                              BoxShadow(
                                color: _isPressed
                                    ? AppColors.micGlow.withValues(alpha: 0.6)
                                    : AppColors.micGlow,
                                blurRadius: _isPressed ? 56 : 40,
                                spreadRadius: _isPressed ? 12 : 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.mic_rounded,
                      color: isSpeaking ? AppColors.textSecondary : Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),

            // ── PTT label overlay ─────────────────────────
            if (widget.micMode == MicMode.pushToTalk)
              Positioned(
                bottom: 12,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _isPressed ? 1.0 : 0.5,
                  child: Text(
                    _isPressed ? "RECORDING" : "HOLD TO SPEAK",
                    style: TextStyle(
                      fontFamily: "DMSans",
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _isPressed
                          ? AppColors.accentPrimary
                          : AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Expanding ring that fades out — runs on a 1.5s loop.
class _PulseRing extends StatelessWidget {
  const _PulseRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accentPrimary.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.5, 1.5),
          duration: 2000.ms,
          curve: Curves.easeOut,
        )
        .fadeOut(duration: 2000.ms);
  }
}

class MicModeToggle extends StatelessWidget {
  final MicMode micMode;
  final VoidCallback onToggle;

  const MicModeToggle({
    super.key,
    required this.micMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isAlwaysOn = micMode == MicMode.alwaysOn;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAlwaysOn ? Icons.auto_awesome : Icons.back_hand_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              isAlwaysOn ? "Always-on" : "Push-to-talk",
              style: AppTypography.bodyMD.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
