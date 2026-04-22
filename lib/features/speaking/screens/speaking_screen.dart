// lib/features/speaking/screens/speaking_screen.dart

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:valoqui/core/domain/models/conversation_message.dart";
import "package:valoqui/core/router/route_names.dart";
import "package:valoqui/core/theme/app_colors.dart";
import "package:valoqui/core/theme/app_spacing.dart";
import "package:valoqui/core/theme/app_typography.dart";
import "package:valoqui/features/auth/bloc/auth_bloc.dart";
import "package:valoqui/features/home/bloc/home_bloc.dart";
import "package:valoqui/features/speaking/bloc/speaking_bloc.dart";
import "package:valoqui/features/speaking/widgets/mic_button.dart";
import "package:valoqui/features/speaking/widgets/speaking_waveform.dart";
import "package:valoqui/features/speaking/widgets/transcript_bubble.dart";

class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({super.key});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    final homeState = context.read<HomeBloc>().state;

    if (authState is AuthAuthenticated) {
      final cefrLevel = homeState is HomeLoaded
          ? homeState.profile.currentCefrLevel
          : "A1";

      context.read<SpeakingBloc>().add(
        SessionStarted(userId: authState.user.uid, userCefrLevel: cefrLevel),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, "0");
    final m = (d.inMinutes % 60).toString().padLeft(2, "0");
    final s = (d.inSeconds % 60).toString().padLeft(2, "0");
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingEnded) {
          context.go(RouteNames.report, extra: state);
        }
        if (state is SpeakingActive && state.transcript.isNotEmpty) {
          _scrollToBottom();
        }
        if (state is SpeakingActive && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: switch (state) {
            SpeakingInitial() || SpeakingInitializing() => _buildLoading(),
            SpeakingError(:final message) => _buildError(message),
            SpeakingActive() => _buildActive(context, state),
            SpeakingEnded() => _buildLoading(),
          },
        );
      },
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.accentPrimary),
          SizedBox(height: AppSpacing.lg),
          Text(
            "Getting Lucia ready...",
            style: TextStyle(
              fontFamily: "DMSans",
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTypography.bodyMD.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.home),
              child: const Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active conversation ────────────────────────────────────────────────────

  Widget _buildActive(BuildContext context, SpeakingActive state) {
    final bloc = context.read<SpeakingBloc>();
    final isLuciaStreaming =
        state.phase == ConversationPhase.processing &&
        state.currentLuciaBuffer.isNotEmpty;

    return SafeArea(
      child: Column(
        children: [
          _TopBar(
            elapsed: state.elapsed,
            formatDuration: _formatDuration,
            onEnd: () => bloc.add(const SessionEnded()),
          ),
          const Divider(color: AppColors.border, height: 1),
          Expanded(child: _buildTranscript(state, isLuciaStreaming)),
          _buildBottomPanel(context, bloc),
        ],
      ),
    );
  }

  // ── Transcript ─────────────────────────────────────────────────────────────

  Widget _buildTranscript(SpeakingActive state, bool isLuciaStreaming) {
    final messages = state.transcript;
    final hasPartial =
        state.partialUserTranscript != null &&
        state.partialUserTranscript!.isNotEmpty;
    final showTyping =
        state.phase == ConversationPhase.processing &&
        state.currentLuciaBuffer.isEmpty;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      itemCount: messages.length + (hasPartial ? 1 : 0) + (showTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          final message = messages[index];
          final isLastLucia =
              index == messages.length - 1 && message.isAssistant;

          if (isLastLucia && isLuciaStreaming) {
            // ── BlocSelector for Scoped Rebuilds ───────────────────────
            // We use a BlocSelector to listen strictly to the currentLuciaBuffer.
            // This ensures that as each tiny token arrives (high frequency),
            // ONLY this single text bubble rebuilds, not the whole ListView.
            return BlocSelector<SpeakingBloc, SpeakingState, String>(
              selector: (state) => (state as SpeakingActive).currentLuciaBuffer,
              builder: (context, buffer) {
                return TranscriptBubble(
                  message: assistantMessage(buffer),
                  isStreaming: true,
                );
              },
            );
          }

          return TranscriptBubble(message: message, isStreaming: false);
        }
        if (hasPartial && index == messages.length) {
          return TranscriptBubble(
            message: userMessage(state.partialUserTranscript!),
            isStreaming: false,
          );
        }
        return const _TypingIndicator();
      },
    );
  }

  // ── Bottom panel ───────────────────────────────────────────────────────────
  //
  // Uses a dedicated BlocBuilder scoped to SpeakingActive so that high-frequency
  // amplitude updates (which fire on every mic tick) only rebuild this section
  // rather than the entire screen.  The buildWhen predicate further restricts
  // rebuilds to changes in amplitude, phase, or micMode — the three fields
  // this widget actually uses.
  //
  // The outer _buildActive already verified state is SpeakingActive, but the
  // inner BlocBuilder receives a fresh SpeakingState each time, so we must
  // guard with `is SpeakingActive` before accessing subtype fields.

  Widget _buildBottomPanel(BuildContext context, SpeakingBloc bloc) {
    return BlocBuilder<SpeakingBloc, SpeakingState>(
      buildWhen: (prev, curr) {
        if (curr is! SpeakingActive) return false;
        if (prev is! SpeakingActive) return true;
        return prev.amplitude != curr.amplitude ||
            prev.phase != curr.phase ||
            prev.micMode != curr.micMode ||
            prev.bufferFillPercentage != curr.bufferFillPercentage;
      },
      builder: (context, state) {
        // Guard: if state is not SpeakingActive (e.g. brief transition to
        // SpeakingEnded), return an empty box to avoid accessing missing fields.
        if (state is! SpeakingActive) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpeakingWaveform(
              phase: state.phase,
              amplitudeStream: state.amplitude,
            ),
            const Divider(color: AppColors.border, height: 1),
            Container(
              color: AppColors.bgPrimary,
              padding: const EdgeInsets.only(
                top: AppSpacing.xl,
                bottom: AppSpacing.xl,
              ),
              child: Column(
                children: [
                  MicButton(
                    phase: state.phase,
                    micMode: state.micMode,
                    bufferFillPercentage: state.bufferFillPercentage,
                    onPressDown: () => bloc.add(const MicPressed()),
                    onPressUp: () => bloc.add(const MicReleased()),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MicModeToggle(
                    micMode: state.micMode,
                    onToggle: () => bloc.add(const MicModeToggled()),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────
// Matches design: [X] End Session ············ ● 00:07:14

class _TopBar extends StatelessWidget {
  final Duration elapsed;
  final String Function(Duration) formatDuration;
  final VoidCallback onEnd;

  const _TopBar({
    required this.elapsed,
    required this.formatDuration,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onEnd,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgElevated,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            "End Session",
            style: AppTypography.bodyMD.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeOut(duration: 900.ms)
                  .then()
                  .fadeIn(duration: 900.ms),
              const SizedBox(width: 6),
              Text(
                formatDuration(elapsed),
                style: const TextStyle(
                  fontFamily: "JetBrainsMono",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => _Dot(index: i)),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final int index;
  const _Dot({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textSecondary,
          ),
        )
        .animate(
          delay: (index * 150).ms,
          onPlay: (c) => c.repeat(reverse: true),
        )
        .scaleXY(begin: 0.6, end: 1.0, duration: 400.ms);
  }
}
