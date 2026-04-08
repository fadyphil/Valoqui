// test/features/home/home_bloc_test.dart

import "package:bloc_test/bloc_test.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:valoqui/core/domain/models/app_user.dart";
import "package:valoqui/features/home/bloc/home_bloc.dart";

import "../../mocks/mock_services.dart";

void main() {
  late MockWatchUserProfile mockWatchUserProfile;

  const tUser = AppUser(
    uid: "123",
    displayName: "Test User",
    email: "test@example.com",
    currentCefrLevel: "A1",
  );

  setUp(() {
    mockWatchUserProfile = MockWatchUserProfile();
  });

  HomeBloc buildBloc() => HomeBloc(watchUserProfile: mockWatchUserProfile);

  group("HomeBloc", () {
    test("initial state is HomeState.initial()", () {
      expect(buildBloc().state, const HomeState.initial());
    });

    group("WatchProfile", () {
      blocTest<HomeBloc, HomeState>(
        "emits [loading, loaded] when profile is found",
        build: () {
          when(
            () => mockWatchUserProfile.execute(any()),
          ).thenAnswer((_) => Stream.value(tUser));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const WatchProfile("123")),
        expect: () => [
          const HomeState.loading(),
          const HomeState.loaded(profile: tUser),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        "emits [loading, error] when profile is null",
        build: () {
          when(
            () => mockWatchUserProfile.execute(any()),
          ).thenAnswer((_) => Stream.value(null));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const WatchProfile("123")),
        expect: () => [
          const HomeState.loading(),
          const HomeState.error(message: "User profile not found."),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        "emits [loading, error] on stream error",
        build: () {
          when(
            () => mockWatchUserProfile.execute(any()),
          ).thenAnswer((_) => Stream.error("Stream Error"));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const WatchProfile("123")),
        expect: () => [
          const HomeState.loading(),
          const HomeState.error(
            message: "Failed to load profile: Stream Error",
          ),
        ],
      );
    });
  });
}
