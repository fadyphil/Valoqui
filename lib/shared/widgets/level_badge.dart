// lib/shared/widgets/level_badge.dart

import "package:flutter/material.dart";
import "../../core/theme/app_colors.dart";
import "../../core/theme/app_typography.dart";
import "../../core/theme/app_spacing.dart";

class LevelBadge extends StatelessWidget {
  final String level;
  const LevelBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.micButtonGradient,
        borderRadius: BorderRadius.circular(AppRadius.circle),
      ),
      child: Text(
        level,
        style: AppTypography.labelMD.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
