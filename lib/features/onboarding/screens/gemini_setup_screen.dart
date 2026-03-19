// lib/features/onboarding/screens/gemini_setup_screen.dart
//
// Changes from previous version:
// SaveGeminiKey → SubmitGeminiKey
// SkipGeminiStep → SkipGeminiKey

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:url_launcher/url_launcher.dart";
import "package:valoqui/features/auth/bloc/auth_bloc.dart";
import "package:valoqui/features/onboarding/bloc/onboarding_bloc.dart";
import "../../../../core/theme/app_colors.dart";
import "../../../../core/theme/app_typography.dart";
import "../../../../core/theme/app_spacing.dart";
import "../../../../shared/widgets/onboarding_progress_dots.dart";
import "../../../../shared/widgets/loading_overlay.dart";

class GeminiSetupScreen extends StatefulWidget {
  const GeminiSetupScreen({super.key});

  @override
  State<GeminiSetupScreen> createState() => _GeminiSetupScreenState();
}

class _GeminiSetupScreenState extends State<GeminiSetupScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _inlineError;
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onAddKey(BuildContext context, String uid) {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _inlineError = "Please paste your key or tap Skip.");
      return;
    }
    setState(() => _inlineError = null);
    context.read<OnboardingBloc>().add(SubmitGeminiKey(key: key, uid: uid));
  }

  void _onSkip(BuildContext context) {
    context.read<OnboardingBloc>().add(const SkipGeminiKey());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final uid = (authState as AuthAuthenticated).user.uid;

    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (_, curr) => curr is OnboardingError,
      listener: (context, state) {
        state.maybeWhen(
          error: (message) => setState(() => _inlineError = message),
          orElse: () {},
        );
      },
      builder: (context, state) {
        final isLoading = state is OnboardingLoading;

        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.bgPrimary,
              body: SafeArea(
                child: SingleChildScrollView(
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
                          currentStep: 3,
                          totalSteps: 4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          "OPTIONAL — BUT RECOMMENDED",
                          style: AppTypography.labelSM.copyWith(
                            color: AppColors.success,
                            fontSize: 11,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Icon(
                        Icons.shield_outlined,
                        color: AppColors.accentSecondary,
                        size: 32,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        "Add a backup\nAI connection",
                        style: AppTypography.headingLG,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        "A second key keeps Valoqui running smoothly "
                        "if the first provider is busy. Free from Google.",
                        style: AppTypography.bodyMD.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x3l),
                      const _BenefitRow(
                        icon: Icons.bolt_rounded,
                        iconColor: AppColors.accentPrimary,
                        title: "Uninterrupted practice",
                        subtitle:
                            "Auto-switches if your primary key hits its limit",
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _BenefitRow(
                        icon: Icons.shield_rounded,
                        iconColor: AppColors.accentSecondary,
                        title: "Zero downtime",
                        subtitle:
                            "If one provider is down, the other picks up instantly",
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _BenefitRow(
                        icon: Icons.g_mobiledata_rounded,
                        iconColor: AppColors.success,
                        title: "Free from Google",
                        subtitle:
                            "1,000,000 tokens per day at no cost with a Google account",
                      ),
                      const SizedBox(height: AppSpacing.x3l),
                      _OutlineButton(
                        label: "Open Google AI Studio →",
                        color: AppColors.accentSecondary,
                        onTap: () => launchUrl(
                          Uri.parse("https://aistudio.google.com"),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _KeyInputField(
                        controller: _controller,
                        focusNode: _focusNode,
                        obscure: _obscure,
                        error: _inlineError,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                        onPaste: () async {
                          final data = await Clipboard.getData(
                            Clipboard.kTextPlain,
                          );
                          if (data?.text != null) {
                            _controller.text = data!.text!.trim();
                            setState(() => _inlineError = null);
                          }
                        },
                        onChanged: (_) {
                          if (_inlineError != null) {
                            setState(() => _inlineError = null);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            "Stored privately on your device only. Never shared.",
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x3l),
                      _PrimaryButton(
                        label: "Add backup key & Continue",
                        onTap: isLoading ? null : () => _onAddKey(context, uid),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: TextButton(
                          onPressed: isLoading ? null : () => _onSkip(context),
                          child: Text(
                            "Skip for now",
                            style: AppTypography.labelMD.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
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

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _BenefitRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelMD),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodyMD.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscure;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onPaste;
  final ValueChanged<String> onChanged;

  const _KeyInputField({
    required this.controller,
    required this.focusNode,
    required this.obscure,
    required this.error,
    required this.onToggleObscure,
    required this.onPaste,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      onChanged: onChanged,
      style: AppTypography.bodyMD.copyWith(
        fontFamily: AppTypography.jetBrainsMono,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: "Paste your Gemini key here...",
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: AppColors.textSecondary,
          size: 18,
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 18,
              ),
              onPressed: onToggleObscure,
            ),
            TextButton(
              onPressed: onPaste,
              child: Text(
                "Paste",
                style: AppTypography.labelSM.copyWith(
                  color: AppColors.accentSecondary,
                ),
              ),
            ),
          ],
        ),
        errorText: error,
        errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
      ),
    );
  }
}

class _OutlineButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OutlineButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: widget.color),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTypography.labelLG.copyWith(color: widget.color),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _PrimaryButton({required this.label, this.onTap});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 150),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.micButtonGradient,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: AppTypography.labelLG.copyWith(
                  color: AppColors.bgPrimary,
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
