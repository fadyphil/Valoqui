// test/widget_test.dart

import "package:bloc_test/bloc_test.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:valoqui/app.dart";
import "package:valoqui/core/di/service_locator.dart";
import "package:valoqui/features/auth/bloc/auth_bloc.dart";
import "package:valoqui/features/home/bloc/home_bloc.dart";
import "package:valoqui/features/onboarding/bloc/onboarding_bloc.dart";

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockOnboardingBloc extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockOnboardingBloc mockOnboardingBloc;
  late MockHomeBloc mockHomeBloc;

  setUpAll(() {
    sl.allowReassignment = true;
    mockAuthBloc = MockAuthBloc();
    mockOnboardingBloc = MockOnboardingBloc();
    mockHomeBloc = MockHomeBloc();

    // Register mocks in sl
    sl.registerFactory<AuthBloc>(() => mockAuthBloc);
    sl.registerFactory<OnboardingBloc>(() => mockOnboardingBloc);
    sl.registerFactory<HomeBloc>(() => mockHomeBloc);
  });

  testWidgets("App root renders correctly with initial states", (tester) async {
    when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());
    when(
      () => mockOnboardingBloc.state,
    ).thenReturn(const OnboardingState.initial());
    when(() => mockHomeBloc.state).thenReturn(const HomeState.initial());

    await tester.pumpWidget(const ValoquiApp());

    expect(find.byType(ValoquiApp), findsOneWidget);
  });
}
