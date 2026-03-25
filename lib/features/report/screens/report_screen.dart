// lib/features/report/screens/report_screen.dart

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:valoqui/core/router/route_names.dart";
import "package:valoqui/core/theme/app_colors.dart";
import "package:valoqui/core/theme/app_spacing.dart";
import "package:valoqui/core/theme/app_typography.dart";
import "package:valoqui/features/home/bloc/home_bloc.dart";
import "package:valoqui/features/report/bloc/report_bloc.dart";
import "package:valoqui/features/report/widgets/mistake_card.dart";
import "package:valoqui/features/report/widgets/score_bar.dart";
import "package:valoqui/features/report/widgets/xp_breakdown_card.dart";

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  String _formatDuration(Duration d) {
    if (d.inMinutes > 0) {
      final m = d.inMinutes;
      final s = d.inSeconds % 60;
      return "$m min ${s > 0 ? "$s sec" : ""}".trim();
    }
    return "${d.inSeconds} sec";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: BlocBuilder<ReportBloc, ReportState>(
        builder: (context, state) => switch (state) {
          ReportInitial() || ReportGenerating() => _buildGenerating(),
          ReportLoaded() => _buildLoaded(context, state),
          ReportFallback() => _buildFallback(context, state),
          ReportError(:final message) => _buildError(context, message),
        },
      ),
    );
  }

  // ── Generating spinner ─────────────────────────────────
  Widget _buildGenerating() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.accentPrimary),
          SizedBox(height: AppSpacing.lg),
          Text(
            "Generating your report...",
            style: TextStyle(
              fontFamily: "DMSans",
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Full report ────────────────────────────────────────
  Widget _buildLoaded(BuildContext context, ReportLoaded state) {
    final report = state.report;
    final homeState = context.read<HomeBloc>().state;
    final profile = homeState is HomeLoaded ? homeState.profile : null;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(child: _buildHeader(state)),

          // Grade card
          SliverToBoxAdapter(child: _buildGradeCard(report.overallGrade)),

          // Score bars
          SliverToBoxAdapter(
            child: _buildSection(
              title: null,
              child: Column(
                children: [
                  ScoreBar(label: "Fluency", score: report.fluencyScore),
                  ScoreBar(label: "Grammar", score: report.grammarScore),
                  ScoreBar(label: "Vocabulary", score: report.vocabularyScore),
                ],
              ),
            ),
          ),

          // XP breakdown
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

          // Topics covered
          if (report.topicsCovered.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSection(
                title: "TOPICS COVERED",
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

          // Mistakes
          if (report.mistakes.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSection(
                title: "MISTAKES & CORRECTIONS  (${report.mistakes.length})",
                child: Column(
                  children: report.mistakes
                      .map((m) => MistakeCard(mistake: m))
                      .toList(),
                ),
              ),
            ),

          // New vocabulary
          if (report.vocabularyHighlights.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSection(
                title:
                    "NEW VOCABULARY  (${report.vocabularyHighlights.length})",
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
                                " — ${v.english}",
                                style: AppTypography.bodyMD.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (v.usedCorrectly) ...[
                                const SizedBox(width: AppSpacing.sm),
                                const Text(
                                  "✓",
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

          // Tutor notes
          SliverToBoxAdapter(
            child: _buildSection(
              title: "TUTOR NOTES",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TutorNote(label: "Fluency", note: report.fluencyNote),
                  const SizedBox(height: AppSpacing.sm),
                  _TutorNote(label: "Grammar", note: report.grammarNote),
                  const SizedBox(height: AppSpacing.sm),
                  _TutorNote(label: "Vocabulary", note: report.vocabularyNote),
                ],
              ),
            ),
          ),

          // Encouragement
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

          // Action buttons
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
          const Text("✨  Session Complete", style: AppTypography.headingMD),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "${_formatDuration(state.totalDuration)}  ·  ${_formatDuration(state.activeSpeakingTime)} speaking",
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
            "Overall Grade",
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

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          // Speak Again
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.go(RouteNames.speaking),
              icon: const Icon(Icons.mic_rounded),
              label: const Text("Speak Again"),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fallback (report failed, XP saved) ────────────────
  Widget _buildFallback(BuildContext context, ReportFallback state) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("✅", style: TextStyle(fontSize: 48)),
              const SizedBox(height: AppSpacing.lg),
              const Text("Session Complete!", style: AppTypography.headingMD),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "+${state.totalXp} XP saved",
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
              ElevatedButton(
                onPressed: () => context.go(RouteNames.speaking),
                child: const Text("Speak Again"),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.go(RouteNames.home),
                child: const Text("Back to Home"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────
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
                child: const Text("Back to Home"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            text: "$label: ",
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
