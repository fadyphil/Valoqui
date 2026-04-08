// lib/features/onboarding/screens/groq_setup_screen.dart
//
// Only change from previous version:
// SaveGroqKey(key: key, uid: uid) → SubmitGroqKey(key: key, uid: uid)

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:url_launcher/url_launcher.dart";
import 'package:valoqui/core/theme/app_colors.dart';
import 'package:valoqui/core/theme/app_spacing.dart';
import 'package:valoqui/core/theme/app_typography.dart';
import "package:valoqui/features/auth/bloc/auth_bloc.dart";
import "package:valoqui/features/onboarding/bloc/onboarding_bloc.dart";
import 'package:valoqui/shared/widgets/loading_overlay.dart';
import 'package:valoqui/shared/widgets/onboarding_progress_dots.dart';

class GroqSetupScreen extends StatefulWidget {
  const GroqSetupScreen({super.key});

  @override
  State<GroqSetupScreen> createState() => _GroqSetupScreenState();
}

class _GroqSetupScreenState extends State<GroqSetupScreen> {
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

  void _onContinue(BuildContext context, String uid) {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _inlineError = "Please paste your key to continue.");
      return;
    }
    setState(() => _inlineError = null);
    context.read<OnboardingBloc>().add(SubmitGroqKey(key: key, uid: uid));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final uid = (authState as AuthAuthenticated).user.uid;

    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (_, curr) =>
          curr is OnboardingError || curr is GroqKeyComplete,
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
                          currentStep: 2,
                          totalSteps: 4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x3l),
                      const Icon(
                        Icons.key_rounded,
                        color: AppColors.accentPrimary,
                        size: 32,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        "Set up your free\nAI connection",
                        style: AppTypography.headingLG,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        "Valoqui uses a free AI service to power your "
                        "conversations. You'll need your own personal key "
                        "— it takes 30 seconds.",
                        style: AppTypography.bodyMD.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x3l),
                      const _StepList(
                        steps: [
                          "Open the link below",
                          "Create a free account",
                          'Click "Create API Key"',
                          "Copy and paste it here",
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _OutlineButton(
                        label: "Open Groq Console →",
                        onTap: () => launchUrl(
                          Uri.parse("https://console.groq.com"),
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
                      const Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            "Stored privately on your device only. Never shared.",
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x3l),
                      _PrimaryButton(
                        label: "Continue",
                        onTap: isLoading
                            ? null
                            : () => _onContinue(context, uid),
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

class _StepList extends StatelessWidget {
  final List<String> steps;
  const _StepList({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgElevated,
                ),
                child: Center(
                  child: Text(
                    "$index",
                    style: AppTypography.labelSM.copyWith(
                      color: AppColors.accentPrimary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(entry.value, style: AppTypography.bodyMD)),
            ],
          ),
        );
      }).toList(),
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
        hintText: "Paste your key here...",
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
                  color: AppColors.accentPrimary,
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
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

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
            border: Border.all(color: AppColors.accentPrimary),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTypography.labelLG.copyWith(
                color: AppColors.accentPrimary,
              ),
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
