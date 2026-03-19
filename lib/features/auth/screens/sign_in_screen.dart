// lib/features/auth/screens/sign_in_screen.dart

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_typography.dart";
import "../../../core/theme/app_spacing.dart";
import "../bloc/auth_bloc.dart";

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          state.maybeWhen(
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            orElse: () {},
          );
        },
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePaddingH,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // ── Wordmark ──────────────────────────────
                  Text(
                    "Valoqui",
                    style: AppTypography.displayXL.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Amber rule ────────────────────────────
                  Container(
                    width: 40,
                    height: 1,
                    color: AppColors.accentPrimary,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Tagline ───────────────────────────────
                  Text(
                    "Practice Spanish. Sound fluent.",
                    style: AppTypography.bodyLG.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.x3l),

                  // ── Sound wave (decorative) ───────────────
                  const _SoundWaveDecoration(),

                  const Spacer(flex: 2),

                  // ── Google sign-in button ──────────────────
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return _GoogleSignInButton(
                        isLoading: isLoading,
                        onTap: isLoading
                            ? null
                            : () {
                                context.read<AuthBloc>().add(
                                  const AuthSignInWithGoogle(),
                                );
                              },
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Fine print ────────────────────────────
                  Text(
                    "Free forever · No subscription",
                    style: AppTypography.labelSM.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sound Wave Decoration ───────────────────────────────
class _SoundWaveDecoration extends StatelessWidget {
  const _SoundWaveDecoration();

  @override
  Widget build(BuildContext context) {
    const heights = [
      12.0,
      24.0,
      16.0,
      32.0,
      20.0,
      48.0,
      28.0,
      40.0,
      24.0,
      16.0,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: heights.map((h) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            width: 4,
            height: h,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Custom Google Sign-In Button ────────────────────────
class _GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isLoading;

  const _GoogleSignInButton({required this.onTap, required this.isLoading});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.border),
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.accentPrimary,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google "G" icon
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          "G",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      "Continue with Google",
                      style: AppTypography.labelLG.copyWith(fontSize: 16),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
