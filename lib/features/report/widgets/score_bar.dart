// lib/features/report/widgets/score_bar.dart

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:valoqui/core/theme/app_colors.dart";
import "package:valoqui/core/theme/app_spacing.dart";
import "package:valoqui/core/theme/app_typography.dart";

class ScoreBar extends StatelessWidget {
  final String label;
  final int score; // 0–100

  const ScoreBar({super.key, required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    final fraction = (score / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          // Label
          SizedBox(width: 96, child: Text(label, style: AppTypography.labelMD)),
          // Bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.xs),
              child: Container(
                height: 8,
                color: AppColors.border,
                child:
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraction,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.accentPrimary,
                              AppColors.success,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                        ),
                      ),
                    ).animate().scaleX(
                      begin: 0,
                      end: 1,
                      duration: 800.ms,
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.centerLeft,
                    ),
              ),
            ),
          ),
          // Numeric score
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 32,
            child: Text(
              "$score",
              style: AppTypography.labelMD.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
