// lib/features/speaking/widgets/mic_button.dart
//
// Vanguard_UI_Architect Refinement: Premium "Double-Bezel" Architecture
// Implements haptic depth, cinematic spatial rhythm, and fluid motion.

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
  final bool isTranscribing;
  final VoidCallback? onPressDown;
  final VoidCallback? onPressUp;

  const MicButton({
    super.key,
    required this.phase,
    required this.micMode,
    this.bufferFillPercentage = 0.0,
    this.isTranscribing = false,
    this.onPressDown,
    this.onPressUp,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> {
  bool _isPressed = false;

  void _handleDown() {
    if (widget.isTranscribing) return;
    setState(() => _isPressed = true);
    if (widget.micMode == MicMode.pushToTalk) {
      widget.onPressDown?.call();
    }
  }

  void _handleUp() {
    if (widget.isTranscribing) return;
    setState(() => _isPressed = false);
    if (widget.micMode == MicMode.pushToTalk) {
      widget.onPressUp?.call();
    }
  }

  void _handleCancel() {
    if (widget.isTranscribing) return;
    setState(() => _isPressed = false);
    if (widget.micMode == MicMode.pushToTalk) {
      widget.onPressUp?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.phase == ConversationPhase.listening;
    final isSpeaking = widget.phase == ConversationPhase.speaking;
    final isDisabled =
        widget.isTranscribing || widget.phase != ConversationPhase.listening;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _handleDown(),
      onTapUp: isDisabled ? null : (_) => _handleUp(),
      onTapCancel: isDisabled ? null : _handleCancel,
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
        child: SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Ethereal Pulse Rings (Raindrop Effect) ──
              if (isListening && !isDisabled) ...[
                const _PulseRing(delay: 0),
                const _PulseRing(delay: 600),
                const _PulseRing(delay: 1200),
              ],

              // ── Outer "Machined" Bezel ──────────────────
              Container(
                width: 196,
                height: 196,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentPrimary.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
              ),

              // ── Inset "Tray" (Depth Layer) ──────────────
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgPrimary.withValues(alpha: 0.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),

              // ── Main button core ────────────────────────
              AnimatedScale(
                scale: _isPressed ? 0.92 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: const Cubic(0.32, 0.72, 0, 1),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ── Buffer Limit Ring (High Precision) ─────
                    if (widget.micMode == MicMode.pushToTalk &&
                        widget.bufferFillPercentage > 0.01 &&
                        !isDisabled)
                      SizedBox(
                        width: 116,
                        height: 116,
                        child: CircularProgressIndicator(
                          value: widget.bufferFillPercentage,
                          strokeWidth: 2.5,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          color: Color.lerp(
                            AppColors.accentPrimary,
                            AppColors.error,
                            widget.bufferFillPercentage,
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms),

                    // ── The Interactive Island ────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: const Cubic(0.32, 0.72, 0, 1),
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: (isSpeaking || isDisabled)
                            ? null
                            : AppColors.micButtonGradient,
                        color: (isSpeaking || isDisabled)
                            ? AppColors.bgElevated
                            : null,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 0.5,
                        ),
                        boxShadow: (isListening && !isDisabled)
                            ? [
                                BoxShadow(
                                  color: AppColors.accentPrimary.withValues(
                                    alpha: _isPressed ? 0.5 : 0.35,
                                  ),
                                  blurRadius: _isPressed ? 64 : 48,
                                  spreadRadius: _isPressed ? 8 : 4,
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  blurRadius: 0,
                                  offset: const Offset(0, -1),
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child:
                          Icon(
                                isDisabled
                                    ? Icons.hourglass_empty_rounded
                                    : (isListening
                                          ? Icons.mic_rounded
                                          : Icons.graphic_eq_rounded),
                                color: (isSpeaking || isDisabled)
                                    ? AppColors.textSecondary
                                    : Colors.white,
                                size: 38,
                              )
                              .animate(target: _isPressed ? 1 : 0)
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(0.9, 0.9),
                                duration: 200.ms,
                              ),
                    ),
                  ],
                ),
              ),

              // ── Dynamic Label ───────────────────────────
              if (widget.micMode == MicMode.pushToTalk)
                Positioned(
                  bottom: 16,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: isDisabled ? 0.0 : (_isPressed ? 1.0 : 0.4),
                    child: Text(
                      _isPressed ? "RECORDING" : "HOLD TO SPEAK",
                      style: TextStyle(
                        fontFamily: "DMSans",
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _isPressed
                            ? AppColors.accentPrimary
                            : AppColors.textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ethereal expanding ring that fades out.
class _PulseRing extends StatelessWidget {
  final int delay;
  const _PulseRing({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentPrimary.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.6, 1.6),
          duration: 2400.ms,
          curve: const Cubic(0.2, 0.4, 0, 1),
          delay: delay.ms,
        )
        .fadeOut(duration: 2400.ms, delay: delay.ms);
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
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isAlwaysOn
                ? AppColors.accentPrimary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
          boxShadow: isAlwaysOn
              ? [
                  BoxShadow(
                    color: AppColors.accentPrimary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAlwaysOn ? Icons.auto_awesome : Icons.back_hand_rounded,
              size: 14,
              color: isAlwaysOn
                  ? AppColors.accentPrimary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              isAlwaysOn ? "Always-on" : "Push-to-talk",
              style: AppTypography.bodyMD.copyWith(
                color: isAlwaysOn
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
