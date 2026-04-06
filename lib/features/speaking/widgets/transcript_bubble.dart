// lib/features/speaking/widgets/transcript_bubble.dart

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:valoqui/core/domain/models/conversation_message.dart";
import "package:valoqui/core/theme/app_colors.dart";
import "package:valoqui/core/theme/app_spacing.dart";
import "package:valoqui/core/theme/app_typography.dart";

class TranscriptBubble extends StatelessWidget {
  final ConversationMessage message;

  /// When true, renders a pulsing cursor at the end of the text to
  /// indicate that tokens are still streaming in.
  final bool isStreaming;

  const TranscriptBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
          padding: EdgeInsets.only(
            left: message.isAssistant ? 0 : AppSpacing.x3l,
            right: message.isUser ? 0 : AppSpacing.x3l,
            bottom: AppSpacing.sm,
          ),
          child: Align(
            alignment: message.isUser
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: message.isAssistant
                ? _LuciaBubble(message: message, isStreaming: isStreaming)
                : _UserBubble(message: message),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.08, end: 0, duration: 200.ms, curve: Curves.easeOut);
  }
}

// ── Lucia bubble — left aligned, blue gradient, flat bottom-left ──────

class _LuciaBubble extends StatelessWidget {
  final ConversationMessage message;
  final bool isStreaming;

  const _LuciaBubble({required this.message, required this.isStreaming});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.luciaBubbleGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(4), // flat corner pointing left
        ),
        border: const Border(
          left: BorderSide(color: AppColors.accentSecondary, width: 3),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Lucia",
            style: AppTypography.labelSM.copyWith(
              color: AppColors.accentSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: message.content,
                  style: AppTypography.transcript,
                ),
                if (isStreaming) WidgetSpan(child: _StreamingCursor()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── User bubble — right aligned, elevated, flat bottom-right ──────────

class _UserBubble extends StatelessWidget {
  final ConversationMessage message;

  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(4), // flat corner pointing right
        ),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            "You",
            style: AppTypography.labelSM.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(message.content, style: AppTypography.transcript),
        ],
      ),
    );
  }
}

// ── Streaming cursor — blinking "|" while tokens arrive ────────────────

class _StreamingCursor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
          "▋",
          style: AppTypography.transcript.copyWith(
            color: AppColors.accentSecondary,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(duration: 500.ms)
        .then()
        .fadeOut(duration: 500.ms);
  }
}
