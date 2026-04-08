// lib/features/report/widgets/mistake_card.dart

import "package:flutter/material.dart";
import "package:valoqui/core/domain/models/session_report.dart";
import "package:valoqui/core/theme/app_colors.dart";
import "package:valoqui/core/theme/app_spacing.dart";
import "package:valoqui/core/theme/app_typography.dart";

class MistakeCard extends StatelessWidget {
  final MistakeItem mistake;

  const MistakeCard({super.key, required this.mistake});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // What the user said — crossed out in red
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("❌", style: TextStyle(fontSize: 14)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  mistake.whatUserSaid,
                  style: AppTypography.bodyMD.copyWith(
                    color: AppColors.error,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.error,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Correction — green
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("✅", style: TextStyle(fontSize: 14)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  mistake.correction,
                  style: AppTypography.bodyMD.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Explanation
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("📌", style: TextStyle(fontSize: 13)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    mistake.explanation,
                    style: AppTypography.bodyMD.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
