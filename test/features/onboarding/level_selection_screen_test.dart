// test/features/onboarding/level_selection_screen_test.dart

import "package:bloc_test/bloc_test.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:valoqui/core/domain/models/app_user.dart";
import "package:valoqui/features/auth/bloc/auth_bloc.dart";
import "package:valoqui/features/onboarding/bloc/onboarding_bloc.dart";
import "package:valoqui/features/onboarding/screens/level_selection_screen.dart";
import "package:valoqui/shared/widgets/loading_overlay.dart";

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockOnboardingBloc extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockOnboardingBloc mockOnboardingBloc;

  const tUser = AppUser(
    uid: "123",
    displayName: "Test",
    email: "test@test.com",
    currentCefrLevel: "A1",
  );

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockOnboardingBloc = MockOnboardingBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<OnboardingBloc>.value(value: mockOnboardingBloc),
        ],
        child: const LevelSelectionScreen(),
      ),
    );
  }

  group("LevelSelectionScreen", () {
    testWidgets("renders all levels correctly", (tester) async {
      when(
        () => mockAuthBloc.state,
      ).thenReturn(const AuthState.authenticated(user: tUser));
      when(
        () => mockOnboardingBloc.state,
      ).thenReturn(const OnboardingState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text("What's your current\nSpanish level?"), findsOneWidget);
      expect(find.text("A1"), findsOneWidget);
      expect(find.text("Complete Beginner"), findsOneWidget);
      expect(find.text("A2"), findsOneWidget);
      expect(find.text("Elementary"), findsOneWidget);
    });

    testWidgets("shows loading overlay when onboarding is loading", (
      tester,
    ) async {
      when(
        () => mockAuthBloc.state,
      ).thenReturn(const AuthState.authenticated(user: tUser));
      when(
        () => mockOnboardingBloc.state,
      ).thenReturn(const OnboardingState.loading());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(LoadingOverlay), findsOneWidget);
    });

    testWidgets("selects and submits level when cards and button are tapped", (
      tester,
    ) async {
      when(
        () => mockAuthBloc.state,
      ).thenReturn(const AuthState.authenticated(user: tUser));
      when(
        () => mockOnboardingBloc.state,
      ).thenReturn(const OnboardingState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      // 1. Select A2
      await tester.tap(find.text("A2"));
      await tester.pump();

      // 2. Tap Continue Button
      await tester.tap(find.text("Let's Start →"));
      await tester.pump();

      verify(
        () =>
            mockOnboardingBloc.add(const SubmitLevel(uid: "123", level: "A2")),
      ).called(1);
    });

    testWidgets("accessibility: level cards meet minimum touch targets", (
      tester,
    ) async {
      when(
        () => mockAuthBloc.state,
      ).thenReturn(const AuthState.authenticated(user: tUser));
      when(
        () => mockOnboardingBloc.state,
      ).thenReturn(const OnboardingState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });
}
