// lib/shared/widgets/onboarding_progress_dots.dart

import "package:flutter/material.dart";
import "../../core/theme/app_colors.dart";
import "../../core/theme/app_spacing.dart";

class OnboardingProgressDots extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgressDots({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (i) {
        final active = i + 1 == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.accentPrimary : AppColors.bgElevated,
            borderRadius: BorderRadius.circular(AppRadius.circle),
          ),
        );
      }),
    );
  }
}
