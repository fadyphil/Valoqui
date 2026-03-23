// lib/core/router/app_router.dart
//
// Changes from previous version:
// 1. AuthAuthenticated carries AppUser not Firebase User — no change
//    needed in the redirect logic since we only check the type.
// 2. Bug fix applied: removed && isOnSignIn from onboarding redirect guard.
// 3. Bug fix applied: removed .asBroadcastStream() from refresh stream.

import "dart:async";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:valoqui/core/router/route_names.dart";
import "package:valoqui/features/auth/bloc/auth_bloc.dart";
import "package:valoqui/features/auth/screens/sign_in_screen.dart";
import "package:valoqui/features/home/screens/home_screen.dart";
import "package:valoqui/features/onboarding/bloc/onboarding_bloc.dart";
import "package:valoqui/features/onboarding/screens/gemini_setup_screen.dart";
import "package:valoqui/features/onboarding/screens/groq_setup_screen.dart";
import "package:valoqui/features/onboarding/screens/level_selection_screen.dart";

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
      // Bug fix: removed && isOnSignIn — guard fires from any route
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

// Bug fix: removed .asBroadcastStream() — BLoC streams are already broadcast
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
