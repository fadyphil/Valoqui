import "package:flutter_test/flutter_test.dart";
import "package:valoqui/core/domain/models/app_user.dart";
import "package:valoqui/core/domain/usecases/auth/watch_auth_state.dart";

import "../../../../mocks/mock_services.dart";

void main() {
  late MockAuthRepository mockAuthRepository;
  late WatchAuthState useCase;

  const tUser = AppUser(
    uid: "u1",
    displayName: "Fady",
    email: "fady@example.com",
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = WatchAuthState(authRepository: mockAuthRepository);
  });

  test("returns the same auth state stream exposed by repository", () async {
    final stream = Stream<AppUser?>.fromIterable(const [null, tUser]);

    when(() => mockAuthRepository.authStateChanges).thenAnswer((_) => stream);

    expectLater(useCase.execute(), emitsInOrder([null, tUser, emitsDone]));
  });
}
