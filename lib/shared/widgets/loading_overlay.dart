// lib/shared/widgets/loading_overlay.dart

import "package:flutter/material.dart";
import 'package:valoqui/core/theme/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bgPrimary.withValues(alpha: 0.7),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.accentPrimary),
      ),
    );
  }
}
