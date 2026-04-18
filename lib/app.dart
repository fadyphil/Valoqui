// lib/app.dart
//
// Change from previous version:
// CheckOnboardingStatus() → CheckOnboardingStatusEvent()

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:valoqui/core/di/service_locator.dart";
import "package:valoqui/core/router/app_router.dart";
import "package:valoqui/core/theme/app_theme.dart";
import "package:valoqui/features/auth/bloc/auth_bloc.dart";
import "package:valoqui/features/home/bloc/home_bloc.dart";
import "package:valoqui/features/onboarding/bloc/onboarding_bloc.dart";

class ValoquiApp extends StatefulWidget {
  const ValoquiApp({super.key});

  @override
  State<ValoquiApp> createState() => _ValoquiAppState();
}

class _ValoquiAppState extends State<ValoquiApp> {
  late final AuthBloc _authBloc;
  late final OnboardingBloc _onboardingBloc;
  late final HomeBloc _homeBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthStarted());
    _onboardingBloc = sl<OnboardingBloc>()
      ..add(const CheckOnboardingStatusEvent()); // ← updated event name
    _homeBloc = sl<HomeBloc>();
    _router = createRouter(
      authBloc: _authBloc,
      onboardingBloc: _onboardingBloc,
    );
  }

  @override
  void dispose() {
    _authBloc.close();
    _onboardingBloc.close();
    _homeBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<OnboardingBloc>.value(value: _onboardingBloc),
        BlocProvider<HomeBloc>.value(value: _homeBloc),
      ],
      child: MaterialApp.router(
        title: "Valoqui",
        theme: AppTheme.dark.copyWith(
          appBarTheme: AppTheme.dark.appBarTheme.copyWith(
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
          ),
        ),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
