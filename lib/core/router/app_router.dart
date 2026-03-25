// lib/core/router/app_router.dart
//
// Sprint 2 additions:
//   - /speaking route: creates a fresh SpeakingBloc scoped to the route.
//   - /report  route: creates a fresh ReportBloc scoped to the route,
//     immediately fires GenerateReport using data passed via state.extra.
//
// Both BLoCs are route-scoped via BlocProvider in pageBuilder.
// They are NOT added to the app-level MultiBlocProvider — that would keep
// them alive across the whole session lifetime, which is wrong for
// SpeakingBloc (should be fresh per session) and ReportBloc (per report).
//
// The refreshListenable is intentionally unchanged — speaking/report routes
// are push navigation, not redirect targets.

import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:valoqui/core/di/service_locator.dart";
import "package:valoqui/core/router/route_names.dart";
import "package:valoqui/features/auth/bloc/auth_bloc.dart";
import "package:valoqui/features/auth/screens/sign_in_screen.dart";
import "package:valoqui/features/home/screens/home_screen.dart";
import "package:valoqui/features/onboarding/bloc/onboarding_bloc.dart";
import "package:valoqui/features/onboarding/screens/gemini_setup_screen.dart";
import "package:valoqui/features/onboarding/screens/groq_setup_screen.dart";
import "package:valoqui/features/onboarding/screens/level_selection_screen.dart";
import "package:valoqui/features/report/bloc/report_bloc.dart";
import "package:valoqui/features/report/screens/report_screen.dart";
import "package:valoqui/features/speaking/bloc/speaking_bloc.dart";
import "package:valoqui/features/speaking/screens/speaking_screen.dart";

GoRouter createRouter({
  required AuthBloc authBloc,
  required OnboardingBloc onboardingBloc,
}) {
  return GoRouter(
    initialLocation: RouteNames.signIn,
    refreshListenable: _GoRouterBlocRefreshStream([
      authBloc.stream,
      onboardingBloc.stream,
    ]),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authBloc.state;
      final onboardingState = onboardingBloc.state;
      final currentLocation = state.matchedLocation;

      final isAuthenticated = authState is AuthAuthenticated;
      final isOnSignIn = currentLocation == RouteNames.signIn;

      // ── Not authenticated → force sign-in ──────────────
      if (!isAuthenticated && !isOnSignIn) return RouteNames.signIn;
      if (!isAuthenticated) return null;

      // ── Authenticated but onboarding incomplete ─────────
      final isOnboardingComplete = onboardingState is OnboardingComplete;
      final isOnSetupRoute = currentLocation.startsWith("/setup");

      if (!isOnboardingComplete && !isOnSetupRoute) {
        if (onboardingState is GroqKeyComplete) return RouteNames.geminiSetup;
        if (onboardingState is GeminiStepComplete) {
          return RouteNames.levelSelection;
        }
        return RouteNames.groqSetup;
      }

      // Redirect within setup screens based on progress
      if (onboardingState is GroqKeyComplete &&
          currentLocation == RouteNames.groqSetup) {
        return RouteNames.geminiSetup;
      }
      if (onboardingState is GeminiStepComplete &&
          currentLocation != RouteNames.levelSelection) {
        return RouteNames.levelSelection;
      }

      // ── Authenticated + onboarding complete → home ──────
      if (isOnboardingComplete && (isOnSignIn || isOnSetupRoute)) {
        return RouteNames.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.signIn,
        pageBuilder: (context, state) =>
            _buildPage(state, const SignInScreen()),
      ),
      GoRoute(
        path: RouteNames.groqSetup,
        pageBuilder: (context, state) =>
            _buildPage(state, const GroqSetupScreen(), slideIn: true),
      ),
      GoRoute(
        path: RouteNames.geminiSetup,
        pageBuilder: (context, state) =>
            _buildPage(state, const GeminiSetupScreen(), slideIn: true),
      ),
      GoRoute(
        path: RouteNames.levelSelection,
        pageBuilder: (context, state) =>
            _buildPage(state, const LevelSelectionScreen(), slideIn: true),
      ),
      GoRoute(
        path: RouteNames.home,
        pageBuilder: (context, state) => _buildPage(state, const HomeScreen()),
      ),

      // ── Sprint 2: Speaking ────────────────────────────
      // SpeakingBloc is created fresh for each session and disposed
      // automatically when the user navigates away from this route.
      GoRoute(
        path: RouteNames.speaking,
        pageBuilder: (context, state) => _buildPage(
          state,
          BlocProvider(
            create: (_) => sl<SpeakingBloc>(),
            child: const SpeakingScreen(),
          ),
          slideIn: true,
        ),
      ),

      // ── Sprint 2: Report ──────────────────────────────
      // SpeakingEnded state is passed via state.extra from SpeakingScreen.
      // ReportBloc fires GenerateReport immediately on creation.
      GoRoute(
        path: RouteNames.report,
        pageBuilder: (context, state) {
          final ended = state.extra! as SpeakingEnded;
          return _buildPage(
            state,
            BlocProvider(
              create: (_) => sl<ReportBloc>()
                ..add(
                  GenerateReportEvent(
                    transcript: ended.transcript,
                    totalDuration: ended.totalDuration,
                    activeSpeakingTime: ended.activeSpeakingTime,
                    userId: ended.userId,
                    userCefrLevel: ended.userCefrLevel,
                  ),
                ),
              child: const ReportScreen(),
            ),
          );
        },
      ),
    ],
  );
}

CustomTransitionPage<void> _buildPage(
  GoRouterState state,
  Widget child, {
  bool slideIn = false,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (slideIn) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
          child: child,
        );
      }
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _GoRouterBlocRefreshStream extends ChangeNotifier {
  late final List<StreamSubscription<dynamic>> _subscriptions;

  _GoRouterBlocRefreshStream(List<Stream<dynamic>> streams) {
    _subscriptions = streams
        .map((stream) => stream.listen((_) => notifyListeners()))
        .toList();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
