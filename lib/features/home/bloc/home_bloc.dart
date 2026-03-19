// lib/features/home/bloc/home_bloc.dart

import "dart:async";
import "package:equatable/equatable.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "../../../../core/domain/models/app_user.dart";
import "../../../../core/domain/usecases/user/watch_user_profile.dart";

part "home_event.dart";
part "home_state.dart";

part "home_bloc.freezed.dart";

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final WatchUserProfile _watchUserProfile;
  StreamSubscription<AppUser?>? _profileSubscription;

  HomeBloc({required WatchUserProfile watchUserProfile})
    : _watchUserProfile = watchUserProfile,
      super(const HomeState.initial()) {
    on<WatchProfile>(_onWatchProfile);
    on<_ProfileUpdated>(_onProfileUpdated);
    on<_ProfileError>(_onProfileError);
  }

  void _onWatchProfile(WatchProfile event, Emitter<HomeState> emit) {
    emit(const HomeState.loading());
    _profileSubscription?.cancel();
    _profileSubscription = _watchUserProfile.execute(event.uid).listen(
      (user) {
        if (user != null) {
          add(_ProfileUpdated(user));
        } else {
          add(const _ProfileError("User profile not found."));
        }
      },
      onError: (error) => add(_ProfileError("Failed to load profile: $error")),
    );
  }

  void _onProfileUpdated(_ProfileUpdated event, Emitter<HomeState> emit) {
    emit(HomeState.loaded(profile: event.user));
  }

  void _onProfileError(_ProfileError event, Emitter<HomeState> emit) {
    emit(HomeState.error(message: event.message));
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    return super.close();
  }
}

// ── Internal events ─────────────────────────────────────
class _ProfileUpdated extends HomeEvent {
  final AppUser user;
  const _ProfileUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

class _ProfileError extends HomeEvent {
  final String message;
  const _ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
