import "package:flutter_test/flutter_test.dart";
import "package:valoqui/core/domain/models/app_user.dart";
import "package:valoqui/core/domain/usecases/user/watch_user_profile.dart";

import "../../../../mocks/mock_services.dart";

void main() {
  late MockUserRepository mockUserRepository;
  late WatchUserProfile useCase;

  const tUid = "u-123";
  const tUser = AppUser(
    uid: tUid,
    displayName: "User",
    email: "user@example.com",
  );

  setUp(() {
    mockUserRepository = MockUserRepository();
    useCase = WatchUserProfile(userRepository: mockUserRepository);
  });

  test("proxies watchUser stream for the requested uid", () async {
    when(() => mockUserRepository.watchUser(tUid))
        .thenAnswer((_) => Stream<AppUser?>.fromIterable(const [tUser, null]));

    await expectLater(
      useCase.execute(tUid),
      emitsInOrder([tUser, null, emitsDone]),
    );
    verify(() => mockUserRepository.watchUser(tUid)).called(1);
  });
}
