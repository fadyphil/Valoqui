// test/widget_test.dart

import "package:flutter_test/flutter_test.dart";
import "package:valoqui/app.dart";
import "package:valoqui/core/di/service_locator.dart";
import "package:mocktail/mocktail.dart";
import "mocks/mock_services.dart";

void main() {
  setUpAll(() async {
    // Basic DI setup for widget testing
    if (!sl.isRegistered<MockAuthService>()) {
      await setupServiceLocator();
    }
  });

  testWidgets("App smoke test - verifies entry point builds", (tester) async {
    // Build our app and trigger a frame.
    // Note: This might still fail if Firebase isn't mocked properly in this specific test,
    // but it's better than the old counter test.
    await tester.pumpWidget(const ValoquiApp());

    // Basic verification that the app at least starts
    expect(find.byType(ValoquiApp), findsOneWidget);
  });
}
