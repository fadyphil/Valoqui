// test/features/auth/sign_in_screen_test.dart

import "package:bloc_test/bloc_test.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:valoqui/features/auth/bloc/auth_bloc.dart";
import "package:valoqui/features/auth/screens/sign_in_screen.dart";

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const SignInScreen(),
      ),
    );
  }

  group("SignInScreen", () {
    testWidgets("renders correctly in unauthenticated state", (tester) async {
      when(
        () => mockAuthBloc.state,
      ).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text("Valoqui"), findsOneWidget);
      expect(find.text("Practice Spanish. Sound fluent."), findsOneWidget);
      expect(find.text("Continue with Google"), findsOneWidget);
    });

    testWidgets("shows loading indicator when state is loading", (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.loading());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets("adds AuthSignInWithGoogle event when button is pressed", (
      tester,
    ) async {
      when(
        () => mockAuthBloc.state,
      ).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text("Continue with Google"));
      await tester.pump();

      verify(() => mockAuthBloc.add(const AuthSignInWithGoogle())).called(1);
    });

    testWidgets("shows error message SnackBar when state changes to error", (
      tester,
    ) async {
      const errorMsg = "Login Failed";
      // Start with unauthenticated
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([
          const AuthState.unauthenticated(),
          const AuthState.error(message: errorMsg),
        ]),
        initialState: const AuthState.unauthenticated(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text(errorMsg), findsOneWidget);
    });

    testWidgets("accessibility: button meets tap target guidelines", (
      tester,
    ) async {
      when(
        () => mockAuthBloc.state,
      ).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createWidgetUnderTest());

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    });
  });
}
