// lib/features/home/screens/home_screen.dart

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:valoqui/features/auth/bloc/auth_bloc.dart";
import "package:valoqui/features/home/bloc/home_bloc.dart";
import "../../../../core/domain/models/app_user.dart";
import "../../../../core/theme/app_colors.dart";
import "../../../../core/theme/app_typography.dart";
import "../../../../core/theme/app_spacing.dart";
import "../../../../shared/widgets/xp_progress_bar.dart";
import "../../../../shared/widgets/level_badge.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<HomeBloc>().add(WatchProfile(authState.user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) => state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentPrimary),
          ),
          loaded: (profile) => _HomeContent(profile: profile),
          error: (message) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                message,
                style: AppTypography.bodyMD.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final AppUser profile;
  const _HomeContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePaddingH,
          vertical: AppSpacing.pagePaddingV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            _TopBar(profile: profile),
            const SizedBox(height: AppSpacing.xl),
            _XPSection(profile: profile),
            const SizedBox(height: AppSpacing.x3l),
            const _MicButtonSection(),
            const SizedBox(height: AppSpacing.x3l),
            _StatsRow(profile: profile),
            const SizedBox(height: AppSpacing.xl),
            _LastSessionCard(profile: profile),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final AppUser profile;
  const _TopBar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final initial = profile.displayName.isNotEmpty
        ? profile.displayName[0].toUpperCase()
        : "?";

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.bgElevated,
          ),
          child: Center(
            child: Text(
              initial,
              style: AppTypography.labelLG.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            "Hola, ${profile.displayName.split(' ').first} 👋",
            style: AppTypography.labelLG,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        LevelBadge(level: profile.currentCefrLevel),
      ],
    );
  }
}

class _XPSection extends StatelessWidget {
  final AppUser profile;
  const _XPSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${profile.currentXP} XP",
              style: AppTypography.labelMD.copyWith(
                color: AppColors.accentPrimary,
              ),
            ),
            Text("${profile.xpForNextLevel} XP", style: AppTypography.labelSM),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        XPProgressBar(progress: profile.levelProgress),
      ],
    );
  }
}

class _MicButtonSection extends StatelessWidget {
  const _MicButtonSection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 196,
                height: 196,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentPrimary.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Sprint 2: context.push(RouteNames.speaking)
                },
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.micButtonGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.micGlow,
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 52),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            "Let's Speak",
            style: AppTypography.headingMD.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Tap to start a conversation",
            style: AppTypography.bodyMD.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AppUser profile;
  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            value: "${profile.streakDays}",
            label: "Day streak",
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.access_time_rounded,
            value: "${(profile.totalSpeakingSeconds / 60).round()}",
            label: "Minutes",
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.bar_chart_rounded,
            value: "${profile.totalSessionCount}",
            label: "Sessions",
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accentPrimary, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTypography.headingMD.copyWith(fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSM,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LastSessionCard extends StatelessWidget {
  final AppUser profile;
  const _LastSessionCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile.totalSessionCount == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "No sessions yet",
              style: AppTypography.labelLG.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "Tap the mic to start your first conversation!",
              style: AppTypography.bodyMD.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Last Session", style: AppTypography.labelMD),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "${profile.totalSessionCount} sessions completed",
                  style: AppTypography.labelSM,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        onTap: (_) {},
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_rounded),
            label: "Progress",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
