// lib/features/onboarding/screens/level_selection_screen.dart
//
// Change from previous version:
// SaveSelectedLevel(level: level, uid: uid) → SubmitLevel(level: level, uid: uid)

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:valoqui/features/auth/bloc/auth_bloc.dart";
import "package:valoqui/features/onboarding/bloc/onboarding_bloc.dart";
import "../../../../core/theme/app_colors.dart";
import "../../../../core/theme/app_typography.dart";
import "../../../../core/theme/app_spacing.dart";
import "../../../../shared/widgets/onboarding_progress_dots.dart";
import "../../../../shared/widgets/loading_overlay.dart";

class _LevelOption {
  final String code;
  final String title;
  final String subtitle;
  const _LevelOption({
    required this.code,
    required this.title,
    required this.subtitle,
  });
}

const _levels = [
  _LevelOption(
    code: "A1",
    title: "Complete Beginner",
    subtitle: "I'm just starting out",
  ),
  _LevelOption(code: "A2", title: "Elementary", subtitle: "I know some basics"),
  _LevelOption(
    code: "B1",
    title: "Intermediate",
    subtitle: "I can have simple conversations",
  ),
  _LevelOption(
    code: "B2",
    title: "Upper Intermediate",
    subtitle: "I'm fairly comfortable",
  ),
  _LevelOption(
    code: "C1",
    title: "Advanced",
    subtitle: "I speak well but want to refine",
  ),
  _LevelOption(code: "C2", title: "Mastery", subtitle: "I'm nearly fluent"),
  _LevelOption(
    code: "?",
    title: "Not sure yet",
    subtitle: "We'll figure it out together",
  ),
];

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  String? _selectedLevel;

  void _onContinue(BuildContext context, String uid) {
    if (_selectedLevel == null) return;
    context.read<OnboardingBloc>().add(
      SubmitLevel(level: _selectedLevel!, uid: uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final uid = (authState as AuthAuthenticated).user.uid;

    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (_, curr) => curr is OnboardingError,
      listener: (context, state) {
        state.maybeWhen(
          error: (message) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.error),
          ),
          orElse: () {},
        );
      },
      builder: (context, state) {
        final isLoading = state is OnboardingLoading;
        final canContinue = _selectedLevel != null && !isLoading;

        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.bgPrimary,
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pagePaddingH,
                        vertical: AppSpacing.pagePaddingV,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          const Center(
                            child: OnboardingProgressDots(
                              currentStep: 4,
                              totalSteps: 4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x3l),
                          Text(
                            "What's your current\nSpanish level?",
                            style: AppTypography.headingLG,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            "Lucia will adapt to where you are right now.",
                            style: AppTypography.bodyMD.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pagePaddingH,
                        ),
                        itemCount: _levels.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final level = _levels[index];
                          return _LevelTile(
                            level: level,
                            selected: _selectedLevel == level.code,
                            onTap: () =>
                                setState(() => _selectedLevel = level.code),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePaddingH,
                        AppSpacing.lg,
                        AppSpacing.pagePaddingH,
                        AppSpacing.xl,
                      ),
                      child: _ContinueButton(
                        enabled: canContinue,
                        onTap: () => _onContinue(context, uid),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isLoading) const LoadingOverlay(),
          ],
        );
      },
    );
  }
}

class _LevelTile extends StatelessWidget {
  final _LevelOption level;
  final bool selected;
  final VoidCallback onTap;

  const _LevelTile({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnknown = level.code == "?";
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentPrimary.withValues(alpha: 0.08)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected ? AppColors.accentPrimary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppColors.accentPrimary
                    : AppColors.bgElevated,
              ),
              child: Center(
                child: isUnknown
                    ? Icon(
                        Icons.help_outline_rounded,
                        size: 20,
                        color: selected
                            ? AppColors.bgPrimary
                            : AppColors.textSecondary,
                      )
                    : Text(
                        level.code,
                        style: AppTypography.labelMD.copyWith(
                          color: selected
                              ? AppColors.bgPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.title,
                    style: AppTypography.labelMD.copyWith(
                      color: selected
                          ? AppColors.accentPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    level.subtitle,
                    style: AppTypography.bodyMD.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.accentPrimary,
                      size: 22,
                      key: ValueKey("check"),
                    )
                  : const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                      size: 22,
                      key: ValueKey("chevron"),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _ContinueButton({required this.enabled, required this.onTap});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: widget.enabled
          ? () => setState(() => _pressed = false)
          : null,
      child: AnimatedOpacity(
        opacity: widget.enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: widget.enabled
                  ? AppColors.micButtonGradient
                  : const LinearGradient(
                      colors: [AppColors.bgElevated, AppColors.bgElevated],
                    ),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Center(
              child: Text(
                "Let's Start →",
                style: AppTypography.labelLG.copyWith(
                  color: widget.enabled
                      ? AppColors.bgPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
