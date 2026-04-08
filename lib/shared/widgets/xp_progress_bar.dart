// lib/shared/widgets/xp_progress_bar.dart

import "package:flutter/material.dart";
import 'package:valoqui/core/theme/app_colors.dart';
import 'package:valoqui/core/theme/app_spacing.dart';

class XPProgressBar extends StatelessWidget {
  final double progress;

  const XPProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppRadius.circle),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                height: 8,
                decoration: BoxDecoration(
                  gradient: AppColors.xpBarGradient,
                  borderRadius: BorderRadius.circular(AppRadius.circle),
                  boxShadow: progress > 0
                      ? [
                          BoxShadow(
                            color: AppColors.accentPrimary.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
