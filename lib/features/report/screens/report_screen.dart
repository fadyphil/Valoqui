// lib/features/report/screens/report_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:valoqui/core/router/route_names.dart';
import 'package:valoqui/core/theme/app_colors.dart';
import 'package:valoqui/core/theme/app_spacing.dart';
import 'package:valoqui/core/theme/app_typography.dart';
import 'package:valoqui/features/home/bloc/home_bloc.dart';
import 'package:valoqui/features/report/bloc/report_bloc.dart';
import 'package:valoqui/features/report/widgets/mistake_card.dart';
import 'package:valoqui/features/report/widgets/score_bar.dart';
import 'package:valoqui/features/report/widgets/xp_breakdown_card.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  String _formatDuration(Duration d) {
    if (d.inMinutes > 0) {
      final m = d.inMinutes;
      final s = d.inSeconds % 60;
      return s > 0 ? '$m min $s sec' : '$m min';
    }
    return '${d.inSeconds} sec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: BlocBuilder<ReportBloc, ReportState>(
        builder: (context, state) => switch (state) {
          ReportInitial() => _buildGenerating(
            const Duration(seconds: 0),
            const Duration(seconds: 0),
          ),
          ReportGenerating(:final totalDuration, :final activeSpeakingTime) =>
            _buildGenerating(totalDuration, activeSpeakingTime),
          ReportLoaded() => _buildLoaded(context, state),
          ReportFallback() => _buildFallback(context, state),
          ReportError(:final message) => _buildError(context, message),
        },
      ),
    );
  }

  // ── Loading screen ─────────────────────────────────────────────────────────
  // Matches the design exactly: dashed circle icon · step list · stats pill

  Widget _buildGenerating(Duration totalDuration, Duration activeSpeakingTime) {
    return SafeArea(
      child: _GeneratingContent(
        totalDuration: totalDuration,
        activeSpeakingTime: activeSpeakingTime,
        formatDuration: _formatDuration,
      ),
    );
  }

  // ── Full report ────────────────────────────────────────────────────────────

  Widget _buildLoaded(BuildContext context, ReportLoaded state) {
    final report = state.report;
    final homeState = context.read<HomeBloc>().state;
    final profile = homeState is HomeLoaded ? homeState.profile : null;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(state)),
          SliverToBoxAdapter(child: _buildGradeCard(report.overallGrade)),
          SliverToBoxAdapter(
            child: _buildSection(
              title: null,
              child: Column(
                children: [
                  ScoreBar(label: 'Fluency', score: report.fluencyScore),
                  ScoreBar(label: 'Grammar', score: report.grammarScore),
                  ScoreBar(label: 'Vocabulary', score: report.vocabularyScore),
                ],
              ),
            ),
          ),
          if (profile != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: XpBreakdownCard(
                  xp: report.xpBreakdown,
                  profile: profile,
                ),
              ),
            ),
          if (report.topicsCovered.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'TOPICS COVERED',
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: report.topicsCovered
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(t, style: AppTypography.labelMD),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          if (report.mistakes.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'MISTAKES & CORRECTIONS  (${report.mistakes.length})',
                child: Column(
                  children: report.mistakes
                      .map((m) => MistakeCard(mistake: m))
                      .toList(),
                ),
              ),
            ),
          if (report.vocabularyHighlights.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSection(
                title:
                    'NEW VOCABULARY  (${report.vocabularyHighlights.length})',
                child: Column(
                  children: report.vocabularyHighlights
                      .map(
                        (v) => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              Text(
                                v.word,
                                style: AppTypography.bodyMD.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentSecondary,
                                ),
                              ),
                              Text(
                                ' — ${v.english}',
                                style: AppTypography.bodyMD.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (v.usedCorrectly) ...[
                                const SizedBox(width: AppSpacing.sm),
                                const Text(
                                  '✓',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: _buildSection(
              title: 'TUTOR NOTES',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TutorNote(label: 'Fluency', note: report.fluencyNote),
                  const SizedBox(height: AppSpacing.sm),
                  _TutorNote(label: 'Grammar', note: report.grammarNote),
                  const SizedBox(height: AppSpacing.sm),
                  _TutorNote(label: 'Vocabulary', note: report.vocabularyNote),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSection(
              title: null,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  report.encouragement,
                  style: AppTypography.bodyLG.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildActions(context)),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.x3l)),
        ],
      ),
    );
  }

  Widget _buildHeader(ReportLoaded state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✨  Session Complete', style: AppTypography.headingMD),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${_formatDuration(state.totalDuration)}  ·  ${_formatDuration(state.activeSpeakingTime)} speaking',
            style: AppTypography.bodyMD.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCard(String grade) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                grade,
                style: AppTypography.headingLG.copyWith(
                  color: AppColors.accentPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            'Overall Grade',
            style: AppTypography.bodyLG.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String? title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            const Divider(color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: AppTypography.labelSM),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );
  }

  // ── Action buttons — BOTH Speak Again and Go Home ─────────────────────────

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          // Go Home
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.go(RouteNames.home),
              icon: const Icon(Icons.home_rounded, size: 18),
              label: const Text('Home'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                textStyle: AppTypography.labelLG,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Speak Again
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => context.go(RouteNames.speaking),
              icon: const Icon(Icons.mic_rounded, size: 18),
              label: const Text('Speak Again'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fallback (report failed, XP saved) ────────────────────────────────────

  Widget _buildFallback(BuildContext context, ReportFallback state) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✅', style: TextStyle(fontSize: 48)),
              const SizedBox(height: AppSpacing.lg),
              const Text('Session Complete!', style: AppTypography.headingMD),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '+${state.totalXp} XP saved',
                style: AppTypography.headingMD.copyWith(
                  color: AppColors.accentPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                "Your detailed report couldn't be generated this time, but your progress has been saved.",
                style: AppTypography.bodyMD.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton.icon(
                onPressed: () => context.go(RouteNames.speaking),
                icon: const Icon(Icons.mic_rounded, size: 18),
                label: const Text('Speak Again'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go(RouteNames.home),
                  icon: const Icon(Icons.home_rounded, size: 18),
                  label: const Text('Back to Home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────

  Widget _buildError(BuildContext context, String message) {
    return SafeArea(
      child: Center(
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
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Generating content widget ──────────────────────────────────────────────────
// Matches the design: dashed circle · title · step list · stats pill · footer

class _GeneratingContent extends StatefulWidget {
  final Duration totalDuration;
  final Duration activeSpeakingTime;
  final String Function(Duration) formatDuration;

  const _GeneratingContent({
    required this.totalDuration,
    required this.activeSpeakingTime,
    required this.formatDuration,
  });

  @override
  State<_GeneratingContent> createState() => _GeneratingContentState();
}

class _GeneratingContentState extends State<_GeneratingContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotateController;
  // Step 1 completes instantly; step 2 starts after a short delay
  int _activeStep = 1; // 0-indexed: 0=complete, 1=in-progress, 2=pending
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Simulate step progression while the API call runs
    _stepTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _activeStep = 2);
    });
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSessionData = widget.totalDuration.inSeconds > 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Dashed circle with sparkle icon ──────────────────────────────
            _DashedCircleIcon(rotateController: _rotateController),
            const SizedBox(height: AppSpacing.xxl),

            // ── Title ────────────────────────────────────────────────────────
            const Text(
                  'Analyzing your session...',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .slideY(begin: 0.15, end: 0, duration: 400.ms, delay: 100.ms),

            const SizedBox(height: AppSpacing.md),

            // ── Subtitle ─────────────────────────────────────────────────────
            Text(
              'Lucia is reviewing your Spanish and\npreparing your personal report.',
              style: AppTypography.bodyMD.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: AppSpacing.x3l),

            // ── Step list ────────────────────────────────────────────────────
            _StepList(
              activeStep: _activeStep,
            ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

            const SizedBox(height: AppSpacing.xxl),

            // ── Stats pill ───────────────────────────────────────────────────
            if (hasSessionData)
              _StatsPill(
                duration: widget.totalDuration,
                formatDuration: widget.formatDuration,
              ).animate().fadeIn(duration: 400.ms, delay: 450.ms),

            const SizedBox(height: AppSpacing.x3l),

            // ── Footer hint ───────────────────────────────────────────────────
            Text(
              'This usually takes 5–10 seconds',
              style: AppTypography.caption,
            ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
          ],
        ),
      ),
    );
  }
}

// ── Dashed rotating circle with sparkle icon ───────────────────────────────────

class _DashedCircleIcon extends StatelessWidget {
  final AnimationController rotateController;

  const _DashedCircleIcon({required this.rotateController});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Slowly rotating dashed border
              AnimatedBuilder(
                animation: rotateController,
                builder: (context, _) => Transform.rotate(
                  angle: rotateController.value * 2 * pi,
                  child: CustomPaint(
                    size: const Size(100, 100),
                    painter: _DashedCirclePainter(
                      color: AppColors.accentPrimary.withValues(alpha: 0.6),
                      dashCount: 20,
                      strokeWidth: 1.5,
                    ),
                  ),
                ),
              ),
              // Inner filled circle
              Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bgElevated,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.accentPrimary,
                        size: 30,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                    begin: 0.96,
                    end: 1.0,
                    duration: 1800.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .scaleXY(
          begin: 0.85,
          end: 1.0,
          duration: 500.ms,
          curve: Curves.easeOut,
        );
  }
}

/// Draws a circle made of evenly-spaced dashes.
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double strokeWidth;

  const _DashedCirclePainter({
    required this.color,
    required this.dashCount,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    final gapAngle = (2 * pi) / dashCount;
    final dashAngle = gapAngle * 0.55; // dash occupies 55% of each slot

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * gapAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.color != color || old.dashCount != dashCount;
}

// ── Step list ─────────────────────────────────────────────────────────────────

class _StepList extends StatelessWidget {
  final int
  activeStep; // 0=step1 in progress, 1=step2 in progress, 2=step3 in progress

  const _StepList({required this.activeStep});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepRow(
          label: 'Transcription complete',
          status: activeStep >= 1 ? _StepStatus.done : _StepStatus.active,
        ),
        const SizedBox(height: AppSpacing.md),
        _StepRow(
          label: 'Grading grammar & vocabulary',
          status: activeStep == 1
              ? _StepStatus.active
              : activeStep > 1
              ? _StepStatus.done
              : _StepStatus.pending,
        ),
        const SizedBox(height: AppSpacing.md),
        _StepRow(
          label: 'Calculating your XP',
          status: activeStep == 2
              ? _StepStatus.active
              : activeStep > 2
              ? _StepStatus.done
              : _StepStatus.pending,
        ),
      ],
    );
  }
}

enum _StepStatus { done, active, pending }

class _StepRow extends StatelessWidget {
  final String label;
  final _StepStatus status;

  const _StepRow({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 24, height: 24, child: _buildIcon()),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: switch (status) {
              _StepStatus.done => AppColors.success,
              _StepStatus.active => AppColors.accentPrimary,
              _StepStatus.pending => AppColors.textSecondary.withValues(
                alpha: 0.5,
              ),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    switch (status) {
      case _StepStatus.done:
        return const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 22,
        );
      case _StepStatus.active:
        return Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentPrimary,
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
              begin: 0.75,
              end: 1.0,
              duration: 700.ms,
              curve: Curves.easeInOut,
            )
            .fadeOut(begin: 0.5, duration: 700.ms)
            .then()
            .fadeIn(duration: 700.ms);
      case _StepStatus.pending:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
        );
    }
  }
}

// ── Session stats pill ────────────────────────────────────────────────────────

class _StatsPill extends StatelessWidget {
  final Duration duration;
  final String Function(Duration) formatDuration;

  const _StatsPill({required this.duration, required this.formatDuration});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.circle),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            color: AppColors.textSecondary,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            formatDuration(duration),
            style: AppTypography.labelMD.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tutor note ────────────────────────────────────────────────────────────────

class _TutorNote extends StatelessWidget {
  final String label;
  final String note;

  const _TutorNote({required this.label, required this.note});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: AppTypography.bodyMD.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: note,
            style: AppTypography.bodyMD.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
