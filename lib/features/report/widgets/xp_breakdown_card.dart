// lib/features/report/widgets/xp_breakdown_card.dart

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:valoqui/core/domain/models/app_user.dart";
import "package:valoqui/core/domain/models/session_report.dart";
import "package:valoqui/core/theme/app_colors.dart";
import "package:valoqui/core/theme/app_spacing.dart";
import "package:valoqui/core/theme/app_typography.dart";

class XpBreakdownCard extends StatelessWidget {
  final XpBreakdown xp;
  final AppUser profile;

  const XpBreakdownCard({super.key, required this.xp, required this.profile});

  @override
  Widget build(BuildContext context) {
    final newXp = profile.currentXP + xp.totalXp;
    final nextLevelXp = AppUser.xpNextLevel(profile.currentCefrLevel);
    final currentLevelXp = AppUser.xpForLevel(profile.currentCefrLevel);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("XP EARNED", style: AppTypography.labelSM),
          const SizedBox(height: AppSpacing.lg),

          // XP rows
          _XpRow(icon: "⏱", label: "Time Speaking", xp: xp.timeSpeakingXp),
          _XpRow(icon: "🗣", label: "Spanish Words", xp: xp.spanishWordsXp),
          _XpRow(icon: "📐", label: "Grammar Bonus", xp: xp.grammarBonusXp),
          _XpRow(
            icon: "📚",
            label: "Vocabulary Range",
            xp: xp.vocabularyBonusXp,
          ),
          _XpRow(
            icon: "✅",
            label: "Session Complete",
            xp: xp.sessionCompletionXp,
          ),
          _XpRow(
            icon: "🌅",
            label: "First Session Today",
            xp: xp.firstSessionTodayXp,
          ),

          const Divider(color: AppColors.border, height: AppSpacing.xl),

          // Total XP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("🏆  TOTAL", style: AppTypography.labelLG),
              Text(
                "+${xp.totalXp} XP",
                style: AppTypography.labelLG.copyWith(
                  color: AppColors.accentPrimary,
                ),
              ).animate().shimmer(
                duration: 1200.ms,
                color: AppColors.accentPrimary.withValues(alpha: 0.3),
                delay: 400.ms,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // XP progress bar — shows progress within current level
          _XpProgressBar(
            currentXP: newXp - currentLevelXp,
            maxXP: nextLevelXp - currentLevelXp,
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            "$newXp XP  ·  Level ${profile.currentCefrLevel}",
            style: AppTypography.labelSM,
          ),
        ],
      ),
    );
  }
}

class _XpRow extends StatelessWidget {
  final String icon;
  final String label;
  final int xp;

  const _XpRow({required this.icon, required this.label, required this.xp});

  @override
  Widget build(BuildContext context) {
    if (xp == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: AppTypography.bodyMD),
            ],
          ),
          Text(
            "+$xp XP",
            style: AppTypography.bodyMD.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

// Inlined progress bar — keeps xp_breakdown_card.dart self-contained
// and avoids a dependency on the Sprint 1 shared widget signature.
class _XpProgressBar extends StatelessWidget {
  final int currentXP;
  final int maxXP;

  const _XpProgressBar({required this.currentXP, required this.maxXP});

  @override
  Widget build(BuildContext context) {
    final progress = maxXP > 0 ? (currentXP / maxXP).clamp(0.0, 1.0) : 0.0;

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(999),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.xpBarGradient,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
