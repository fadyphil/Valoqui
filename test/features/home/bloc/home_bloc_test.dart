import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valoqui/core/domain/models/app_user.dart';
import 'package:valoqui/features/home/bloc/home_bloc.dart';

import '../../../mocks/mock_services.dart';

void main() {
  late HomeBloc homeBloc;
  late MockWatchUserProfile mockWatchUserProfile;

  const tUid = 'test-user-123';
  const tUser = AppUser(
    uid: tUid,
    displayName: 'Test User',
    email: 'test@example.com',
    currentCefrLevel: 'A2',
  );
  const tUpdatedUser = AppUser(
    uid: tUid,
    displayName: 'Test User',
    email: 'test@example.com',
    currentCefrLevel: 'B1', // Level upgraded
  );

  setUp(() {
    mockWatchUserProfile = MockWatchUserProfile();
    homeBloc = HomeBloc(watchUserProfile: mockWatchUserProfile);
  });

  tearDown(() {
    homeBloc.close();
  });

  group('HomeBloc', () {
    test('initial state should be HomeState.initial()', () {
      expect(homeBloc.state, const HomeState.initial());
    });

    group('WatchProfile event', () {
      blocTest<HomeBloc, HomeState>(
        'emits [loading, loaded] when stream emits a valid user',
        build: () {
          when(
            () => mockWatchUserProfile.execute(tUid),
          ).thenAnswer((_) => Stream.value(tUser));
          return homeBloc;
        },
        act: (bloc) => bloc.add(const WatchProfile(tUid)),
        expect: () => [
          const HomeState.loading(),
          const HomeState.loaded(profile: tUser),
        ],
        verify: (_) {
          verify(() => mockWatchUserProfile.execute(tUid)).called(1);
        },
      );

      blocTest<HomeBloc, HomeState>(
        'emits [loading, error] when stream emits null (user not found)',
        build: () {
          when(
            () => mockWatchUserProfile.execute(tUid),
          ).thenAnswer((_) => Stream.value(null));
          return homeBloc;
        },
        act: (bloc) => bloc.add(const WatchProfile(tUid)),
        expect: () => [
          const HomeState.loading(),
          const HomeState.error(message: 'User profile not found.'),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'emits [loading, error] when stream throws an exception',
        build: () {
          when(
            () => mockWatchUserProfile.execute(tUid),
          ).thenAnswer((_) => Stream.error(Exception('Firestore timeout')));
          return homeBloc;
        },
        act: (bloc) => bloc.add(const WatchProfile(tUid)),
        expect: () => [
          const HomeState.loading(),
          const HomeState.error(
            message: 'Failed to load profile: Exception: Firestore timeout',
          ),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'emits multiple loaded states when stream emits multiple users',
        build: () {
          when(
            () => mockWatchUserProfile.execute(tUid),
          ).thenAnswer((_) => Stream.fromIterable([tUser, tUpdatedUser]));
          return homeBloc;
        },
        act: (bloc) => bloc.add(const WatchProfile(tUid)),
        expect: () => [
          const HomeState.loading(),
          const HomeState.loaded(profile: tUser),
          const HomeState.loaded(profile: tUpdatedUser),
        ],
      );
    });

    group('close()', () {
      test('cancels active profile subscription', () async {
        // Arrange: start watching to create a subscription
        final mockStreamController = StreamController<AppUser?>();
        when(
          () => mockWatchUserProfile.execute(tUid),
        ).thenAnswer((_) => mockStreamController.stream);

        homeBloc.add(const WatchProfile(tUid));
        await Future.microtask(() {}); // Let event process

        // Act: close the BLoC
        await homeBloc.close();
        await mockStreamController.close();

        // Assert: subscription is cancelled (no more events can be added)
        expect(mockStreamController.isClosed, isTrue);
      });

      blocTest<HomeBloc, HomeState>(
        'does not emit states after close() is called',
        build: () {
          final delayedStream = Stream.fromFuture(
            Future.delayed(const Duration(seconds: 1), () => tUser),
          );
          when(
            () => mockWatchUserProfile.execute(tUid),
          ).thenAnswer((_) => delayedStream);
          return homeBloc;
        },
        act: (bloc) async {
          bloc.add(const WatchProfile(tUid));
          await Future.microtask(() {}); // Process loading state
          await bloc.close(); // Close before delayed emission
        },
        // Should only see loading, not the delayed loaded state
        expect: () => [const HomeState.loading()],
      );
    });

    group('State equality (freezed)', () {
      test('HomeState.loaded uses value equality', () {
        const state1 = HomeState.loaded(profile: tUser);
        const state2 = HomeState.loaded(profile: tUser);
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('HomeState.error uses value equality', () {
        const state1 = HomeState.error(message: 'Test error');
        const state2 = HomeState.error(message: 'Test error');
        expect(state1, equals(state2));
      });
    });
  });
}
